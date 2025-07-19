//
//  ExploreView.swift
//  Scanivore
//
//  TCA-powered explore view for product recommendations
//

import SwiftUI
import ComposableArchitecture

// MARK: - Explore Feature Domain
@Reducer
struct ExploreFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var searchText = ""
        var showingFilters = false
        var selectedMeatTypes: Set<MeatType> = []
        var recommendations: IdentifiedArrayOf<ProductRecommendation> = []
        
        // Search state
        var searchResults: IdentifiedArrayOf<ProductRecommendation> = []
        var isSearching = false
        var searchError: String?
        var searchParsedIntent: ParsedIntent?
        var isUsingFallbackSearch = false
        var isSearchActive: Bool {
            !searchText.isEmpty || !searchResults.isEmpty
        }
        
        // Pagination state
        var isLoading = false
        var isLoadingNextPage = false
        var error: String?
        var hasMorePages = true
        var totalItems = 0
        
        // Auto-refresh timer state
        var timerActive = false
        
        // Navigation state
        @Presents var productDetail: ProductDetailFeatureDomain.State?
        
        // Computed properties
        var canLoadMore: Bool {
            !isLoadingNextPage && hasMorePages
        }
        
        var displayedProducts: IdentifiedArrayOf<ProductRecommendation> {
            // If search is active, show search results
            if isSearchActive {
                return searchResults
            }
            
            // Otherwise show recommendations with meat type filter
            if !selectedMeatTypes.isEmpty {
                return IdentifiedArrayOf(uniqueElements: recommendations.filter { recommendation in
                    selectedMeatTypes.contains(recommendation.meatType)
                })
            }
            
            return recommendations
        }
    }
    
    enum Action {
        case searchTextChanged(String)
        case filterButtonTapped
        case filtersDismissed
        case meatTypeToggled(MeatType)
        case clearAllFilters
        
        // Recommendations loading
        case onAppear
        case loadRecommendations
        case loadMoreRecommendations
        case recommendationsResponse(TaskResult<ExploreResponse>)
        case moreRecommendationsResponse(TaskResult<ExploreResponse>)
        case pullToRefresh
        
        // Timer actions
        case startAutoRefreshTimer
        case stopAutoRefreshTimer
        case timerTick
        
        // Helper actions
        case ensureUserPreferences
        
        // Search actions
        case searchDebounced
        case searchSubmitted(String)
        case searchResponse(TaskResult<SearchResponse>)
        case clearSearch
        
        // Navigation actions
        case productTapped(ProductRecommendation)
        case productDetail(PresentationAction<ProductDetailFeatureDomain.Action>)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .searchTextChanged(text):
                state.searchText = text
                
                // Clear search results if text is empty
                if text.isEmpty {
                    state.searchResults = []
                    state.searchError = nil
                    return .cancel(id: "search-debounce")
                }
                
                // Debounce search
                return .run { send in
                    @Dependency(\.continuousClock) var clock
                    try await clock.sleep(for: .milliseconds(300))
                    await send(.searchDebounced)
                }
                .cancellable(id: "search-debounce")
                
            case .filterButtonTapped:
                state.showingFilters = true
                return .none
                
            case .filtersDismissed:
                state.showingFilters = false
                return .none
                
            case let .meatTypeToggled(meatType):
                if state.selectedMeatTypes.contains(meatType) {
                    state.selectedMeatTypes.remove(meatType)
                } else {
                    state.selectedMeatTypes.insert(meatType)
                }
                return .none
                
            case .clearAllFilters:
                state.selectedMeatTypes.removeAll()
                return .none
                
            case .onAppear:
                guard state.recommendations.isEmpty else { return .none }
                return .run { send in
                    await send(.ensureUserPreferences)
                    await send(.loadRecommendations)
                }
                
            case .loadRecommendations:
                state.isLoading = true
                state.error = nil
                state.hasMorePages = true
                
                return .run { send in
                    await send(.recommendationsResponse(
                        TaskResult {
                            @Dependency(\.productGateway) var productGateway
                            // First page: offset=0, pageSize=10
                            return try await productGateway.getRecommendations(0, 10)
                        }
                    ))
                }
                .cancellable(id: "explore-recommendations")
                
            case let .recommendationsResponse(.success(response)):
                state.isLoading = false
                state.totalItems = response.totalMatches
                state.hasMorePages = response.recommendations.count == 10
                
                
                // Convert API response to app models
                let newRecommendations = response.recommendations.map { item in
                    ProductRecommendation.fromRecommendationItem(item)
                }
                state.recommendations = IdentifiedArrayOf(uniqueElements: newRecommendations)
                
                return .run { send in
                    await send(.startAutoRefreshTimer)
                }
                
            case let .recommendationsResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case let .moreRecommendationsResponse(.success(response)):
                state.isLoadingNextPage = false
                state.hasMorePages = response.recommendations.count == 10
                
                
                // Convert and append new recommendations
                let newRecommendations = response.recommendations.map { item in
                    ProductRecommendation.fromRecommendationItem(item)
                }
                state.recommendations.append(contentsOf: newRecommendations)
                
                return .none
                
            case let .moreRecommendationsResponse(.failure(error)):
                state.isLoadingNextPage = false
                // Don't show error for pagination failure, just stop loading
                return .none
                
            case .pullToRefresh:
                return .run { send in
                    await send(.loadRecommendations)
                }
                
            case .startAutoRefreshTimer:
                guard !state.timerActive else { return .none }
                state.timerActive = true
                return .run { send in
                    @Dependency(\.continuousClock) var clock
                    for await _ in clock.timer(interval: .seconds(3600)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: "auto-refresh-timer")
                
            case .stopAutoRefreshTimer:
                state.timerActive = false
                return .cancel(id: "auto-refresh-timer")
                
            case .timerTick:
                guard state.timerActive else { return .none }
                return .run { send in
                    await send(.loadRecommendations)
                }
                
            case .ensureUserPreferences:
                return .none
                
            case .searchDebounced:
                return .run { [searchText = state.searchText] send in
                    await send(.searchSubmitted(searchText))
                }
                
            case let .searchSubmitted(query):
                guard !query.isEmpty else { return .none }
                
                state.isSearching = true
                state.searchError = nil
                
                return .run { send in
                    await send(.searchResponse(
                        TaskResult {
                            @Dependency(\.productGateway) var productGateway
                            return try await productGateway.searchProducts(query)
                        }
                    ))
                }
                .cancellable(id: "search-request")
                
            case let .searchResponse(.success(searchResponse)):
                state.isSearching = false
                
                // Store AI insights from the search response
                state.searchParsedIntent = searchResponse.parsedIntent
                state.isUsingFallbackSearch = searchResponse.fallbackMode ?? false
                
                // Convert Product array to ProductRecommendation array
                let searchRecommendations = searchResponse.products.map { product in
                    ProductRecommendation.fromProduct(product)
                }
                state.searchResults = IdentifiedArrayOf(uniqueElements: searchRecommendations)
                
                return .none
                
            case let .searchResponse(.failure(error)):
                state.isSearching = false
                state.searchError = error.localizedDescription
                return .none
                
            case .clearSearch:
                state.searchText = ""
                state.searchResults = []
                state.searchError = nil
                return .cancel(id: "search-debounce")
                    .merge(with: .cancel(id: "search-request"))
                    
            case let .productTapped(recommendation):
                state.productDetail = ProductDetailFeatureDomain.State(
                    productCode: recommendation.id,
                    productName: recommendation.name,
                    productBrand: recommendation.brand,
                    productImageUrl: recommendation.imageUrl,
                    originalRiskRating: recommendation.originalRiskRating
                )
                return .none
                
            case .productDetail:
                return .none
            case .loadMoreRecommendations:
                guard state.canLoadMore else { return .none }
                state.isLoadingNextPage = true
                
                let offset = state.recommendations.count
                
                return .run { send in
                    await send(.moreRecommendationsResponse(
                        TaskResult {
                            @Dependency(\.productGateway) var productGateway
                            // Next page: offset=current count, pageSize=10
                            return try await productGateway.getRecommendations(offset, 10)
                        }
                    ))
                }
                .cancellable(id: "explore-more-recommendations")

            }
        }
        .ifLet(\.$productDetail, action: \.productDetail) {
            ProductDetailFeatureDomain()
        }
    }
}

