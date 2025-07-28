//
//  ProductDetailView.swift
//  Scanivore
//
//  Product detail view using health assessment endpoint with specific interface design
//

import SwiftUI
import ComposableArchitecture

// MARK: - SafetyGrade Enum
public enum SafetyGrade: String, CaseIterable {
    case excellent = "Excellent"
    case fair = "Fair"
    case bad = "Bad"
}

// MARK: - Product Detail Feature Domain
@Reducer
struct ProductDetailFeatureDomain {
    @ObservableState
    struct State: Equatable {
        let productCode: String
        let productName: String?
        let productBrand: String?
        let productImageUrl: String?
        let originalRiskRating: String? // Add original OpenFoodFacts risk rating
        
        var healthAssessment: HealthAssessmentResponse?
        // Recommended swaps feature removed to fix 404 errors
        var isLoading = false
        var error: String?
        var showingIngredientSheet = false
        var selectedIngredient: IngredientRisk?
        
        // New state for collapsible ingredients
        var expandedSections: Set<String> = []
        var selectedIngredientCitations: [Citation] = []
        
        // Computed properties  
        var safetyGrade: SafetyGrade {
            // PRIORITY 1: Use original OpenFoodFacts risk_rating for consistency
            if let riskRating = originalRiskRating {
                return mapRiskRatingToSafetyGrade(riskRating)
            }
            
            // PRIORITY 2: Get grade from health assessment API
            if let grade = healthAssessment?.grade, !grade.isEmpty {
                return mapLetterGradeToSafetyGrade(grade)
            }
            
            // PRIORITY 3: Fallback to deriving from assessment content
            if let assessment = healthAssessment {
                if let score = assessment.riskSummary?.score {
                    return scoreToSafetyGrade(score)
                }
                
                // Analyze summary text for grade indicators
                let summary = assessment.summary.lowercased()
                if summary.contains("excellent") || summary.contains("high-quality") || summary.contains("great") {
                    return .excellent
                } else if summary.contains("good") || summary.contains("healthy") {
                    return .excellent
                } else if summary.contains("moderate") || summary.contains("caution") {
                    return .fair
                } else if summary.contains("high-risk") || summary.contains("concerning") {
                    return .bad
                }
            }
            
            return .fair // Default fallback
        }
        
        private func mapRiskRatingToSafetyGrade(_ riskRating: String) -> SafetyGrade {
            switch riskRating.lowercased() {
            case "green": return .excellent
            case "yellow": return .fair
            case "orange", "red": return .bad
            default: return .fair
            }
        }
        
        private func mapLetterGradeToSafetyGrade(_ grade: String) -> SafetyGrade {
            switch grade.uppercased() {
            case "A", "B": return .excellent
            case "C": return .fair
            case "D", "F": return .bad
            default: return .fair
            }
        }
        
        var safetyColor: Color {
            // First priority: Use color directly from API if available
            if let assessment = healthAssessment,
               let color = assessment.color {
                switch color.lowercased() {
                case "green": return DesignSystem.Colors.success
                case "yellow": return DesignSystem.Colors.warning
                case "orange": return Color.orange
                case "red": return DesignSystem.Colors.error
                default: break
                }
            }
            
            // Second priority: Map SafetyGrade to color
            let grade = safetyGrade
            switch grade {
            case .excellent: return DesignSystem.Colors.success
            case .fair: return DesignSystem.Colors.warning
            case .bad: return DesignSystem.Colors.error
            }
        }
        
        private func scoreToSafetyGrade(_ score: Double) -> SafetyGrade {
            switch score {
            case 80...100: return .excellent
            case 60..<80: return .fair
            default: return .bad
            }
        }
        
        var allIngredients: [IngredientRisk] {
            guard let assessment = healthAssessment else { 
                return [] 
            }
            
            // Use direct API fields that match actual response structure
            let highRisk = assessment.high_risk ?? []
            let moderateRisk = assessment.moderate_risk ?? []
            let lowRisk = assessment.low_risk ?? []
            
            return highRisk + moderateRisk + lowRisk
        }
        
