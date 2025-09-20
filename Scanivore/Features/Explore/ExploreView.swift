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
        var selectedGrades: Set<SafetyGrade> = []
        var recommendations: IdentifiedArrayOf<ProductRecommendation> = []
        
        // Search state
        var searchResults: IdentifiedArrayOf<ProductRecommendation> = []
        var isSearching = false
        var searchError: String?
        var isSearchActive: Bool {
            !searchText.isEmpty
        }

        // Search pagination state
        var searchHasMorePages = true
        var searchTotalItems = 0
        var searchCurrentPage = 0
        var isLoadingSearchNextPage = false

        // Recommendations pagination state
        var isLoading = false
        var isLoadingNextPage = false
        var error: String?
        var hasMorePages = true
        var totalItems = 0
        var currentPage = 0

        // Auth state tracking
        var lastAuthState: Bool? = nil // Track if user was authenticated on last load
        
        // Auto-refresh timer state
        var timerActive = false
        
        // Navigation state
        @Presents var productDetail: ProductDetailFeatureDomain.State?
        
        // Computed properties
        var canLoadMore: Bool {
            if isSearchActive {
                return !isLoadingSearchNextPage && searchHasMorePages
            } else {
                return !isLoadingNextPage && hasMorePages
            }
        }
        
        var displayedProducts: IdentifiedArrayOf<ProductRecommendation> {
            // If search is active, show search results
            if isSearchActive {
                return searchResults
            }
            
            // Otherwise show recommendations with grade filter
            if !selectedGrades.isEmpty {
                return IdentifiedArrayOf(uniqueElements: recommendations.filter { recommendation in
                    let mappedGrade = ExploreFeatureDomain.mapQualityToSafetyGrade(recommendation.qualityRating)
                    return selectedGrades.contains(mappedGrade)
                })
            }
            
            return recommendations
        }
    }
    
    enum Action: Equatable {
        case searchTextChanged(String)
        case filterButtonTapped
        case filtersDismissed
        case gradeToggled(SafetyGrade)
        case clearAllFilters
        
        // Timer actions
        case startAutoRefreshTimer
        case stopAutoRefreshTimer
        case timerTicked
        
        // Pagination actions
        case loadMoreRecommendations
        case loadMoreSearchResults
        case recommendationsReceived(TaskResult<ExploreResponse>)
        case recommendationsProcessed(ExploreResponse)
        case searchPaginationReceived(TaskResult<SearchResponse>)

        // Auth state actions
        case authStateChanged(Bool)
        case clearExploreData
        
        // Product actions  
        case refreshRecommendations
        case loadRecommendations
        
        // Search actions
        case searchDebounced
        case searchSubmitted(String)
        case searchResponseReceived(TaskResult<SearchResponse>)
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
                
            case let .gradeToggled(grade):
                if state.selectedGrades.contains(grade) {
                    state.selectedGrades.remove(grade)
                } else {
                    state.selectedGrades.insert(grade)
                }
                return .none
                
            case .clearAllFilters:
                state.selectedGrades = []
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
                state.isLoading = false  // Reset loading state before calling loadRecommendations
                return .send(.loadRecommendations)
                
            case .loadRecommendations:
                guard !state.isLoading else { return .none }
                state.isLoading = true
                state.error = nil
                let offset = 0
                
                return .run { send in
                    @Dependency(\.productGateway) var gateway
                    @Dependency(\.authState) var authState
                    
                    let result = await TaskResult {
                        let currentAuthState = await authState.load()
                        
                        // For both authenticated and guest users, load recommendations
                        // Avoid calling search with an empty query which causes 400 errors
                        return try await gateway.getExploreRecommendations(offset, 10)
                    }
                    
                    await send(.recommendationsReceived(result))
                }
                .cancellable(id: "explore-recommendations")
                
            case let .recommendationsReceived(.success(response)):
                state.isLoading = false
                
                // First process through the optimization
                return .send(.recommendationsProcessed(response))
                
            case let .recommendationsReceived(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case let .recommendationsProcessed(response):
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
                state.hasMorePages = response.hasMore ?? (state.recommendations.count < response.totalMatches)
                state.isLoadingNextPage = false

                // Debug: Log pagination state after processing
                print("🔎 [Explore] Processed page: appended=\(newRecommendations.count), totalLoaded=\(state.recommendations.count), totalMatches=\(state.totalItems), hasMorePages=\(state.hasMorePages)")
                
                return .none
                
            case let .searchSubmitted(query):
                // Enforce minimum length to satisfy backend validation
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 2 else { return .none }

                state.isSearching = true
                state.searchError = nil
                // Reset search pagination for new search
                state.searchResults = []
                state.searchHasMorePages = true
                state.searchTotalItems = 0
                state.searchCurrentPage = 0
                state.isLoadingSearchNextPage = false

                return .run { send in
                    @Dependency(\.productGateway) var gateway

                    let result = await TaskResult {
                        try await gateway.searchProducts(trimmed, 0, 10)
                    }

                    await send(.searchResponseReceived(result))
                }
                .cancellable(id: "search-request")
                
            case let .searchResponseReceived(.success(searchResponse)):
                state.isSearching = false

                // Convert Product array to ProductRecommendation array
                let searchRecommendations = searchResponse.products.map { product in
                    ProductRecommendation.fromProduct(product)
                }

                state.searchResults = IdentifiedArrayOf(uniqueElements: searchRecommendations)
                // Update search pagination state
                state.searchTotalItems = searchResponse.totalResults
                state.searchHasMorePages = state.searchResults.count < searchResponse.totalResults

                return .none
                
            case let .searchResponseReceived(.failure(error)):
                state.isSearching = false
                state.searchError = "Search failed: \(error.localizedDescription)"
                state.searchResults = []
                return .none
                
            case .clearSearch:
                state.searchText = ""
                state.searchResults = []
                state.searchError = nil
                state.searchHasMorePages = true
                state.searchTotalItems = 0
                state.searchCurrentPage = 0
                state.isLoadingSearchNextPage = false
                return .cancel(id: "search-debounce")
                    .merge(with: .cancel(id: "search-request"))
                    .merge(with: .cancel(id: "search-pagination"))
                    
            case let .productTapped(recommendation):
                state.productDetail = ProductDetailFeatureDomain.State(
                    productCode: recommendation.id,
                    context: .explored,
                    productName: recommendation.name,
                    productBrand: recommendation.brand,
                    productImageUrl: recommendation.imageUrl,
                    originalRiskRating: recommendation.originalRiskRating
                )
                return .none
                
            case .productDetail(.presented(.delegate(.requestAccountCreation))):
                // Handle request to create account from rate limit screen
                // Dismiss the product detail and user can navigate to Settings tab to create account
                state.productDetail = nil
                return .none
                
            case .productDetail:
                return .none
                    
            case .loadMoreRecommendations:
                guard !state.isSearchActive && state.canLoadMore else {
                    print("🔎 [Explore] loadMoreRecommendations blocked: isSearchActive=\(state.isSearchActive), canLoadMore=\(state.canLoadMore), hasMorePages=\(state.hasMorePages), isLoadingNextPage=\(state.isLoadingNextPage)")
                    return .none
                }
                print("🔎 [Explore] loadMoreRecommendations starting: currentCount=\(state.recommendations.count), offset=\(state.recommendations.count)")
                state.isLoadingNextPage = true
                state.currentPage += 1
                let offset = state.recommendations.count

                return .run { send in
                    @Dependency(\.productGateway) var gateway

                    let result = await TaskResult {
                        try await gateway.getExploreRecommendations(offset, 10)
                    }

                    await send(.recommendationsReceived(result))
                }
                .cancellable(id: "explore-more-recommendations")

            case .loadMoreSearchResults:
                // Use dedicated search pagination flags
                guard state.isSearchActive && state.searchHasMorePages && !state.isLoadingSearchNextPage else { return .none }
                state.isLoadingSearchNextPage = true
                state.searchCurrentPage += 1
                let offset = state.searchResults.count
                let query = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

                return .run { send in
                    @Dependency(\.productGateway) var gateway

                    let result = await TaskResult {
                        try await gateway.searchProducts(query, offset, 10)
                    }

                    await send(.searchPaginationReceived(result))
                }
                .cancellable(id: "search-pagination")

            case let .searchPaginationReceived(.success(searchResponse)):
                state.isLoadingSearchNextPage = false

                // Convert and append new search results
                let newSearchRecommendations = searchResponse.products.map { product in
                    ProductRecommendation.fromProduct(product)
                }

                for recommendation in newSearchRecommendations {
                    state.searchResults.updateOrAppend(recommendation)
                }

                // Update search pagination state
                state.searchTotalItems = searchResponse.totalResults
                state.searchHasMorePages = state.searchResults.count < searchResponse.totalResults

                return .none

            case let .searchPaginationReceived(.failure(error)):
                state.isLoadingSearchNextPage = false
                state.searchError = "Failed to load more results: \(error.localizedDescription)"
                return .none

            case let .authStateChanged(isAuthenticated):
                // Clear all explore data when auth state changes
                if let lastAuth = state.lastAuthState, lastAuth != isAuthenticated {
                    return .send(.clearExploreData)
                }
                state.lastAuthState = isAuthenticated
                return .none

            case .clearExploreData:
                // Reset all explore state
                state.recommendations = []
                state.searchResults = []
                state.hasMorePages = true
                state.totalItems = 0
                state.currentPage = 0
                state.searchHasMorePages = true
                state.searchTotalItems = 0
                state.searchCurrentPage = 0
                state.isLoading = false
                state.isLoadingNextPage = false
                state.isLoadingSearchNextPage = false
                state.error = nil
                state.searchError = nil

                // Reload recommendations for new auth state
                return .send(.loadRecommendations)

            }
        }
        .ifLet(\.$productDetail, action: \.productDetail) {
            ProductDetailFeatureDomain()
        }
    }
    
    static func mapQualityToSafetyGrade(_ qualityLevel: QualityLevel) -> SafetyGrade {
        switch qualityLevel {
        case .excellent:
            return .excellent
        case .good, .poor:
            return .fair
        case .bad:
            return .bad
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
                        GradeFilterView(store: store)
                    }
                    .onAppear {
                        // Check auth state and clear data if needed
                        @Dependency(\.authState) var authState
                        Task {
                            let currentAuthState = await authState.load()
                            store.send(.authStateChanged(currentAuthState.isLoggedIn))
                        }
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
                            hasActiveFilters: !store.selectedGrades.isEmpty,
                            action: { store.send(.filterButtonTapped) }
                        )
                        
                        ForEach(Array(store.selectedGrades), id: \.self) { grade in
                            gradeFilterChip(grade)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
                .frame(height: 44)
            }
        }
    }
    
    private func gradeFilterChip(_ grade: SafetyGrade) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(gradeColor(for: grade))
                .frame(width: 12, height: 12)
            
            Text(grade.rawValue)
                .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Button {
                store.send(.gradeToggled(grade))
            } label: {
                Image(systemName: "xmark")
                    .font(DesignSystem.Typography.small)
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
    
    private func gradeColor(for grade: SafetyGrade) -> Color {
        switch grade {
        case .excellent:
            return Color(red: 0.0, green: 0.8, blue: 0.0) // Green
        case .fair:
            return Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow
        case .bad:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // Red
        }
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
                .font(.system(size: DesignSystem.Typography.xxxxxl))
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
                    .font(.system(size: DesignSystem.Typography.xxxxxl))
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
                    .font(.system(size: DesignSystem.Typography.xxxxxl))
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
                    let totalItems = store.displayedProducts.count
                    let itemsFromEnd = totalItems - index
                    let nearEnd = itemsFromEnd <= 3
                    let canLoadRecommendations = !store.isSearchActive && store.canLoadMore
                    let canLoadSearch = store.isSearchActive && store.searchHasMorePages && !store.isLoadingSearchNextPage
                    print("🔎 [Explore] Cell onAppear index=\(index), total=\(totalItems), itemsFromEnd=\(itemsFromEnd), nearEnd=\(nearEnd), canLoadRecommendations=\(canLoadRecommendations), canLoadSearch=\(canLoadSearch)")
                    if nearEnd {
                        if canLoadRecommendations {
                            store.send(.loadMoreRecommendations)
                        } else if canLoadSearch {
                            store.send(.loadMoreSearchResults)
                        }
                    }
                }
            }
            
            if store.isLoadingNextPage || store.isLoadingSearchNextPage {
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
                .tint(DesignSystem.Colors.primaryRed)
            Text("Loading more...")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primaryRed)
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
