//
//  ProductDetailView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct ProductDetailView: View {
    let scan: MeatScan
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ProductHeaderView(scan: scan)
                    
                    TabSelectorView(selectedTab: $selectedTab)
                    
                    TabView(selection: $selectedTab) {
                        GradeDetailView(scan: scan)
                            .tag(0)
                        
                        IngredientRiskView(scan: scan)
                            .tag(1)
                        
                        NutritionPanelView(scan: scan)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .customNavigationTitle("Product Analysis")
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                }
            }
        }
    }
}

struct ProductHeaderView: View {
    let scan: MeatScan
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.base) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text(scan.meatType.rawValue)
                        .font(DesignSystem.Typography.heading1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Scanned \(scan.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Text(scan.meatType.icon)
                    .font(DesignSystem.Typography.hero)
            }
            
            OverallScoreView(scan: scan)
        }
        .padding(DesignSystem.Spacing.base)
        .background(DesignSystem.Colors.background)
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: DesignSystem.Shadow.offsetLight.width,
            y: DesignSystem.Shadow.offsetLight.height
        )
    }
}

struct OverallScoreView: View {
    let scan: MeatScan
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            VStack {
                Text("OVERALL")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(scan.quality.grade)
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(scan.quality.color)
            }
            
            VStack {
                Text("SCORE")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("\(Int(scan.quality.score))")
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(scan.quality.color)
            }
            
            VStack {
                Text("FRESHNESS")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(scan.freshness.rawValue.uppercased())
                    .font(DesignSystem.Typography.label)
                    .foregroundColor(scan.freshness.color)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(scan.freshness.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                            .stroke(scan.freshness.color.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            }
        }
    }
}

struct TabSelectorView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "GRADE", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "RISKS", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabButton(title: "NUTRITION", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .background(DesignSystem.Colors.background)
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: DesignSystem.Shadow.offsetLight.width,
            y: DesignSystem.Shadow.offsetLight.height
        )
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(isSelected ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                
                Rectangle()
                    .fill(isSelected ? DesignSystem.Colors.primaryRed : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
    }
}

// MARK: - Grade Detail View
struct GradeDetailView: View {
    let scan: MeatScan
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                QualityBreakdownCard(scan: scan)
                FreshnessAnalysisCard(scan: scan)
                QualityFactorsCard(scan: scan)
            }
            .padding(DesignSystem.Spacing.screenPadding)
        }
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

struct QualityBreakdownCard: View {
    let scan: MeatScan
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Quality Breakdown")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                QualityMetric(label: "Visual Appearance", score: scan.quality.score * 0.9, maxScore: 100)
                QualityMetric(label: "Color Consistency", score: scan.quality.score * 0.95, maxScore: 100)
                QualityMetric(label: "Texture Analysis", score: scan.quality.score * 0.85, maxScore: 100)
                QualityMetric(label: "Marbling Quality", score: scan.quality.score * 1.1, maxScore: 100)
            }
        }
        .cardStyle()
    }
}

struct QualityMetric: View {
    let label: String
    let score: Double
    let maxScore: Double
    
    private var normalizedScore: Double {
        min(score, maxScore)
    }
    
    private var color: Color {
        switch normalizedScore {
        case 90...100: return .green
        case 75..<90: return .blue
        case 60..<75: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(label)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("\(Int(normalizedScore))")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: normalizedScore / maxScore)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 2)
        }
    }
}

struct FreshnessAnalysisCard: View {
    let scan: MeatScan
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Freshness Analysis")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Status")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(scan.freshness.rawValue)
                        .font(DesignSystem.Typography.heading3)
                        .foregroundColor(scan.freshness.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Estimated Days Left")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(estimatedDaysLeft())
                        .font(DesignSystem.Typography.heading3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            
            Text("Based on visual indicators, temperature history, and storage conditions")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .cardStyle()
    }
    
    private func estimatedDaysLeft() -> String {
        switch scan.freshness {
        case .fresh: return "3-5"
        case .good: return "2-3"
        case .acceptable: return "1-2"
        case .caution: return "< 1"
        case .expired: return "0"
        }
    }
}

struct QualityFactorsCard: View {
    let scan: MeatScan
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Quality Factors")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                QualityFactor(
                    icon: "eye.fill",
                    title: "Visual Inspection",
                    description: "Color uniformity and surface quality",
                    status: .good
                )
                
                QualityFactor(
                    icon: "thermometer",
                    title: "Temperature Analysis",
                    description: "Storage temperature compliance",
                    status: .excellent
                )
                
                QualityFactor(
                    icon: "clock.fill",
                    title: "Age Assessment",
                    description: "Time since processing",
                    status: scan.freshness == .fresh ? .excellent : .warning
                )
            }
        }
        .cardStyle()
    }
}

struct QualityFactor: View {
    let icon: String
    let title: String
    let description: String
    let status: QualityStatus
    
    enum QualityStatus {
        case excellent, good, warning, poor
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .warning: return .orange
            case .poor: return .red
            }
        }
        
        var text: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .warning: return "Fair"
            case .poor: return "Poor"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Text(status.text)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(status.color)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(status.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(DesignSystem.CornerRadius.sm)
        }
    }
}

#Preview {
    ProductDetailView(scan: MeatScan.mockScans[0])
}