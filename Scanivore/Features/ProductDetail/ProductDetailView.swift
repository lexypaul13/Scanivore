
import SwiftUI
import ComposableArchitecture
import Alamofire

// MARK: - Product Detail Context
enum ProductDetailContext: Equatable {
    case scanned      // Product was scanned with barcode scanner
    case explored     // Product was viewed from explore/search
    case history      // Product was viewed from scan history
}


// MARK: - Product Detail Feature Domain
@Reducer
struct ProductDetailFeatureDomain {
    @ObservableState
    struct State: Equatable {
        let productCode: String
        let context: ProductDetailContext  // Track how user arrived at product detail
        var productName: String?
        var productBrand: String?
        var productImageUrl: String?
        var originalRiskRating: String? // Add original OpenFoodFacts risk rating
        
        var healthAssessment: HealthAssessmentResponse?
        var isLoading = false
        var error: String?
        var isRateLimited = false
        var showingIngredientSheet = false
        var selectedIngredient: IngredientRisk?
        
        var expandedSections: Set<String> = []
        var selectedIngredientCitations: [Citation] = []
        
        var individualIngredientAnalysis: [String: IndividualIngredientAnalysisResponseWithName] = [:]
        var loadingIndividualAnalysis: Set<String> = []
        var individualAnalysisErrors: [String: String] = [:]
        
        var safetyGrade: SafetyGrade {
            if let riskRating = originalRiskRating {
                return mapRiskRatingToSafetyGrade(riskRating)
            }
            
            if let grade = healthAssessment?.grade, !grade.isEmpty {
                return mapLetterGradeToSafetyGrade(grade)
            }
            
            if let assessment = healthAssessment {
                if let score = assessment.computedRiskSummary?.score {
                    return scoreToSafetyGrade(score)
                }
                
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
            if let assessment = healthAssessment,
               let color = assessment.color {
                switch color.lowercased() {
                case "green": return DesignSystem.Colors.success
                case "yellow": return DesignSystem.Colors.warning
                case "orange": return DesignSystem.Colors.warning
                case "red": return DesignSystem.Colors.error
                default: break
                }
            }
            
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
            
            let highRisk = assessment.high_risk ?? []
            let moderateRisk = assessment.moderate_risk ?? []
            let lowRisk = assessment.low_risk ?? []
            
            return highRisk + moderateRisk + lowRisk
        }
        
        init(
            productCode: String, 
            context: ProductDetailContext,
            productName: String? = nil, 
            productBrand: String? = nil, 
            productImageUrl: String? = nil, 
            originalRiskRating: String? = nil,
            healthAssessment: HealthAssessmentResponse? = nil
        ) {
            self.productCode = productCode
            self.context = context
            self.productName = productName
            self.productBrand = productBrand
            self.productImageUrl = productImageUrl
            self.originalRiskRating = originalRiskRating
            self.healthAssessment = healthAssessment
        }
    }
    enum Action: Equatable {
        case onAppear
        case loadHealthAssessment
        case healthAssessmentReceived(TaskResult<HealthAssessmentResponse>)
        case basicProductReceived(TaskResult<Product>)
        case ingredientTapped(IngredientRisk)
        case dismissIngredientSheet
        case retryTapped
        case createAccountFromRateLimit
        case toggleIngredientSection(String)
        case ingredientTappedWithCitations(IngredientRisk, [Citation])
        
        case loadIndividualIngredientAnalysis(String) // Present tense - user action
        case individualIngredientAnalysisReceived(String, TaskResult<IndividualIngredientAnalysisResponseWithName>) // Past tense - effect response
        case openCitationInSafari(URL) // Present tense - user action
        case citationSafariOpened(Bool) // Past tense - effect response
        
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case requestAccountCreation
        }
    }
    
    @Dependency(\.scannedProducts) var scannedProducts
    @Dependency(\.productGateway) var productGateway
    @Dependency(\.safariService) var safariService
    @Dependency(\.hapticFeedback) var hapticFeedback
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.healthAssessment == nil else {
                    return Effect<Action>.none 
                }
                
                if state.context != .history {
                    return .run { [productCode = state.productCode] send in
                        if let cacheResult = await HealthAssessmentCache.shared.getCachedAssessment(for: productCode) {
                            await send(.healthAssessmentReceived(.success(cacheResult.assessment)))
                        } else {
                            await send(.loadHealthAssessment)
                        }
                    }
                } else {
                    return .run { send in
                        await send(.loadHealthAssessment)
                    }
                }
                
            case .loadHealthAssessment:
                state.isLoading = true
                state.error = nil
                
                return .run { [productCode = state.productCode] send in
                    await send(.healthAssessmentReceived(
                        TaskResult { try await productGateway.getHealthAssessment(productCode) }
                    ))
                }
                
            case let .healthAssessmentReceived(.success(assessment)):
                state.isLoading = false
                state.healthAssessment = assessment
                
                if let productInfo = assessment.product_info {
                    if state.productName == nil && productInfo.name != nil {
                        state.productName = productInfo.name
                    }
                    if state.productBrand == nil && productInfo.brand != nil {
                        state.productBrand = productInfo.brand
                    }
                    if state.productImageUrl == nil && productInfo.image_url != nil {
                        state.productImageUrl = productInfo.image_url
                    }
                }
                
                if state.context == .scanned {
                    return .run { [productCode = state.productCode] _ in
                        let savedProduct = assessment.toSavedProduct(barcode: productCode)
                        await scannedProducts.save(savedProduct)
                    }
                } else {
                    return .none
                }
                
            case let .healthAssessmentReceived(.failure(error)):
                 state.isLoading = false
                
