
import SwiftUI
import ComposableArchitecture

// MARK: - Ingredient Analysis Feature
@Reducer
struct IngredientAnalysisFeature {
    @ObservableState
    struct State: Equatable {
        let ingredient: IngredientRisk
        let fallbackCitations: [Citation]
        
        var individualAnalysis: IndividualIngredientAnalysisResponseWithName?
        var isLoading = false
        var error: String?
        var citationError: String?
        
        var hasIndividualAnalysis: Bool {
            individualAnalysis != nil
        }
        
        var shouldShowHealthEffects: Bool {
            individualAnalysis?.healthEffects != nil && !individualAnalysis!.healthEffects!.isEmpty
        }
        
        var shouldShowRecommendations: Bool {
            individualAnalysis?.alternatives != nil && !individualAnalysis!.alternatives!.isEmpty
        }
        
        var riskColor: Color {
            switch ingredient.riskLevel?.lowercased() {
            case "high": return DesignSystem.Colors.primaryRed
            case "moderate": return DesignSystem.Colors.warning
            case "low": return DesignSystem.Colors.success
            default: return DesignSystem.Colors.textSecondary
            }
        }
        
        init(ingredient: IngredientRisk, fallbackCitations: [Citation] = []) {
            self.ingredient = ingredient
            self.fallbackCitations = fallbackCitations
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case loadIndividualAnalysis
        case individualAnalysisResponse(TaskResult<IndividualIngredientAnalysisResponseWithName>)
        case retryAnalysis
        case retryCitations
        case dismiss
        
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case dismiss
        }
    }
    
    @Dependency(\.productGateway) var productGateway
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                if !state.hasIndividualAnalysis && !state.isLoading {
                    return .send(.loadIndividualAnalysis)
                }
                return .none
                
            case .loadIndividualAnalysis:
                state.isLoading = true
                state.error = nil
                return .run { [ingredientName = state.ingredient.name] send in
                    await send(.individualAnalysisResponse(
                        TaskResult {
                            try await productGateway.getIndividualIngredientAnalysis(ingredientName, nil)
                        }
                    ))
                }
                
            case let .individualAnalysisResponse(.success(analysis)):
                state.isLoading = false
                state.individualAnalysis = analysis
                return .none
                
            case let .individualAnalysisResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case .retryAnalysis:
                return .send(.loadIndividualAnalysis)
                
            case .retryCitations:
                state.citationError = nil
                return .send(.loadIndividualAnalysis)
                
            case .dismiss:
                return .send(.delegate(.dismiss))
                
            case .delegate:
                return .none
            }
        }
    }
    
}

// MARK: - Ingredient Analysis View
struct IngredientAnalysisView: View {
    @Bindable var store: StoreOf<IngredientAnalysisFeature>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        headerSection
                        
                        individualAnalysisSection
                        
                        if store.shouldShowHealthEffects, let healthEffects = store.individualAnalysis?.healthEffects {
                            healthEffectsSection(healthEffects)
                        }
                        
                        if store.shouldShowRecommendations, let analysis = store.individualAnalysis {
                            recommendationsSection(analysis)
                        }
                        
                        citationsSection
                    }
                    .padding(DesignSystem.Spacing.base)
                }
                .background(DesignSystem.Colors.background)
                .navigationTitle("Ingredient Analysis")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            store.send(.dismiss)
                        }
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                }
                .onAppear {
                    store.send(.onAppear)
                }
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(store.ingredient.name)
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if let riskLevel = store.ingredient.riskLevel {
                    Text(riskLevel.uppercased())
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(store.riskColor)
                        .cornerRadius(8)
                }
            }
            
            if let riskLevel = store.ingredient.riskLevel {
                Text("Risk Level: \(riskLevel)")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Individual Analysis Section
    @ViewBuilder
    private var individualAnalysisSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Detailed Analysis")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if store.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if store.isLoading {
                LoadingAnalysisCard()
            } else if let error = store.error {
                ErrorAnalysisCard(error: error) {
                    store.send(.retryAnalysis)
                }
            } else if let analysis = store.individualAnalysis {
                Text(analysis.analysisText)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineSpacing(4)
            } else {
                Text(cleanAnalysisText(store.ingredient.overview ?? store.ingredient.microReport))
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - Health Effects Section
    @ViewBuilder
    private func healthEffectsSection(_ healthEffects: [HealthEffect]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Health Effects")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                ForEach(healthEffects, id: \.effect) { healthEffect in
                    HealthEffectRow(healthEffect: healthEffect)
                }
            }
        }
    }
    
    // MARK: - Recommendations Section
    @ViewBuilder
    private func recommendationsSection(_ analysis: IndividualIngredientAnalysisResponseWithName) -> some View {
        if let alternatives = analysis.alternatives, !alternatives.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Recommendations")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(alternatives, id: \.self) { alternative in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.success)
                                .font(.caption)
                                .padding(.top, 2)
                            
                            Text(alternative)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Citations Section
    @ViewBuilder
    private var citationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Citations")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            let analysisCitations = store.individualAnalysis?.citations ?? []
            let citations = analysisCitations.isEmpty
                ? store.fallbackCitations
                : analysisCitations
            let uniqueCitations = citations.reduce(into: [Citation]()) { result, citation in
                if !result.contains(where: { $0.id == citation.id }) {
                    result.append(citation)
                }
            }
            
            if let citationError = store.citationError {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Citations temporarily unavailable")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.error)
                    
                    Text(citationError)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Button("Try again") {
                        store.send(.retryCitations)
                    }
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                }
                .padding(DesignSystem.Spacing.base)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(12)
            } else if uniqueCitations.isEmpty {
                Text("No citations available for this ingredient")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .italic()
            } else {
                LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(Array(uniqueCitations.enumerated()), id: \.offset) { index, citation in
                        CitationRow(citation: citation, index: index + 1)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func cleanAnalysisText(_ text: String?) -> String {
        guard let text = text else { return "No analysis available" }
        return text.replacingOccurrences(of: "\\n", with: "\n")
                  .replacingOccurrences(of: "\\\"", with: "\"")
                  .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Supporting Views
struct LoadingAnalysisCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading detailed analysis...")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.base)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct ErrorAnalysisCard: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Analysis temporarily unavailable")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.error)
            
            Text(error)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Button("Retry") {
                onRetry()
            }
            .foregroundColor(DesignSystem.Colors.primaryRed)
        }
        .padding(DesignSystem.Spacing.base)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct HealthEffectRow: View {
    let healthEffect: HealthEffect
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(DesignSystem.Colors.primaryRed)
                .font(.caption)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(healthEffect.effect)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .fontWeight(.medium)
                
                Text("Severity: \(healthEffect.severity) | Evidence: \(healthEffect.evidenceLevel)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

struct CitationRow: View {
    let citation: Citation
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
            Text("\(index).")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fontWeight(.medium)
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(citation.title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .fontWeight(.medium)
                
                if let url = citation.url {
                    Link(url, destination: URL(string: url) ?? URL(string: "https://example.com")!)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                        .lineLimit(2)
                }
            }
        }
    }
}
