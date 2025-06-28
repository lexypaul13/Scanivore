//
//  IngredientRiskView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

// MARK: - Ingredient Risk View
struct IngredientRiskView: View {
    let scan: MeatScan
    @State private var showingRiskDetails = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                RiskOverviewCard(scan: scan)
                DetectedRisksCard(scan: scan)
                SafetyRecommendationsCard(scan: scan)
                AllergenInfoCard()
            }
            .padding(DesignSystem.Spacing.screenPadding)
        }
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

struct RiskOverviewCard: View {
    let scan: MeatScan
    
    private var riskLevel: RiskLevel {
        if !scan.warnings.isEmpty {
            return .medium
        }
        return scan.quality.score > 85 ? .low : .medium
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.base) {
            HStack {
                Text("Risk Assessment")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                RiskBadge(level: riskLevel)
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                RiskIndicator(
                    label: "Bacterial Risk",
                    level: scan.warnings.contains { $0.contains("bacteria") } ? .medium : .low
                )
                
                RiskIndicator(
                    label: "Spoilage Risk",
                    level: scan.freshness == .expired ? .high : scan.freshness == .caution ? .medium : .low
                )
                
                RiskIndicator(
                    label: "Contamination Risk",
                    level: .low
                )
                
                RiskIndicator(
                    label: "Allergen Risk",
                    level: .low
                )
            }
        }
        .cardStyle()
    }
}

struct RiskBadge: View {
    let level: RiskLevel
    
    var body: some View {
        Text(level.text.uppercased())
            .font(DesignSystem.Typography.caption)
            .fontWeight(.bold)
            .foregroundColor(DesignSystem.Colors.background)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(level.color)
            .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct RiskIndicator: View {
    let label: String
    let level: RiskLevel
    
    var body: some View {
        HStack {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(level.color)
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Spacer()
            
            Text(level.text)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(level.color)
        }
    }
}

enum RiskLevel {
    case low, medium, high
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var text: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

struct DetectedRisksCard: View {
    let scan: MeatScan
    
    private var detectedRisks: [DetectedRisk] {
        var risks: [DetectedRisk] = []
        
        if scan.warnings.contains(where: { $0.contains("bacteria") }) {
            risks.append(DetectedRisk(
                type: "Bacterial Count",
                description: "Elevated bacterial presence detected",
                severity: .medium,
                recommendation: "Cook to 165°F internal temperature"
            ))
        }
        
        if scan.freshness == .caution || scan.freshness == .expired {
            risks.append(DetectedRisk(
                type: "Spoilage Indicators",
                description: "Signs of deterioration detected",
                severity: scan.freshness == .expired ? .high : .medium,
                recommendation: "Use immediately or discard"
            ))
        }
        
        if risks.isEmpty {
            risks.append(DetectedRisk(
                type: "No Significant Risks",
                description: "Product appears safe for consumption",
                severity: .low,
                recommendation: "Follow standard cooking practices"
            ))
        }
        
        return risks
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Detected Risks")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(detectedRisks, id: \.type) { risk in
                RiskItemView(risk: risk)
            }
        }
        .cardStyle()
    }
}

struct DetectedRisk {
    let type: String
    let description: String
    let severity: RiskLevel
    let recommendation: String
}

struct RiskItemView: View {
    let risk: DetectedRisk
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(risk.type)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                RiskBadge(level: risk.severity)
            }
            
            Text(risk.description)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            if risk.severity != .low {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                        .font(DesignSystem.Typography.caption)
                    
                    Text(risk.recommendation)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .stroke(risk.severity.color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

struct SafetyRecommendationsCard: View {
    let scan: MeatScan
    
    private var recommendations: [SafetyRecommendation] {
        var recs: [SafetyRecommendation] = []
        
        recs.append(SafetyRecommendation(
            icon: "thermometer",
            title: "Cooking Temperature",
            description: "Cook to minimum internal temperature of 160°F (71°C)"
        ))
        
        recs.append(SafetyRecommendation(
            icon: "clock.fill",
            title: "Storage Time",
            description: "Use within recommended timeframe for optimal safety"
        ))
        
        recs.append(SafetyRecommendation(
            icon: "hand.wash.fill",
            title: "Food Safety",
            description: "Wash hands and surfaces after handling raw meat"
        ))
        
        if scan.freshness == .caution {
            recs.append(SafetyRecommendation(
                icon: "exclamationmark.triangle.fill",
                title: "Priority Use",
                description: "Use immediately - showing signs of deterioration"
            ))
        }
        
        return recs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Safety Recommendations")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(recommendations, id: \.title) { recommendation in
                SafetyRecommendationRow(recommendation: recommendation)
            }
        }
        .cardStyle()
    }
}

struct SafetyRecommendation {
    let icon: String
    let title: String
    let description: String
}

struct SafetyRecommendationRow: View {
    let recommendation: SafetyRecommendation
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: recommendation.icon)
                .foregroundColor(DesignSystem.Colors.primaryRed)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(recommendation.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

struct AllergenInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Allergen Information")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                AllergenRow(allergen: "Contains", status: "None detected", isPresent: false)
                AllergenRow(allergen: "May contain traces of", status: "Cross-contamination possible", isPresent: true)
                AllergenRow(allergen: "Processing facility", status: "Also processes dairy, soy", isPresent: true)
            }
            
            Text("Always check packaging labels for complete allergen information")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .italic()
        }
        .cardStyle()
    }
}

struct AllergenRow: View {
    let allergen: String
    let status: String
    let isPresent: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(allergen)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(status)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: isPresent ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(isPresent ? DesignSystem.Colors.warning : DesignSystem.Colors.success)
        }
    }
}

#Preview {
    IngredientRiskView(scan: MeatScan.mockScans[1])
}