                 if let apiError = error as? APIError {
                     if apiError.statusCode == -1001 {
                        state.error = "Health assessment timed out. Basic product grade available from barcode scan."
                     } else if apiError.statusCode == 429 {
                        state.isRateLimited = true
                        state.error = apiError.detail
                     } else {
                        state.error = apiError.detail
                    }
                } else if let urlError = error as? URLError, urlError.code == .timedOut {
                    state.error = "Health assessment timed out. Basic product grade available from barcode scan."
                 } else if let afError = error as? AFError,
                          case .sessionTaskFailed(let underlyingError) = afError,
                          let urlError = underlyingError as? URLError,
                          urlError.code == .timedOut {
                     state.error = "Health assessment timed out. Basic product grade available from barcode scan."
                 } else {
                    state.error = "Health assessment currently unavailable. Basic product info available."
                }
                
                return .run { [productCode = state.productCode] send in
                     await send(.basicProductReceived(
                        TaskResult { try await productGateway.getProduct(productCode) }
                    ))
                }
                
            case let .basicProductReceived(.success(product)):
                if state.productName == nil { state.productName = product.name }
                if state.productBrand == nil { state.productBrand = product.brand }
                if state.productImageUrl == nil { state.productImageUrl = product.image_url }
                if state.originalRiskRating == nil { state.originalRiskRating = product.risk_rating }
                return .none
                
            case let .basicProductReceived(.failure(error)):
                if state.error == nil {
                    state.error = "Basic product info unavailable."
                }
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
                state.isRateLimited = false
                return .run { send in
                    await send(.loadHealthAssessment)
                }
                
            case .createAccountFromRateLimit:
                return .send(.delegate(.requestAccountCreation))
                
            case let .loadIndividualIngredientAnalysis(ingredientName):
                guard !state.loadingIndividualAnalysis.contains(ingredientName) else {
                    return .none
                }
                
                state.loadingIndividualAnalysis.insert(ingredientName)
                state.individualAnalysisErrors.removeValue(forKey: ingredientName)
                
                return .run { [productCode = state.productCode] send in
                    await send(.individualIngredientAnalysisReceived(
                        ingredientName,
                        TaskResult {
                            try await productGateway.getIndividualIngredientAnalysis(
                                ingredientName,
                                "in product \(productCode)"
                            )
                        }
                    ))
                }
                .cancellable(id: "individual-analysis-\(ingredientName)")
                
            case let .individualIngredientAnalysisReceived(ingredientName, result):
                state.loadingIndividualAnalysis.remove(ingredientName)
                
                switch result {
                case let .success(analysis):
                    state.individualIngredientAnalysis[ingredientName] = analysis
                    state.individualAnalysisErrors.removeValue(forKey: ingredientName)
                    
                case let .failure(error):
                    state.individualAnalysisErrors[ingredientName] = error.localizedDescription
                }
                
                return .none
                
            case let .openCitationInSafari(url):
                return .run { send in
                    await hapticFeedback.impact(.light)
                    
                    let success = await safariService.openURL(url)
                    await send(.citationSafariOpened(success))
                }
                
            case let .citationSafariOpened(success):
                if !success {
                }
                return .none
                
            case .delegate:
                return .none
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
                        EnhancedIndividualIngredientAnalysisView(
                            store: store,
                            ingredient: ingredient,
                            fallbackCitations: store.selectedIngredientCitations
                        )
                        .presentationDetents([.large])
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
                HeroSection(store: store, assessment: assessment)
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    HeadlineSection(store: store)
                    
                    AIHealthSummary(assessment: assessment)
                    
                    CollapsibleIngredientSections(store: store)
                    
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
                FallbackHeroSection(store: store)
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    if store.isRateLimited {
                        RateLimitErrorSection(error: error) {
                            store.send(.createAccountFromRateLimit)
                        }
                    } else {
                        ErrorMessageSection(error: error) {
                            store.send(.retryTapped)
                        }
                    }
                    
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

// MARK: - Rate Limit Error Section  
struct RateLimitErrorSection: View {
    let error: String?
    let onCreateAccount: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: DesignSystem.Typography.xxxxl))
                .foregroundColor(DesignSystem.Colors.warning)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Scan Limit Reached")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(error ?? "Guest users can scan 5 products per hour. Create an account for unlimited scans.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Button("Create Account for Unlimited Scans") {
                onCreateAccount()
            }
            .font(DesignSystem.Typography.buttonText)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.primaryRed)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
}

// MARK: - Error Message Section
struct ErrorMessageSection: View {
    let error: String?
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: DesignSystem.Typography.xxxxl))
                .foregroundColor(DesignSystem.Colors.warning)
            
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
                HStack {
                    Text("Name:")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(store.productName ?? "Product name not provided")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(store.productName != nil ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    Spacer()
                }
                
                HStack {
                    Text("Brand:")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(store.productBrand ?? "Brand information unavailable")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(store.productBrand != nil ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    Spacer()
                }
                
                HStack {
                    Text("Product Code:")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(store.productCode)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Spacer()
                }
                
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
                .font(.system(size: DesignSystem.Typography.xxxxxl))
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
    func createPreviewState() -> ProductDetailFeatureDomain.State {
        var previewState = ProductDetailFeatureDomain.State(
            productCode: "0002000003197",
            context: .scanned,
            productName: "Ground Turkey",
            productBrand: "Simple Truth Organic",
            productImageUrl: "https://example.com/turkey.jpg"
        )
        
        previewState.healthAssessment = .mockHealthAssessment

        
        return previewState
    }
    
    return ProductDetailView(store: Store(initialState: createPreviewState()) {
        ProductDetailFeatureDomain()
    })
}
