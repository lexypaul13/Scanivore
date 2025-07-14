//
//  ProductDetailView.swift
//  Scanivore
//
//  Product detail view using health assessment endpoint with specific interface design
//

import SwiftUI
import ComposableArchitecture

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
        var recommendedSwaps: [ProductRecommendation] = []
        var isLoading = false
        var error: String?
        var showingIngredientSheet = false
        var selectedIngredient: IngredientRisk?
        
        // New state for collapsible ingredients
        var expandedSections: Set<String> = []
        var selectedIngredientCitations: [Citation] = []
        
        // Computed properties  
        var safetyGrade: String {
            // PRIORITY 1: Use original OpenFoodFacts risk_rating for consistency
            if let riskRating = originalRiskRating {
                return mapRiskRatingToGrade(riskRating)
            }
            
            // PRIORITY 2: Get grade from health assessment API
            if let grade = healthAssessment?.grade, !grade.isEmpty {
                return grade
            }
            
            // PRIORITY 3: Fallback to deriving from assessment content
            if let assessment = healthAssessment {
                if let score = assessment.riskSummary?.score {
                    return scoreToGrade(score)
                }
                
                // Analyze summary text for grade indicators
                let summary = assessment.summary.lowercased()
                if summary.contains("excellent") || summary.contains("high-quality") || summary.contains("great") {
                    return "A"
                } else if summary.contains("good") || summary.contains("healthy") {
                    return "B"
                } else if summary.contains("moderate") || summary.contains("caution") {
                    return "C"
                } else if summary.contains("high-risk") || summary.contains("concerning") {
                    return "D"
                }
            }
            
            return "B" // Default fallback
        }
        
        private func mapRiskRatingToGrade(_ riskRating: String) -> String {
            // Map OpenFoodFacts risk_rating to letter grades (A, B, C, D, F)
            switch riskRating.lowercased() {
            case "green": return "A"
            case "yellow": return "C" 
            case "orange": return "D"
            case "red": return "F"
            default: return "C"
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
            
            // Second priority: Map grade to color (handle both letter grades and quality names)
            let grade = safetyGrade
            switch grade {
            case "A", "A+", "Excellent": return DesignSystem.Colors.success
            case "B", "B+", "Good": return Color.blue
            case "C", "C+", "Poor": return DesignSystem.Colors.warning
            case "D", "D+", "F", "Bad": return DesignSystem.Colors.error
            default: return Color.blue
            }
        }
        
        private func scoreToGrade(_ score: Double) -> String {
            switch score {
            case 90...100: return "A"
            case 80..<90: return "B"
            case 70..<80: return "C"
            case 60..<70: return "D"
            default: return "F"
            }
        }
        
        var allIngredients: [IngredientRisk] {
            guard let assessment = healthAssessment,
                  let ingredientsAssessment = assessment.ingredientsAssessment else { return [] }
            return (ingredientsAssessment.highRisk ?? []) + 
                   (ingredientsAssessment.moderateRisk ?? []) + 
                   (ingredientsAssessment.lowRisk ?? [])
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
        case loadRecommendedSwaps
        case recommendedSwapsResponse(TaskResult<[Product]>)
        case ingredientTapped(IngredientRisk)
        case dismissIngredientSheet
        case retryTapped
        case dismissTapped
        
        // New actions for collapsible sections
        case toggleIngredientSection(String)
        case ingredientTappedWithCitations(IngredientRisk, [Citation])
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Check if we already have the assessment or if it needs refresh
                guard state.healthAssessment == nil else { return .none }
                
                // Check cache first to potentially avoid loading state
                if let cachedAssessment = HealthAssessmentCache.shared.getCachedAssessment(for: state.productCode) {
                    state.healthAssessment = cachedAssessment
                    state.isLoading = false
                    state.error = nil
                    return .none
                }
                
                return .run { send in
                    await send(.loadHealthAssessment)
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
                
                return .run { send in
                    await send(.loadRecommendedSwaps)
                }
                
            case let .healthAssessmentResponse(.failure(error)):
                print("❌ Health assessment failed for \(state.productCode): \(error)")
                state.isLoading = false
                
                // Set user-friendly error message based on error type
                if let apiError = error as? APIError {
                    state.error = apiError.detail
                } else {
                    state.error = "Health assessment currently unavailable. Basic product info available."
                }
                
                // Load recommended swaps even when health assessment fails
                return .run { send in
                    await send(.loadRecommendedSwaps)
                }
                
            case .loadBasicProduct:
                // This action is deprecated - we now handle failures with graceful fallback UI
                return .none
                
            case let .basicProductResponse(.success(product)):
                // This action is deprecated - we now handle failures with graceful fallback UI
                return .none
                
            case let .basicProductResponse(.failure(error)):
                // This action is deprecated - we now handle failures with graceful fallback UI
                return .none
                
            case .loadRecommendedSwaps:
                return .run { [productCode = state.productCode] send in
                    await send(.recommendedSwapsResponse(
                        TaskResult {
                            @Dependency(\.productGateway) var productGateway
                            return try await productGateway.getAlternatives(productCode)
                        }
                    ))
                }
                
            case let .recommendedSwapsResponse(.success(products)):
                let swaps = products.prefix(5).map { product in
                    ProductRecommendation.fromProduct(product)
                }
                state.recommendedSwaps = Array(swaps)
                return .none
                
            case .recommendedSwapsResponse(.failure):
                // Silently handle alternatives failure
                return .none
                
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
                
            case .dismissTapped:
                return .run { _ in
                    await dismiss()
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            store.send(.dismissTapped)
                        }
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                }
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
                    
                    // Recommended Swaps Carousel
                    if !store.recommendedSwaps.isEmpty {
                        RecommendedSwapsCarousel(swaps: store.recommendedSwaps)
                    }
                }
                .background(DesignSystem.Colors.background)
                .padding(.top, DesignSystem.Spacing.xxl)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

// MARK: - Hero Section
struct HeroSection: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    let assessment: HealthAssessmentResponse
    
    var body: some View {
        ZStack {
            // Product Image
            AsyncImage(url: URL(string: store.productImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                case .failure(_), .empty:
                    Rectangle()
                        .fill(DesignSystem.Colors.backgroundSecondary)
                        .frame(height: 250)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Text("No Image")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            // Gradient Overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Safety Grade Badge
            VStack {
                HStack {
                    Spacer()
                    SafetyGradeBadge(
                        grade: store.safetyGrade,
                        color: store.safetyColor
                    )
                    .padding(.trailing, DesignSystem.Spacing.base)
                }
                .padding(.top, DesignSystem.Spacing.base)
                Spacer()
            }
        }
        .frame(height: 250)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
    }
}

// MARK: - Safety Grade Badge
struct SafetyGradeBadge: View {
    let grade: String
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 60, height: 60)
            
            Text(grade)
                .font(DesignSystem.Typography.heading2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .shadow(
            color: .black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Headline Section
struct HeadlineSection: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(store.productName ?? "Product name not available")
                .font(DesignSystem.Typography.heading1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Text(store.productBrand ?? "Brand information unavailable")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .padding(.top, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

// MARK: - Nutrition Scroll View
struct NutritionScrollView: View {
    let assessment: HealthAssessmentResponse
    
    // Debug function to check all data access paths - moved outside the view body
    private func getDebugNutritionData() -> [NutritionInsight] {
        #if DEBUG
        print("🍎 === DEBUG NUTRITION DATA ACCESS ===")
        print("🍎 Direct assessment.nutrition: \(assessment.nutrition?.count ?? 0) items")
        print("🍎 Computed nutritionInsights: \(assessment.nutritionInsights?.count ?? 0) items")
        #endif
        
        // Try both access methods
        if let direct = assessment.nutrition, !direct.isEmpty {
            #if DEBUG
            print("🍎 Using direct assessment.nutrition")
            #endif
            return direct
        } else if let computed = assessment.nutritionInsights, !computed.isEmpty {
            #if DEBUG
            print("🍎 Using computed nutritionInsights")
            #endif
            return computed
        }
        
        #if DEBUG
        print("🍎 No nutrition data found via either method")
        #endif
        return []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Nutrition Information")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.base) {
                    let nutritionData = getDebugNutritionData()
                    
                    if !nutritionData.isEmpty {
                        // Map through the nutrition array dynamically
                        ForEach(Array(nutritionData.enumerated()), id: \.offset) { index, insight in
                            NutritionCard(insight: insight)
                        }
                    } else {
                        // Debug logging for skeleton fallback
                        let _ = print("🍎 ❌ NutritionScrollView: No nutrition data found, showing skeleton")
                        
                        // Show skeleton cards for missing nutrition data
                        ForEach(["Calories", "Protein", "Fat", "Sodium", "Fiber", "Sugar"], id: \.self) { nutrient in
                            SkeletonNutritionCard(nutrient: nutrient)
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            }
        }
    }
}

// MARK: - Nutrition Card
struct NutritionCard: View {
    let insight: NutritionInsight
    
    private var evaluationColor: Color {
        switch insight.evaluation.lowercased() {
        case "excellent", "good": return DesignSystem.Colors.success
        case "moderate": return DesignSystem.Colors.warning
        case "high", "poor": return DesignSystem.Colors.error
        default: return DesignSystem.Colors.textSecondary
        }
    }
    
    private var badgeBackgroundColor: Color {
        evaluationColor.opacity(0.1)
    }
    
    var body: some View {
        #if DEBUG
        // Debug logging is now properly wrapped in a debug directive
        // and doesn't affect the view body
        let _ = {
            print("🍎 NutritionCard rendering: \(insight.nutrient) = \(insight.amount)")
            print("🍎 Comment available: \(insight.comment != nil)")
        }()
        #endif
        
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Nutrient name
            Text(insight.nutrient)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
            
            // Amount per serving
            Text(insight.amountPerServing)
                .font(DesignSystem.Typography.heading3)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
            
            // Daily Value if available
            if let dailyValue = insight.dailyValue, !dailyValue.isEmpty {
                Text(dailyValue + " DV")
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // AI Commentary - Full text without truncation
            if let comment = insight.comment, !comment.isEmpty {
                Text(comment)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineSpacing(3)
                    .padding(.top, DesignSystem.Spacing.xs)
            }
            
            Spacer(minLength: DesignSystem.Spacing.xs)
            
            // Evaluation badge
            HStack {
                Circle()
                    .fill(evaluationColor)
                    .frame(width: 6, height: 6)
                
                Text(insight.evaluation.capitalized)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(evaluationColor)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(badgeBackgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.full)
        }
        .padding(DesignSystem.Spacing.base)
        .frame(width: 200)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: 0,
            y: DesignSystem.Shadow.offsetLight.height
        )
    }
}

// MARK: - Skeleton Nutrition Card
struct SkeletonNutritionCard: View {
    let nutrient: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Nutrient name
            Text(nutrient)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(1)
            
            // Placeholder amount
            Text("Not available")
                .font(DesignSystem.Typography.heading3)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // Placeholder daily value
            Text("Data unavailable")
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            // Placeholder evaluation
            HStack {
                Circle()
                    .fill(DesignSystem.Colors.textSecondary.opacity(0.3))
                    .frame(width: 6, height: 6)
                
                Text("Information unavailable")
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.CornerRadius.full)
        }
        .padding(DesignSystem.Spacing.base)
        .frame(width: 200, height: 180)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

// Legacy QuickMetric components removed - replaced with NutritionCard components

// MARK: - Collapsible Ingredient Sections
struct CollapsibleIngredientSections: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    let assessment: HealthAssessmentResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Ingredients Analysis")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            
            VStack(spacing: DesignSystem.Spacing.base) {
                // High Risk Ingredients - using direct fields from assessment
                if let highRisk = assessment.highRisk, !highRisk.isEmpty {
                    CollapsibleIngredientSection(
                        sectionId: "high-risk",
                        title: "High Risk",
                        ingredients: highRisk,
                        color: DesignSystem.Colors.error,
                        isExpanded: store.expandedSections.contains("high-risk"),
                        onToggle: { store.send(.toggleIngredientSection("high-risk")) },
                        onIngredientTap: { ingredient in
                            store.send(.ingredientTappedWithCitations(ingredient, assessment.citations ?? []))
                        }
                    )
                }
                
                // Moderate Risk Ingredients - using direct fields from assessment
                if let moderateRisk = assessment.moderateRisk, !moderateRisk.isEmpty {
                    CollapsibleIngredientSection(
                        sectionId: "moderate-risk",
                        title: "Moderate Risk",
                        ingredients: moderateRisk,
                        color: DesignSystem.Colors.warning,
                        isExpanded: store.expandedSections.contains("moderate-risk"),
                        onToggle: { store.send(.toggleIngredientSection("moderate-risk")) },
                        onIngredientTap: { ingredient in
                            store.send(.ingredientTappedWithCitations(ingredient, assessment.citations ?? []))
                        }
                    )
                }
                
                // Low Risk Ingredients - using direct fields from assessment  
                if let lowRisk = assessment.lowRisk, !lowRisk.isEmpty {
                    CollapsibleIngredientSection(
                        sectionId: "low-risk",
                        title: "Low Risk",
                        ingredients: lowRisk,
                        color: DesignSystem.Colors.success,
                        isExpanded: store.expandedSections.contains("low-risk"),
                        onToggle: { store.send(.toggleIngredientSection("low-risk")) },
                        onIngredientTap: { ingredient in
                            store.send(.ingredientTappedWithCitations(ingredient, assessment.citations ?? []))
                        }
                    )
                }
                
                // Show message if no risk ingredients found
                if (assessment.highRisk?.isEmpty ?? true) &&
                   (assessment.moderateRisk?.isEmpty ?? true) &&
                   (assessment.lowRisk?.isEmpty ?? true) {
                    Text("Ingredient analysis not available for this product")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        }
    }
}

// MARK: - Collapsible Ingredient Section
struct CollapsibleIngredientSection: View {
    let sectionId: String
    let title: String
    let ingredients: [IngredientRisk]
    let color: Color
    let isExpanded: Bool
    let onToggle: () -> Void
    let onIngredientTap: (IngredientRisk) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            // Section Header
            Button(action: onToggle) {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    Text("\(title) (\(ingredients.count))")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.vertical, DesignSystem.Spacing.base)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Ingredients List (Expandable)
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: DesignSystem.Spacing.md)
                ], spacing: DesignSystem.Spacing.md) {
                    ForEach(ingredients, id: \.name) { ingredient in
                        CollapsibleIngredientPill(
                            ingredient: ingredient,
                            color: color,
                            onTap: { onIngredientTap(ingredient) }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.base)
                .padding(.top, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.sm)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
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

// MARK: - Collapsible Ingredient Pill
struct CollapsibleIngredientPill: View {
    let ingredient: IngredientRisk
    let color: Color
    let onTap: () -> Void
    
    // Generate consistent color variations based on ingredient name
    var ingredientColor: Color {
        let baseColor = color // Category color (red/yellow/green)
        let hash = abs(ingredient.name.hashValue)
        
        // Generate hue shift (-20 to +20 degrees)
        let hueShift = Double((hash % 40) - 20) / 360.0
        
        // Generate saturation variation (0.85 to 1.0)
        let saturationMultiplier = 0.85 + (Double(hash % 15) / 100.0)
        
        // Generate brightness variation (0.9 to 1.1)
        let brightnessMultiplier = 0.9 + (Double(hash % 20) / 100.0)
        
        // Apply color modifications
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var opacity: CGFloat = 0
        
        UIColor(baseColor).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &opacity)
        
        // Apply variations
        hue += CGFloat(hueShift)
        saturation *= CGFloat(saturationMultiplier)
        brightness *= CGFloat(brightnessMultiplier)
        
        // Ensure values are in valid ranges
        hue = max(0, min(1, hue))
        saturation = max(0, min(1, saturation))
        brightness = max(0, min(1, brightness))
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: opacity))
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(ingredient.name)
                .font(DesignSystem.Typography.small)
                .foregroundColor(ingredientColor.opacity(0.9))
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            ingredientColor.opacity(0.12),
                            ingredientColor.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.full)
                        .stroke(ingredientColor.opacity(0.35), lineWidth: 1)
                )
                .cornerRadius(DesignSystem.CornerRadius.full)
                .shadow(color: ingredientColor.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Legacy components kept for compatibility - these may be used elsewhere

// MARK: - Skeleton Ingredients Section
struct SkeletonIngredientsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Common Ingredients")
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: DesignSystem.Spacing.xs)
            ], spacing: DesignSystem.Spacing.xs) {
                ForEach(["Turkey", "Salt", "Spices", "Water"], id: \.self) { ingredient in
                    Button {} label: {
                        Text(ingredient)
                            .font(DesignSystem.Typography.small)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(DesignSystem.Colors.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.full)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(DesignSystem.CornerRadius.full)
                    }
                    .disabled(true)
                }
            }
        }
    }
}

