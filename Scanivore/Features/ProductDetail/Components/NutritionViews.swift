//
//  NutritionViews.swift
//  Scanivore
//
//  Nutrition display components for ProductDetail
//

import SwiftUI

// MARK: - Nutrition Scroll View
struct NutritionScrollView: View {
    let assessment: HealthAssessmentResponse
    
    // Get nutrition data from assessment
    private func getNutritionData() -> [NutritionInsight] {
        // Try both access methods for backwards compatibility
        if let direct = assessment.nutrition, !direct.isEmpty {
            return direct
        } else if let computed = assessment.nutritionInsights, !computed.isEmpty {
            return computed
        }
        
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
                    let nutritionData = getNutritionData()
                    
                    if !nutritionData.isEmpty {
                        // Map through the nutrition array dynamically
                        ForEach(Array(nutritionData.enumerated()), id: \.offset) { index, insight in
                            NutritionCard(insight: insight)
                        }
                    } else {
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