        init(productCode: String, productName: String? = nil, productBrand: String? = nil, productImageUrl: String? = nil, originalRiskRating: String? = nil) {
            self.productCode = productCode
            self.productName = productName
            self.productBrand = productBrand
            self.productImageUrl = productImageUrl
            self.originalRiskRating = originalRiskRating
        }
    }
    
    enum Action {
        case onAppear
        case loadHealthAssessment
        case healthAssessmentResponse(TaskResult<HealthAssessmentResponse>)
        case loadBasicProduct
        case basicProductResponse(TaskResult<Product>)
        // Recommended swaps actions removed
        case ingredientTapped(IngredientRisk)
        case dismissIngredientSheet
        case retryTapped
        // New actions for collapsible sections
        case toggleIngredientSection(String)
        case ingredientTappedWithCitations(IngredientRisk, [Citation])
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Check if we already have the assessment or if it needs refresh
                guard state.healthAssessment == nil else { return .none }
                
                // Check cache first to potentially avoid loading state (async to avoid main thread blocking)
                return .run { [productCode = state.productCode] send in
                    if let cacheResult = await HealthAssessmentCache.shared.getCachedAssessment(for: productCode) {
                        await send(.healthAssessmentResponse(.success(cacheResult.assessment)))
                        
                        // Log instant performance for cache hits
                        if cacheResult.fromCache {
                            print("🚀 ProductDetail: INSTANT cache hit - no loading needed!")
                        }
                    } else {
                        // Cache miss - proceed with network fetch
                        await send(.loadHealthAssessment)
                    }
                }
                
            case .loadHealthAssessment:
                state.isLoading = true
                state.error = nil
                
                return .run { [productCode = state.productCode] send in
                    await send(.healthAssessmentResponse(
                        TaskResult {
                            @Dependency(\.productGateway) var productGateway
                            return try await productGateway.getHealthAssessment(productCode)
                        }
                    ))
                }
                
            case let .healthAssessmentResponse(.success(assessment)):
                state.isLoading = false
                state.healthAssessment = assessment
                
                return .none
                
            case let .healthAssessmentResponse(.failure(error)):
                print("❌ Health assessment failed for \(state.productCode): \(error)")
                state.isLoading = false
                
                // Set user-friendly error message based on error type
                if let apiError = error as? APIError {
                    state.error = apiError.detail
                } else {
                    state.error = "Health assessment currently unavailable. Basic product info available."
                }
                
                // Health assessment failed, but continue without recommended swaps
                return .none
                
            case .loadBasicProduct:
                // This action is deprecated - we now handle failures with graceful fallback UI
                return .none
                
            case let .basicProductResponse(.success(product)):
                // This action is deprecated - we now handle failures with graceful fallback UI
                return .none
                
            case let .basicProductResponse(.failure(error)):
                // This action is deprecated - we now handle failures with graceful fallback UI
                return .none
                
            // Recommended swaps functionality removed
                
            case let .ingredientTapped(ingredient):
                state.selectedIngredient = ingredient
                state.selectedIngredientCitations = state.healthAssessment?.citations ?? []
                state.showingIngredientSheet = true
                return .none
                
            case let .toggleIngredientSection(sectionId):
                if state.expandedSections.contains(sectionId) {
                    state.expandedSections.remove(sectionId)
                } else {
                    state.expandedSections.insert(sectionId)
                }
                return .none
                
            case let .ingredientTappedWithCitations(ingredient, citations):
                state.selectedIngredient = ingredient
                state.selectedIngredientCitations = citations
                state.showingIngredientSheet = true
                return .none
                
            case .dismissIngredientSheet:
                state.showingIngredientSheet = false
                state.selectedIngredient = nil
                return .none
                
            case .retryTapped:
                state.error = nil
                return .run { send in
                    await send(.loadHealthAssessment)
                }
            }
        }
    }
}

