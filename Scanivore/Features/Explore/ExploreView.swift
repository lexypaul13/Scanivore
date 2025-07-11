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
        
        // Pagination state
        var isLoading = false
        var isLoadingMore = false
        var error: String?
        var currentPage = 0
        var hasMorePages = true
        var totalItems = 0
        
        // Auto-refresh timer state
        var timerActive = false
        
        // Computed properties
        var canLoadMore: Bool {
            !isLoadingMore && hasMorePages && currentPage < 3
        }
        
        var filteredRecommendations: IdentifiedArrayOf<ProductRecommendation> {
            var filtered = recommendations
            
            // Simple search filter
            if !searchText.isEmpty {
                filtered = IdentifiedArrayOf(uniqueElements: filtered.filter { recommendation in
                    recommendation.name.localizedCaseInsensitiveContains(searchText) ||
                    recommendation.brand.localizedCaseInsensitiveContains(searchText)
                })
            }
            
            // Simple meat type filter
            if !selectedMeatTypes.isEmpty {
                filtered = IdentifiedArrayOf(uniqueElements: filtered.filter { recommendation in
                    selectedMeatTypes.contains(recommendation.meatType)
                })
            }
            
            return filtered
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
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .searchTextChanged(text):
                state.searchText = text
                return .none
                
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
                state.currentPage = 0
                state.hasMorePages = true
                
                return .run { send in
                    await send(.recommendationsResponse(
                        TaskResult {
                            @Dependency(\.productGateway) var productGateway
                            return try await productGateway.getRecommendations()
                        }
                    ))
                }
                .cancellable(id: "explore-recommendations")
                
            case .loadMoreRecommendations:
                guard state.canLoadMore else { return .none }
                
                state.isLoadingMore = true
                let nextPage = state.currentPage + 1
                let offset = nextPage * 10
                
                return .run { send in
                    await send(.moreRecommendationsResponse(
                        TaskResult {
                            @Dependency(\.productGateway) var productGateway
                            return try await productGateway.getExploreRecommendations(offset, 10)
                        }
                    ))
                }
                
            case let .recommendationsResponse(.success(response)):
                state.isLoading = false
                state.currentPage = 0
                state.totalItems = response.totalMatches
                state.hasMorePages = response.recommendations.count == 10 && state.totalItems > 10
                
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
                state.isLoadingMore = false
                state.currentPage += 1
                state.hasMorePages = response.recommendations.count == 10 && 
                                   (state.currentPage + 1) * 10 < state.totalItems &&
                                   state.currentPage < 2  // Max 3 pages (0, 1, 2)
                
                // Convert and append new recommendations
                let newRecommendations = response.recommendations.map { item in
                    ProductRecommendation.fromRecommendationItem(item)
                }
                state.recommendations.append(contentsOf: newRecommendations)
                
                return .none
                
            case let .moreRecommendationsResponse(.failure(error)):
                state.isLoadingMore = false
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
                return .run { _ in
                    @Dependency(\.userGateway) var userGateway
                    
                    do {
                        let user = try? await userGateway.getProfile()
                        
                        if user?.preferences == nil {
                            let defaultPreferences = UserPreferences(
                                nutritionFocus: "balanced",
                                avoidPreservatives: true,
                                meatPreferences: ["chicken", "beef", "fish"],
                                prefer_no_preservatives: true,
                                prefer_antibiotic_free: true,
                                prefer_organic_or_grass_fed: false,
                                prefer_no_added_sugars: true,
                                prefer_no_flavor_enhancers: true,
                                prefer_reduced_sodium: false,
                                preferred_meat_types: ["chicken", "beef", "fish"]
                            )
                            
                            _ = try? await userGateway.updatePreferences(defaultPreferences)
                        }
                    } catch {
                        // Silently handle preference setup errors
                    }
                }
            }
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
                                // Recommendations Header
                                Text("Recommendations")
                                    .font(DesignSystem.Typography.heading1)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                
                                // Loading state
                                if store.isLoading && store.recommendations.isEmpty {
                                    VStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(1.5)
                                        Text("Loading recommendations...")
                                            .font(DesignSystem.Typography.body)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                            .padding(.top, DesignSystem.Spacing.md)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 100)
                                }
                                
                                // Error state
                                else if let error = store.error, store.recommendations.isEmpty {
                                    VStack(spacing: DesignSystem.Spacing.md) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 50))
                                            .foregroundColor(DesignSystem.Colors.error)
                                        Text("Failed to load recommendations")
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        Text(error)
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                            .multilineTextAlignment(.center)
                                        Button("Try Again") {
                                            store.send(.loadRecommendations)
                                        }
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                        .padding(.top)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, DesignSystem.Spacing.xl)
                                    .padding(.top, 100)
                                }
                                
                                // Product Grid
                                else {
                                    VStack(spacing: DesignSystem.Spacing.lg) {
                                        ForEach(store.filteredRecommendations) { recommendation in
                                            ProductRecommendationCard(recommendation: recommendation)
                                                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                                .onAppear {
                                                    let isNearEnd = store.filteredRecommendations.suffix(3).contains(recommendation)
                                                    if isNearEnd {
                                                        store.send(.loadMoreRecommendations)
                                                    }
                                                }
                                        }
                                        
                                        // Loading more indicator
                                        if store.isLoadingMore {
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
                                        
                                        // End of list message
                                        else if !store.hasMorePages && !store.recommendations.isEmpty {
                                            Text("That's all for now!")
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
                } else if let imageData = recommendation.imageData,
                          let data = Data(base64Encoded: imageData),
                          let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipped()
                        .cornerRadius(DesignSystem.CornerRadius.md)
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
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: 0,
            y: DesignSystem.Shadow.offsetLight.height
        )
    }
}

// MARK: - Quality Badge Component
struct QualityBadge: View {
    let level: QualityLevel
    
    var badgeColor: Color {
        switch level {
        case .excellent:
            return DesignSystem.Colors.success
        case .good:
            return Color.blue
        case .poor:
            return Color.orange
        case .bad:
            return DesignSystem.Colors.error
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
    let isRecommended: Bool
    let matchReasons: [String]
    let concerns: [String]
    
    // Convert from API model
    static func fromRecommendationItem(_ item: RecommendationItem) -> ProductRecommendation {
        let riskRating = item.product.risk_rating ?? "Green"
        
        return ProductRecommendation(
            id: item.product.code,
            name: item.product.name ?? "Unknown Product",
            brand: item.product.brand ?? "Unknown Brand",
            imageUrl: item.product.image_url,
            imageData: item.product.image_data,
            meatType: determineMeatType(from: item.product),
            qualityRating: mapRiskRatingToQuality(riskRating),
            isRecommended: item.matchDetails.concerns.isEmpty,
            matchReasons: item.matchDetails.matches,
            concerns: item.matchDetails.concerns
        )
    }
    
    static func determineMeatType(from product: Product) -> MeatType {
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
}

enum QualityLevel: Equatable {
    case excellent
    case good
    case poor
    case bad
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .poor: return "Poor"
        case .bad: return "Bad"
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