struct ExploreView: View {
    let store: StoreOf<ExploreFeatureDomain>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    DesignSystem.Colors.background
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Search Bar
                        SearchBar(
                            text: .init(
                                get: { store.searchText },
                                set: { store.send(.searchTextChanged($0)) }
                            )
                        )
                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                        .padding(.top, DesignSystem.Spacing.sm)
                        .padding(.bottom, DesignSystem.Spacing.base)
                        
                        // Content
                        ScrollView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                                // Header - Dynamic based on search state
                                HStack {
                                    Text(store.isSearchActive ? "Search Results" : "Recommendations")
                                        .font(DesignSystem.Typography.heading1)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    // Clear search button
                                    if store.isSearchActive {
                                        Button("Clear") {
                                            store.send(.clearSearch)
                                        }
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                
                                // Loading state
                                if (store.isLoading && store.recommendations.isEmpty && !store.isSearchActive) ||
                                   (store.isSearching && store.searchResults.isEmpty) {
                                    VStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(1.5)
                                        Text(store.isSearchActive ? "Searching products..." : "Loading recommendations...")
                                            .font(DesignSystem.Typography.body)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                            .padding(.top, DesignSystem.Spacing.md)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 100)
                                }
                                
                                // Error state
                                else if let error = store.searchError ?? store.error, 
                                        (store.isSearchActive ? store.searchResults.isEmpty : store.recommendations.isEmpty) {
                                    VStack(spacing: DesignSystem.Spacing.md) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 50))
                                            .foregroundColor(DesignSystem.Colors.error)
                                        Text(store.isSearchActive ? "Search failed" : "Failed to load recommendations")
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        Text(error)
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                            .multilineTextAlignment(.center)
                                        Button("Try Again") {
                                            if store.isSearchActive {
                                                store.send(.searchSubmitted(store.searchText))
                                            } else {
                                                store.send(.loadRecommendations)
                                            }
                                        }
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                        .padding(.top)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, DesignSystem.Spacing.xl)
                                    .padding(.top, 100)
                                }
                                
                                // Product Grid - LazyVStack for better scroll performance
                                else {
                                    LazyVStack(spacing: DesignSystem.Spacing.lg) {
                                        ForEach(Array(store.displayedProducts.enumerated()), id: \.element.id) { index, recommendation in
                                            ProductRecommendationCard(
                                                recommendation: recommendation,
                                                onTap: {
                                                    store.send(.productTapped(recommendation))
                                                }
                                            )
                                            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                            .onAppear {
                                                // Only load more for recommendations, not search results
                                                if !store.isSearchActive && store.canLoadMore {
                                                    // Efficient pagination using enumerated index (O(1) instead of O(n))
                                                    let totalItems = store.displayedProducts.count
                                                    let itemsFromEnd = totalItems - index
                                                    // Trigger when we're 5 items from the end
                                                    if itemsFromEnd <= 5 {
                                                        store.send(.loadMoreRecommendations)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Loading more indicator (only for recommendations)
                                        if store.isLoadingNextPage && !store.isSearchActive {
                                            HStack {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle())
                                                Text("Loading more...")
                                                    .font(DesignSystem.Typography.caption)
                                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, DesignSystem.Spacing.lg)
                                        }
                                        
                                        // End of list message (only for recommendations)
                                        else if !store.hasMorePages && !store.recommendations.isEmpty && !store.isSearchActive {
                                            VStack(spacing: DesignSystem.Spacing.sm) {
                                                Text(store.recommendations.count < 20 ? 
                                                     "Found \(store.recommendations.count) products matching your preferences" : 
                                                     "That's all for now!")
                                                    .font(DesignSystem.Typography.caption)
                                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                                    .multilineTextAlignment(.center)
                                                
                                                if store.recommendations.count < 10 {
                                                    Text("Try adjusting your filters for more results")
                                                        .font(DesignSystem.Typography.caption)
                                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                                        .multilineTextAlignment(.center)
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, DesignSystem.Spacing.lg)
                                        }
                                        
                                        // Search results count
                                        else if store.isSearchActive && !store.searchResults.isEmpty {
                                            Text("Found \(store.searchResults.count) products")
                                                .font(DesignSystem.Typography.caption)
                                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, DesignSystem.Spacing.lg)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, DesignSystem.Spacing.base)
                        }
                        .refreshable {
                            await store.send(.pullToRefresh).finish()
                        }
                    }
                }
                .customNavigationTitle("Explore")
                .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { store.send(.filterButtonTapped) }) {
                            Text("Filter")
                                .foregroundColor(DesignSystem.Colors.primaryRed)
                                .font(DesignSystem.Typography.body)
                        }
                    }
                }
                .sheet(isPresented: .init(
                    get: { store.showingFilters },
                    set: { _ in store.send(.filtersDismissed) }
                )) {
                    MeatTypeFilterView(store: store)
                }
                .onAppear {
                    store.send(.onAppear)
                }
                .onDisappear {
                    store.send(.stopAutoRefreshTimer)
                }
                .sheet(
                    store: store.scope(state: \.$productDetail, action: \.productDetail)
                ) { productDetailStore in
                    ProductDetailView(store: productDetailStore)
                }
            }
        }
    }
}