// MARK: - Product Detail View
struct ProductDetailView: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    DesignSystem.Colors.backgroundSecondary
                        .ignoresSafeArea()
                    
                    if store.isLoading {
                        LoadingView()
                    } else if let assessment = store.healthAssessment {
                        ProductDetailContentView(
                            store: store,
                            assessment: assessment
                        )
                    } else {
                        // Graceful fallback view - show basic info even when API fails
                        GracefulFallbackView(store: store, error: store.error)
                    }
                }
                .customNavigationTitle("Product Details")
                .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .sheet(isPresented: .init(
                    get: { store.showingIngredientSheet },
                    set: { _ in store.send(.dismissIngredientSheet) }
                )) {
                    if let ingredient = store.selectedIngredient {
                        EnhancedIngredientDetailSheet(
                            ingredient: ingredient,
                            citations: store.selectedIngredientCitations
                        )
                        .presentationDetents([.fraction(0.4), .medium, .large])
                        .presentationDragIndicator(.visible)
                    }
                }
                .onAppear {
                    store.send(.onAppear)
                }
            }
        }
    }
}

// MARK: - Product Detail Content
struct ProductDetailContentView: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    let assessment: HealthAssessmentResponse
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section
                HeroSection(store: store, assessment: assessment)
                
                // White content background
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Headline Section
                    HeadlineSection(store: store)
                    
                    // AI Health Summary (moved to top)
                    AIHealthSummary(assessment: assessment)
                    
                    // Collapsible Ingredient Risk Sections
                    CollapsibleIngredientSections(store: store, assessment: assessment)
                    
                    // Horizontal Nutrition Scroll
                    NutritionScrollView(assessment: assessment)
                    
                }
                .background(DesignSystem.Colors.background)
                .padding(.top, DesignSystem.Spacing.xxl)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

// MARK: - Graceful Fallback View
struct GracefulFallbackView: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    let error: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Fallback Hero Section with Grade Badge
                FallbackHeroSection(store: store)
                
                // White content background
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Error message with retry option
                    ErrorMessageSection(error: error) {
                        store.send(.retryTapped)
                    }
                    
                    // Show basic product info if available
                    BasicProductInfoSection(store: store)
                    
                   
                }
                .background(DesignSystem.Colors.background)
                .padding(.top, DesignSystem.Spacing.xxl)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

// MARK: - Error Message Section
struct ErrorMessageSection: View {
    let error: String?
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Colors.warning)
            
            // Error message
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Limited Information Available")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(error ?? "We couldn't load the full health assessment, but you can see the basic safety grade above.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Retry button
            Button("Try Again") {
                onRetry()
            }
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.primaryRed)
            .padding(.vertical, DesignSystem.Spacing.md)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.primaryRed, lineWidth: 1)
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
    }
}

// MARK: - Basic Product Info Section
struct BasicProductInfoSection: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Product Information")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Always show product name with fallback
                HStack {
                    Text("Name:")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(store.productName ?? "Product name not provided")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(store.productName != nil ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    Spacer()
                }
                
                // Always show brand with fallback
                HStack {
                    Text("Brand:")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(store.productBrand ?? "Brand information unavailable")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(store.productBrand != nil ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    Spacer()
                }
                
                // Always show product code
                HStack {
                    Text("Product Code:")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(store.productCode)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Spacer()
                }
                
                // Always show risk rating with fallback
                HStack {
                    Text("Risk Rating:")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(store.originalRiskRating ?? "Risk assessment pending")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(store.originalRiskRating != nil ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    Spacer()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            .padding(.vertical, DesignSystem.Spacing.base)
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
               Text("Generating health analysis...")
                .font(DesignSystem.Typography.body)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(DesignSystem.Colors.error)
            
            Text("Product Not Available")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(error)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Button("Try Again") {
                    onRetry()
                }
                .primaryButton()
                .frame(width: 120)
                
                Text("This product may not have health assessment data available yet. We're constantly adding new products to our database.")
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    // Create a function to set up the preview state
    func createPreviewState() -> ProductDetailFeatureDomain.State {
        var previewState = ProductDetailFeatureDomain.State(
            productCode: "0002000003197",
            productName: "Ground Turkey",
            productBrand: "Simple Truth Organic",
            productImageUrl: "https://example.com/turkey.jpg"
        )
        
        previewState.healthAssessment = .mockHealthAssessment

        
        return previewState
    }
    
    // Use the function to create the state
    return ProductDetailView(store: Store(initialState: createPreviewState()) {
        ProductDetailFeatureDomain()
    })
}
