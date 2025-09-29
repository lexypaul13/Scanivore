//
//  IndividualIngredientAnalysisView.swift
//  Scanivore
//
//  TCA-compliant individual ingredient analysis view
//

import SwiftUI
import ComposableArchitecture

// MARK: - Enhanced Individual Ingredient Analysis View
struct EnhancedIndividualIngredientAnalysisView: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    let ingredient: IngredientRisk
    let fallbackCitations: [Citation]
    @Environment(\.dismiss) private var dismiss
    
    private var individualAnalysis: IndividualIngredientAnalysisResponseWithName? {
        store.individualIngredientAnalysis[ingredient.name]
    }
    
    private var isLoadingAnalysis: Bool {
        store.loadingIndividualAnalysis.contains(ingredient.name)
    }
    
    private var analysisError: String? {
        store.individualAnalysisErrors[ingredient.name]
    }
    
    private var riskColor: Color {
        switch ingredient.riskLevel?.lowercased() {
        case "high": return DesignSystem.Colors.primaryRed
        case "moderate": return DesignSystem.Colors.warning
        case "low": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.textSecondary
        }
    }
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        // Header Section
                        headerSection
                        
                        // Individual Analysis Section
                        individualAnalysisSection
                        
                        // Health Effects Section
                        if let analysis = individualAnalysis,
                           let healthEffects = analysis.healthEffects,
                           !healthEffects.isEmpty {
                            healthEffectsSection(healthEffects)
                        }
                        
                        
                        // Citations Section
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
                            dismiss()
                        }
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                }
                .onAppear {
                    // Load individual analysis if not already loaded or loading
                    if individualAnalysis == nil && !isLoadingAnalysis {
                        store.send(.loadIndividualIngredientAnalysis(ingredient.name))
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
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
            
            // Risk Score Badge (if available from individual analysis)
            if let analysis = individualAnalysis, let risk = analysis.riskScore {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                    Text("Risk Score: \(String(format: "%.1f", risk))/10")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .padding(.horizontal, DesignSystem.Spacing.base)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(DesignSystem.CornerRadius.sm)
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
                
                if isLoadingAnalysis {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if isLoadingAnalysis {
                LoadingAnalysisCard()
            } else if let error = analysisError {
                ErrorAnalysisCard(error: error) {
                    store.send(.loadIndividualIngredientAnalysis(ingredient.name))
                }
            } else if let analysis = individualAnalysis {
                Text(analysis.analysisText)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineSpacing(4)
            } else {
                // Fallback to existing overview/risk text
                Text(cleanAnalysisText(ingredient.overview ?? ingredient.microReport))
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - Health Effects Section
    @ViewBuilder
    private func healthEffectsSection(_ healthEffects: [HealthEffect]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Health Effects")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(healthEffects.prefix(5), id: \.category) { effect in
                    HealthEffectCard(effect: effect)
                }
            }
        }
    }
    
    
    // MARK: - Citations Section
    @ViewBuilder
    private var citationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            let citations = individualAnalysis?.citations ?? fallbackCitations
            
            if !citations.isEmpty {
                // Citations Section Header
                Text("Research Citations")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(citations.prefix(5), id: \.id) { citation in
                        EnhancedCitationCard(citation: citation) {
                            if let urlString = citation.url,
                               let url = URL(string: urlString),
                               MedicalAuthorityMapper.isValidMedicalURL(urlString) {
                                store.send(.openCitationInSafari(url))
                            }
                        }
                    }
                }
                
                if citations.count > 5 {
                    Text("+ \(citations.count - 5) more references")
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.top, DesignSystem.Spacing.xs)
                }
                
                // AI Disclaimer for Citations
                AIDisclaimerCard()
                    .padding(.top)
            } else {
                // No citations disclaimer
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(DesignSystem.Typography.small)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                        
                        Text("Health Information Disclaimer")
                            .font(DesignSystem.Typography.small)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                    
                    Text("This analysis is AI-generated based on ingredient databases and nutritional research. Always consult healthcare professionals for medical advice.")
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.primaryRed.opacity(0.9))
                        .lineSpacing(2)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.primaryRed.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.primaryRed.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
    }
}

// MARK: - Supporting Views

struct HealthEffectCard: View {
    let effect: HealthEffect
    
    private var severityColor: Color {
        switch effect.severity.lowercased() {
        case "high": return DesignSystem.Colors.primaryRed
        case "moderate": return DesignSystem.Colors.warning
        case "low": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.textSecondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(effect.category)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text(effect.severity.capitalized)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(severityColor)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            }
            
            Text(effect.effect)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineSpacing(2)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}


struct EnhancedCitationCard: View {
    let citation: Citation
    let onTap: () -> Void
    @State private var isPressed = false
    
    private var medicalAuthorityName: String {
        if let urlString = citation.url {
            return MedicalAuthorityMapper.getAuthorityName(from: urlString)
        }
        return citation.source
    }
    
    private var isValidURL: Bool {
        MedicalAuthorityMapper.isValidMedicalURL(citation.url)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(citation.title)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(medicalAuthorityName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fontWeight(.medium)
                    
                    Text("(\(citation.year))")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if isValidURL {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                        Text("Tap to read")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                } else {
                    Image(systemName: "doc.text")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(isValidURL ? DesignSystem.Colors.primaryRed.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(
            color: DesignSystem.Shadow.medium,
            radius: DesignSystem.Shadow.radiusMedium,
            x: 0,
            y: DesignSystem.Shadow.offsetMedium.height
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isValidURL else { return }
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }
    }
}

// MARK: - Helper Functions
private func cleanAnalysisText(_ text: String) -> String {
    var cleanedText = text
    
    // Remove messy source patterns
    cleanedText = cleanedText.replacingOccurrences(
        of: #"\(Sources?:\s*,+\s*\)"#,
        with: "",
        options: .regularExpression
    )
    
    cleanedText = cleanedText.replacingOccurrences(
        of: #"\(Sources?:[^)]*\)"#,
        with: "",
        options: .regularExpression
    )
    
    cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    
    return cleanedText
}
