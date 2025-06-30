//
//  NutritionPanelView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

// MARK: - Nutrition Panel View
struct NutritionPanelView: View {
    let scan: MeatScan
    @State private var servingSize: ServingSize = .standard
    @State private var showingComparison = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                NutritionFactsCard(scan: scan, servingSize: servingSize)
                ServingSizeSelector(selectedSize: $servingSize)
                MacronutrientBreakdownCard(scan: scan, servingSize: servingSize)
                VitaminsMineralsCard(scan: scan, servingSize: servingSize)
                HealthInsightsCard(scan: scan)
            }
            .padding(DesignSystem.Spacing.screenPadding)
        }
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

enum ServingSize: String, CaseIterable {
    case small = "Small (85g)"
    case standard = "Standard (113g)" 
    case large = "Large (170g)"
    
    var multiplier: Double {
        switch self {
        case .small: return 0.75
        case .standard: return 1.0
        case .large: return 1.5
        }
    }
    
    var grams: Int {
        switch self {
        case .small: return 85
        case .standard: return 113
        case .large: return 170
        }
    }
}

struct NutritionFactsCard: View {
    let scan: MeatScan
    let servingSize: ServingSize
    
    private var adjustedNutrition: NutritionInfo {
        let multiplier = servingSize.multiplier
        return NutritionInfo(
            calories: Int(Double(scan.nutritionInfo.calories) * multiplier),
            protein: scan.nutritionInfo.protein * multiplier,
            fat: scan.nutritionInfo.fat * multiplier,
            saturatedFat: scan.nutritionInfo.saturatedFat * multiplier,
            cholesterol: Int(Double(scan.nutritionInfo.cholesterol) * multiplier),
            sodium: Int(Double(scan.nutritionInfo.sodium) * multiplier)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Nutrition Facts")
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Per serving (\(servingSize.grams)g)")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Divider()
                .background(DesignSystem.Colors.textPrimary)
                .frame(height: 2)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("Calories")
                        .font(DesignSystem.Typography.heading3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(adjustedNutrition.calories)")
                        .font(DesignSystem.Typography.heading1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                Text("% Daily Value*")
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                NutritionRow(
                    label: "Total Fat",
                    value: "\(String(format: "%.1f", adjustedNutrition.fat))g",
                    dailyValue: calculateDailyValue(adjustedNutrition.fat, recommended: 65),
                    isMainNutrient: true
                )
                
                NutritionRow(
                    label: "Saturated Fat",
                    value: "\(String(format: "%.1f", adjustedNutrition.saturatedFat))g",
                    dailyValue: calculateDailyValue(adjustedNutrition.saturatedFat, recommended: 20),
                    isMainNutrient: false
                )
                
                NutritionRow(
                    label: "Cholesterol",
                    value: "\(adjustedNutrition.cholesterol)mg",
                    dailyValue: calculateDailyValue(Double(adjustedNutrition.cholesterol), recommended: 300),
                    isMainNutrient: true
                )
                
                NutritionRow(
                    label: "Sodium",
                    value: "\(adjustedNutrition.sodium)mg",
                    dailyValue: calculateDailyValue(Double(adjustedNutrition.sodium), recommended: 2300),
                    isMainNutrient: true
                )
                
                NutritionRow(
                    label: "Protein",
                    value: "\(String(format: "%.1f", adjustedNutrition.protein))g",
                    dailyValue: nil,
                    isMainNutrient: true
                )
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                Text("*The % Daily Value tells you how much a nutrient in a serving of food contributes to a daily diet. 2,000 calories a day is used for general nutrition advice.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.base)
        .background(DesignSystem.Colors.background)
        .overlay(
            Rectangle()
                .stroke(DesignSystem.Colors.textPrimary, lineWidth: 2)
        )
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private func calculateDailyValue(_ amount: Double, recommended: Double) -> Int? {
        return Int((amount / recommended) * 100)
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    let dailyValue: Int?
    let isMainNutrient: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                if !isMainNutrient {
                    Text("    ")
                }
                Text(label)
                    .font(isMainNutrient ? DesignSystem.Typography.bodyMedium : DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let dailyValue = dailyValue {
                Text("\(dailyValue)%")
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        
        if isMainNutrient {
            Divider()
                .background(DesignSystem.Colors.border)
        }
    }
}

struct ServingSizeSelector: View {
    @Binding var selectedSize: ServingSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Serving Size")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                ForEach(ServingSize.allCases, id: \.self) { size in
                    Button(action: { selectedSize = size }) {
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Text(size.rawValue.components(separatedBy: " ").first ?? "")
                                .font(DesignSystem.Typography.captionMedium)
                            
                            Text(size.rawValue.components(separatedBy: " ").last ?? "")
                                .font(DesignSystem.Typography.small)
                        }
                        .foregroundColor(selectedSize == size ? DesignSystem.Colors.background : DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(selectedSize == size ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.backgroundSecondary)
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .stroke(selectedSize == size ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.border, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct MacronutrientBreakdownCard: View {
    let scan: MeatScan
    let servingSize: ServingSize
    
    private var adjustedNutrition: NutritionInfo {
        let multiplier = servingSize.multiplier
        return NutritionInfo(
            calories: Int(Double(scan.nutritionInfo.calories) * multiplier),
            protein: scan.nutritionInfo.protein * multiplier,
            fat: scan.nutritionInfo.fat * multiplier,
            saturatedFat: scan.nutritionInfo.saturatedFat * multiplier,
            cholesterol: Int(Double(scan.nutritionInfo.cholesterol) * multiplier),
            sodium: Int(Double(scan.nutritionInfo.sodium) * multiplier)
        )
    }
    
    private var macroBreakdown: (protein: Double, fat: Double, carbs: Double) {
        let proteinCals = adjustedNutrition.protein * 4
        let fatCals = adjustedNutrition.fat * 9
        let carbsCals = 0.0 // Meat typically has minimal carbs
        let total = proteinCals + fatCals + carbsCals
        
        return (
            protein: total > 0 ? (proteinCals / total) * 100 : 0,
            fat: total > 0 ? (fatCals / total) * 100 : 0,
            carbs: total > 0 ? (carbsCals / total) * 100 : 0
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Macronutrient Breakdown")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                MacroBar(
                    label: "Protein",
                    grams: adjustedNutrition.protein,
                    percentage: macroBreakdown.protein,
                    color: DesignSystem.Colors.primaryRed
                )
                
                MacroBar(
                    label: "Fat",
                    grams: adjustedNutrition.fat,
                    percentage: macroBreakdown.fat,
                    color: DesignSystem.Colors.warning
                )
                
                MacroBar(
                    label: "Carbohydrates",
                    grams: 0,
                    percentage: macroBreakdown.carbs,
                    color: DesignSystem.Colors.success
                )
            }
            
            Text("Calories from protein: \(Int(adjustedNutrition.protein * 4)) • Fat: \(Int(adjustedNutrition.fat * 9))")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .cardStyle()
    }
}

struct MacroBar: View {
    let label: String
    let grams: Double
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(label)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(String(format: "%.1f", grams))g")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("(\(Int(percentage))%)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignSystem.Colors.backgroundSecondary)
                        .frame(height: 8)
                        .cornerRadius(DesignSystem.CornerRadius.xs)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * (percentage / 100), height: 8)
                        .cornerRadius(DesignSystem.CornerRadius.xs)
                }
            }
            .frame(height: 8)
        }
    }
}

struct VitaminsMineralsCard: View {
    let scan: MeatScan
    let servingSize: ServingSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Vitamins & Minerals")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Estimated values based on meat type")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.md) {
                VitaminMineralItem(name: "Iron", amount: "2.5mg", dailyValue: "14%")
                VitaminMineralItem(name: "Zinc", amount: "5.2mg", dailyValue: "47%")
                VitaminMineralItem(name: "Vitamin B12", amount: "2.4μg", dailyValue: "100%")
                VitaminMineralItem(name: "Niacin", amount: "7.3mg", dailyValue: "46%")
                VitaminMineralItem(name: "Phosphorus", amount: "220mg", dailyValue: "18%")
                VitaminMineralItem(name: "Selenium", amount: "24μg", dailyValue: "44%")
            }
        }
        .cardStyle()
    }
}