// MARK: - AI Health Summary
struct AIHealthSummary: View {
    let assessment: HealthAssessmentResponse
    
    private var cleanedSummary: String {
        // Remove citation markers like [1], [2], etc.
        let pattern = "\\[\\d+\\]"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: assessment.summary.count)
        return regex?.stringByReplacingMatches(in: assessment.summary, options: [], range: range, withTemplate: "") ?? assessment.summary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .font(.system(size: 20, weight: .medium))
                Text("AI Health Summary")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Text(cleanedSummary)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(6)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.primaryRed, lineWidth: 1)
        )
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: 0,
            y: DesignSystem.Shadow.offsetLight.height
        )
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

// MARK: - Recommended Swaps Carousel
struct RecommendedSwapsCarousel: View {
    let swaps: [ProductRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Recommended Swaps")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(swaps) { swap in
                        SwapProductCard(recommendation: swap)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            }
        }
    }
}

// MARK: - Swap Product Card
struct SwapProductCard: View {
    let recommendation: ProductRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Product Image
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .frame(width: 120, height: 80)
                
                if let imageUrl = recommendation.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 80)
                                .clipped()
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        case .failure(_), .empty:
                            PlaceholderImage()
                                .frame(width: 120, height: 80)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    PlaceholderImage()
                        .frame(width: 120, height: 80)
                }
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.name)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(recommendation.brand)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                
                QualityBadge(level: recommendation.qualityRating)
                    .scaleEffect(0.8, anchor: .leading)
            }
        }
        .frame(width: 120)
        .padding(DesignSystem.Spacing.sm)
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