// MARK: - Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField("Search products...", text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .autocapitalization(.none)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.inputPadding)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Components.Input.cornerRadius)
    }
}

// MARK: - Product Recommendation Card
struct ProductRecommendationCard: View {
    let recommendation: ProductRecommendation
    let onTap: (() -> Void)?
    
    init(recommendation: ProductRecommendation, onTap: (() -> Void)? = nil) {
        self.recommendation = recommendation
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.base) {
            // Product Image
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .frame(width: 120, height: 120)
                
                if let imageUrl = recommendation.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipped()
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        case .failure(_):
                            // Show placeholder when image fails to load
                            PlaceholderImage()
                        case .empty:
                            ProgressView()
                                .frame(width: 120, height: 120)
                        @unknown default:
                            PlaceholderImage()
                        }
                    }
                } else if let imageData = recommendation.imageData {
                    // Async base64 decoding to avoid main thread blocking during scroll
                    AsyncImageDecoder(base64String: imageData) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 120, height: 120)
                    }
                } else {
                    PlaceholderImage()
                }
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text(recommendation.name)
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(recommendation.brand)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                QualityBadge(level: recommendation.qualityRating)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.base)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            // Use border instead of shadow for better scroll performance
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Async Image Decoder for Base64 Images
struct AsyncImageDecoder<Content: View, Placeholder: View>: View {
    let base64String: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var decodedImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let uiImage = decodedImage {
                content(Image(uiImage: uiImage))
            } else if isLoading {
                placeholder()
            } else {
                // Failed to decode
                PlaceholderImage()
            }
        }
        .task {
            await decodeImage()
        }
    }
    
    @MainActor
    private func decodeImage() async {
        // Move expensive base64 decoding to background queue
        let result = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let data = Data(base64Encoded: base64String),
                  let image = UIImage(data: data) else {
                return nil
            }
            return image
        }.value
        
        decodedImage = result
        isLoading = false
    }
}