struct VitaminMineralItem: View {
    let name: String
    let amount: String
    let dailyValue: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(name)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(amount)
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text(dailyValue)
                .font(DesignSystem.Typography.small)
                .foregroundColor(DesignSystem.Colors.primaryRed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.xs)
    }
}

struct HealthInsightsCard: View {
    let scan: MeatScan
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Health Insights")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                HealthInsight(
                    icon: "heart.fill",
                    title: "Heart Health",
                    description: "High in protein, moderate saturated fat",
                    rating: .good
                )
                
                HealthInsight(
                    icon: "figure.strengthtraining.traditional",
                    title: "Muscle Building",
                    description: "Excellent protein source for muscle maintenance",
                    rating: .excellent
                )
                
                HealthInsight(
                    icon: "brain.head.profile",
                    title: "Brain Function",
                    description: "Rich in B vitamins and iron",
                    rating: .good
                )
            }
            
            Text("Consult with healthcare providers for personalized dietary advice")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .italic()
        }
        .cardStyle()
    }
}

struct HealthInsight: View {
    let icon: String
    let title: String
    let description: String
    let rating: HealthRating
    
    enum HealthRating {
        case excellent, good, fair, poor
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }
        
        var text: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(rating.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Text(rating.text)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(rating.color)
        }
    }
}

#Preview {
    NutritionPanelView(scan: MeatScan.mockScans[0])
}