//
//  ExploreView.swift
//  Scanivore
//
//  TCA-powered explore view
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
        var isSearchActive: Bool {
            !searchText.isEmpty
        }
        
        // Pagination state
        var isLoading = false
        var isLoadingNextPage = false
        var error: String?
        var hasMorePages = true
        var totalItems = 0
        var currentPage = 0
        
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
        
        // Timer actions
        case startAutoRefreshTimer
        case stopAutoRefreshTimer
        case timerTicked
        
        // Pagination actions
        case loadMoreRecommendations
        case recommendationsResponse(TaskResult<ExploreResponse>)
        case recommendationsResponseOptimized(ExploreResponse)
        
        // Product actions  
        case refreshRecommendations
        case loadRecommendations
        
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
                    await send(.searchDebounced)
                }
                .debounce(id: "search-debounce", for: 0.5, scheduler: RunLoop.main)
                
            case .searchDebounced:
                guard !state.searchText.isEmpty else { return .none }
                return .send(.searchSubmitted(state.searchText))
                
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
                state.selectedMeatTypes = []
                return .none
                
            case .startAutoRefreshTimer:
                state.timerActive = true
                // Load initial recommendations immediately
                return .send(.loadRecommendations)
                    .merge(with: .run { send in
                        // Then refresh every 5 minutes
                        for await _ in Timer.publish(every: 300, on: .main, in: .common).autoconnect().values {
                            await send(.timerTicked)
                        }
                    }
                    .cancellable(id: "explore-timer"))
                
            case .stopAutoRefreshTimer:
                state.timerActive = false
                return .cancel(id: "explore-timer")
                
            case .timerTicked:
                // Refresh recommendations automatically
                return .send(.refreshRecommendations)
                
            case .refreshRecommendations:
                // Clear existing and reload
                state.recommendations = []
                state.hasMorePages = true
                state.totalItems = 0
                state.currentPage = 0
                return .send(.loadRecommendations)
                
            case .loadRecommendations:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.error = nil
                let offset = 0
                
                return .run { send in
                    @Dependency(\.productGateway) var gateway
                    
                    let result = await TaskResult {
                        try await gateway.getRecommendations(offset, 10)
                    }
                    
                    await send(.recommendationsResponse(result))
                }
                .cancellable(id: "explore-recommendations")
                
            case let .recommendationsResponse(.success(response)):
                state.isLoading = false
                
                // First process through the optimization
                return .send(.recommendationsResponseOptimized(response))
                
            case let .recommendationsResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case let .recommendationsResponseOptimized(response):
                // Convert to ProductRecommendation models
                let newRecommendations = response.recommendations.map { 
                    ProductRecommendation.fromRecommendationItem($0)
                }
                
                // For initial load
                if state.recommendations.isEmpty {
                    state.recommendations = IdentifiedArrayOf(uniqueElements: newRecommendations)
                } else {
                    // For pagination (append)
                    for recommendation in newRecommendations {
                        state.recommendations.updateOrAppend(recommendation)
                    }
                }
                
                // Update pagination state
                state.totalItems = response.totalMatches
                state.hasMorePages = state.recommendations.count < response.totalMatches
                state.isLoadingNextPage = false
                
                return .none
                
            case let .searchSubmitted(query):
                guard !query.isEmpty else { return .none }
                
                state.isSearching = true
                state.searchError = nil
                
                return .run { send in
                    @Dependency(\.productGateway) var gateway
                    
                    let result = await TaskResult {
                        try await gateway.searchProducts(query)
                    }
                    
                    await send(.searchResponse(result))
                }
                .cancellable(id: "search-request")
                
            case let .searchResponse(.success(searchResponse)):
                state.isSearching = false
                
                // Convert Product array to ProductRecommendation array
                let searchRecommendations = searchResponse.products.map { product in
                    ProductRecommendation.fromProduct(product)
                }
                
                state.searchResults = IdentifiedArrayOf(uniqueElements: searchRecommendations)
                return .none
                
            case let .searchResponse(.failure(error)):
                state.isSearching = false
                state.searchError = "Search failed: \(error.localizedDescription)"
                state.searchResults = []
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
                state.currentPage += 1
                let offset = state.recommendations.count
                
                return .run { send in
                    @Dependency(\.productGateway) var gateway
                    
                    let result = await TaskResult {
                        try await gateway.getRecommendations(offset, 10)
                    }
                    
                    await send(.recommendationsResponse(result))
                }
                .cancellable(id: "explore-more-recommendations")

            }
        }
        ._printChanges()
        .ifLet(\.$productDetail, action: \.productDetail) {
            ProductDetailFeatureDomain()
        }
    }
}