// MARK: - Quality Badge Component
struct QualityBadge: View {
    let level: QualityLevel
    
    var badgeColor: Color {
        switch level {
        case .excellent:
            return DesignSystem.Colors.success  // A = Green
        case .good:
            return DesignSystem.Colors.warning  // C = Yellow (matches ProductDetail)
        case .poor:
            return Color.orange  // D = Orange
        case .bad:
            return DesignSystem.Colors.error  // F = Red
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)
            
            Text(level.displayName)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.full)
    }
}

// MARK: - Meat Type Filter View
struct MeatTypeFilterView: View {
    let store: StoreOf<ExploreFeatureDomain>
    @Environment(\.dismiss) private var dismiss
    
    private let availableMeatTypes: [MeatType] = [.beef, .pork, .chicken, .lamb, .turkey, .fish]
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    DesignSystem.Colors.backgroundSecondary
                        .ignoresSafeArea()
                    
                    Form {
                        Section("Filter by Meat Type") {
                            ForEach(availableMeatTypes, id: \.self) { meatType in
                                HStack {
                                    Text("\(meatType.icon) \(meatType.rawValue)")
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if store.selectedMeatTypes.contains(meatType) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(DesignSystem.Colors.primaryRed)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.meatTypeToggled(meatType))
                                }
                                .listRowBackground(DesignSystem.Colors.background)
                            }
                            
                            // Show All option
                            HStack {
                                Text("Show All")
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                if store.selectedMeatTypes.isEmpty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.send(.clearAllFilters)
                            }
                            .listRowBackground(DesignSystem.Colors.background)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("Filter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                }
            }
        }
    }
}

// MARK: - Data Models
struct ProductRecommendation: Identifiable, Equatable {
    let id: String
    let name: String
    let brand: String
    let imageUrl: String?
    let imageData: String?
    let meatType: MeatType
    let qualityRating: QualityLevel
    let originalRiskRating: String // Store original OpenFoodFacts risk rating
    let isRecommended: Bool
    let matchReasons: [String]
    let concerns: [String]
    