// MARK: - Enhanced Ingredient Detail Sheet
struct EnhancedIngredientDetailSheet: View {
    let ingredient: IngredientRisk
    let citations: [Citation]
    @Environment(\.dismiss) private var dismiss
    
    private var riskColor: Color {
        switch ingredient.riskLevel?.lowercased() {
        case "high": return DesignSystem.Colors.error
        case "moderate": return DesignSystem.Colors.warning
        case "low": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.textSecondary
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Header Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text(ingredient.name)
                            .font(DesignSystem.Typography.heading1)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if let riskLevel = ingredient.riskLevel {
                            HStack {
                                Circle()
                                    .fill(riskColor)
                                    .frame(width: 8, height: 8)
                                
                                Text("\(riskLevel.capitalized) Risk")
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(riskColor)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.base)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(riskColor.opacity(0.1))
                            .cornerRadius(DesignSystem.CornerRadius.full)
                        }
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Analysis")
                            .font(DesignSystem.Typography.heading3)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(ingredient.microReport)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineSpacing(4)
                    }
                    
                    // Citations Section
                    if !citations.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Scientific References")
                                .font(DesignSystem.Typography.heading3)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(citations.prefix(3), id: \.id) { citation in
                                    CitationCard(citation: citation)
                                }
                            }
                            