struct ExploreView: View {
    @Bindable var store: StoreOf<ExploreFeatureDomain>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                mainContent
                    .navigationTitle("Explore")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .sheet(
                        isPresented: Binding(
                            get: { store.showingFilters },
                            set: { _ in store.send(.filtersDismissed) }
                        )
                    ) {
                        MeatTypeFilterView(store: store)
                    }
                    .onAppear {
                        store.send(.startAutoRefreshTimer)
                    }
                    .onDisappear {
                        store.send(.stopAutoRefreshTimer)
                    }
                    .navigationDestination(
                        item: $store.scope(
                            state: \.productDetail,
                            action: \.productDetail
                        )
                    ) { productDetailStore in
                        ProductDetailView(store: productDetailStore)
                    }
            }
        }
    }
    
    private var mainContent: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                searchSection
                filtersSection
                contentSection
            }
        }
    }
    
    private var searchSection: some View {
        SearchBar(text: $store.searchText.sending(\.searchTextChanged))
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private var filtersSection: some View {
        Group {
            if !store.isSearchActive {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        FilterButton(
                            hasActiveFilters: !store.selectedMeatTypes.isEmpty,
                            action: { store.send(.filterButtonTapped) }
                        )
                        
                        ForEach(Array(store.selectedMeatTypes), id: \.self) { meatType in
                            meatTypeFilterChip(meatType)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
                .frame(height: 44)
            }
        }
    }
    
    private func meatTypeFilterChip(_ meatType: MeatType) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text("\(meatType.icon) \(meatType.rawValue)")
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Button {
                store.send(.meatTypeToggled(meatType))
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(DesignSystem.Colors.backgroundSecondary)
        )
    }
    
    private var contentSection: some View {
        ScrollView {
            if store.isLoading && store.recommendations.isEmpty {
                loadingView
            } else if let error = store.error {
                errorView(error)
            } else if store.displayedProducts.isEmpty {
                emptyStateView
            } else {
                productListView
            }
        }
        .refreshable {
            if !store.isSearchActive {
                store.send(.refreshRecommendations)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .frame(height: 140)
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            }
        }
        .padding(.top, DesignSystem.Spacing.md)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.error)
            
            Text("Something went wrong")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(error)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                store.send(.refreshRecommendations)
            } label: {
                Text("Try Again")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.primaryRed)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if store.isSearchActive && !store.isSearching {
                // No search results
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("No products found")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Try searching for something else")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                // No recommendations
                Image(systemName: "star.slash")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("No recommendations yet")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Scan some products to get personalized recommendations")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var productListView: some View {
        LazyVStack(spacing: DesignSystem.Spacing.sm) {
            if store.isSearchActive && store.isSearching {
                searchLoadingView
            }
            
            ForEach(Array(store.displayedProducts.enumerated()), id: \.element.id) { index, recommendation in
                ProductRecommendationCard(
                    recommendation: recommendation,
                    onTap: {
                        store.send(.productTapped(recommendation))
                    }
                )
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                .onAppear {
                    if !store.isSearchActive && store.canLoadMore {
                        let totalItems = store.displayedProducts.count
                        let itemsFromEnd = totalItems - index
                        if itemsFromEnd <= 3 {
                            store.send(.loadMoreRecommendations)
                        }
                    }
                }
            }
            
            if store.isLoadingNextPage {
                loadingMoreView
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private var searchLoadingView: some View {
        HStack {
            ProgressView()
                .tint(DesignSystem.Colors.textSecondary)
            Text("Searching...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    private var loadingMoreView: some View {
        HStack {
            ProgressView()
                .tint(DesignSystem.Colors.textSecondary)
            Text("Loading more...")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
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