    // Convert from API model
    static func fromRecommendationItem(_ item: RecommendationItem) -> ProductRecommendation {
        let riskRating = item.product.risk_rating ?? "Green"
        
        return ProductRecommendation(
            id: item.product.code ?? "unknown",
            name: item.product.name ?? "Unknown Product",
            brand: item.product.brand ?? "Unknown Brand",
            imageUrl: item.product.image_url,
            imageData: item.product.image_data,
            meatType: determineMeatType(from: item.product),
            qualityRating: mapRiskRatingToQuality(riskRating),
            originalRiskRating: riskRating, // Store the original risk rating
            isRecommended: item.matchDetails.concerns.isEmpty,
            matchReasons: item.matchDetails.matches,
            concerns: item.matchDetails.concerns
        )
    }
    
    static func determineMeatType(from product: Product) -> MeatType {
        // First check if we have the direct meat_type field from NLP search
        if let meatType = product.meat_type?.lowercased() {
            switch meatType {
            case "chicken": return .chicken
            case "beef": return .beef
            case "pork": return .pork
            case "turkey": return .turkey
            case "lamb": return .lamb
            case "fish": return .fish
            default: break
            }
        }
        
        // Fallback to name/category analysis for backward compatibility
        let name = (product.name ?? "").lowercased()
        let categories = product.categories?.joined(separator: " ").lowercased() ?? ""
        let combined = name + " " + categories
        
        if combined.contains("chicken") { return .chicken }
        if combined.contains("beef") || combined.contains("steak") { return .beef }
        if combined.contains("pork") || combined.contains("bacon") { return .pork }
        if combined.contains("turkey") { return .turkey }
        if combined.contains("lamb") { return .lamb }
        if combined.contains("fish") || combined.contains("salmon") { return .fish }
        
        return .beef // Default
    }
    
    static func mapRiskRatingToQuality(_ rating: String) -> QualityLevel {
        switch rating.lowercased() {
        case "green": return .excellent
        case "yellow": return .good
        case "orange": return .poor
        case "red": return .bad
        default: return .good
        }
    }
    
    // Convert from Product (for search results)
    static func fromProduct(_ product: Product) -> ProductRecommendation {
        let riskRating = product.risk_rating ?? "Green"
        
        // Generate match reasons based on available data
        var matchReasons: [String] = []
        
        // Add relevance-based reasons if we have a score from NLP search
        if let relevanceScore = product._relevance_score, relevanceScore > 0.7 {
            matchReasons.append("High relevance match")
        } else if let relevanceScore = product._relevance_score, relevanceScore > 0.5 {
            matchReasons.append("Good match")
        } else {
            matchReasons.append("Search result")
        }
        
        // Add nutrition-based reasons
        if let protein = product.protein, protein > 20 {
            matchReasons.append("High protein content")
        }
        
        if let salt = product.salt, salt < 0.5 {
            matchReasons.append("Low sodium")
        }
        
        // Add quality-based reasons from ingredient flags
        if product.antibiotic_free == true {
            matchReasons.append("Antibiotic-free")
        }
        
        if product.contains_preservatives == false {
            matchReasons.append("No preservatives")
        }
        
        return ProductRecommendation(
            id: product.code ?? "unknown",
            name: product.name ?? "Unknown Product",
            brand: product.brand ?? "Unknown Brand",
            imageUrl: product.image_url,
            imageData: product.image_data,
            meatType: determineMeatType(from: product),
            qualityRating: mapRiskRatingToQuality(riskRating),
            originalRiskRating: riskRating,
            isRecommended: true,
            matchReasons: matchReasons,
            concerns: []
        )
    }
}

enum QualityLevel: Equatable {
    case excellent
    case good
    case poor
    case bad
    
    var displayName: String {
        switch self {
        case .excellent: return "A"
        case .good: return "C"
        case .poor: return "D"
        case .bad: return "F"
        }
    }
    
    var sortValue: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .poor: return 2
        case .bad: return 1
        }
    }
}

// MARK: - Placeholder Image Component
struct PlaceholderImage: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundSecondary)
                .frame(width: 120, height: 120)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                
                Text("No Image")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.8))
            }
        }
        .frame(width: 120, height: 120)
    }
}


#Preview {
    ExploreView(
        store: Store(
            initialState: ExploreFeatureDomain.State()
        ) {
            ExploreFeatureDomain()
        }
    )
}