                            if citations.count > 3 {
                                Text("+ \(citations.count - 3) more references")
                                    .font(DesignSystem.Typography.small)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.top, DesignSystem.Spacing.xs)
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.base)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Ingredient Details")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Citation Card
struct CitationCard: View {
    let citation: Citation
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(citation.title)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
            
            if let authors = citation.authors {
                Text(authors)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            HStack {
                if let journal = citation.journal {
                    Text(journal)
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                if let year = citation.year {
                    Text("(\(year))")
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if citation.url != nil {
                    Image(systemName: "link")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .onTapGesture {
            if let urlString = citation.url, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Legacy Ingredient Detail Sheet (for backward compatibility)
struct IngredientDetailSheet: View {
    let ingredient: IngredientRisk
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        EnhancedIngredientDetailSheet(ingredient: ingredient, citations: [])
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading product details...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
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
                    
                    // Recommended Swaps Carousel (if available)
                    if !store.recommendedSwaps.isEmpty {
                        RecommendedSwapsCarousel(swaps: store.recommendedSwaps)
                    }
                }
                .background(DesignSystem.Colors.background)
                .padding(.top, DesignSystem.Spacing.xxl)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

// MARK: - Fallback Hero Section
struct FallbackHeroSection: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    
    var body: some View {
        ZStack {
            // Product Image
            AsyncImage(url: URL(string: store.productImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                        .overlay(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            DesignSystem.Colors.background.opacity(0.1),
                                            DesignSystem.Colors.background.opacity(0.7)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                case .failure(_), .empty:
                    Rectangle()
                        .fill(DesignSystem.Colors.backgroundSecondary)
                        .frame(height: 250)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Text("No Image")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            // Grade Badge - Always show using originalRiskRating
            VStack {
                HStack {
                    Spacer()
                    
                    // Safety Grade Badge
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text(store.safetyGrade)
                            .font(DesignSystem.Typography.heading1)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Safety Grade")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(store.safetyColor)
                            .shadow(
                                color: DesignSystem.Shadow.medium,
                                radius: DesignSystem.Shadow.radiusMedium,
                                x: 0,
                                y: DesignSystem.Shadow.offsetMedium.height
                            )
                    )
                }
                .padding(.top, DesignSystem.Spacing.lg)
                .padding(.trailing, DesignSystem.Spacing.screenPadding)
                
                Spacer()
            }
        }
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
        previewState.recommendedSwaps = [
            ProductRecommendation(
                id: "mock1",
                name: "Organic Ground Turkey",
                brand: "Bell & Evans",
                imageUrl: nil,
                imageData: nil,
                meatType: .turkey,
                qualityRating: .excellent, originalRiskRating: "A",
                isRecommended: true,
                matchReasons: ["Organic", "No preservatives"],
                concerns: []
            ),
            ProductRecommendation(
                id: "mock2",
                name: "Free Range Ground Turkey",
                brand: "Perdue",
                imageUrl: nil,
                imageData: nil,
                meatType: .turkey,
                qualityRating: .good, originalRiskRating: "A",
                isRecommended: true,
                matchReasons: ["Free range"],
                concerns: []
            )
        ]
        
        return previewState
    }
    
    // Use the function to create the state
    return ProductDetailView(store: Store(initialState: createPreviewState()) {
        ProductDetailFeatureDomain()
    })
}
