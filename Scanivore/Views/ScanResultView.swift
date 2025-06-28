//
//  ScanResultView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct ScanResultView: View {
    let scan: MeatScan
    @Environment(\.dismiss) private var dismiss
    @State private var showingNutrition = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        ResultHeaderView(scan: scan)
                        
                        QualityCardView(scan: scan)
                        
                        if !scan.warnings.isEmpty {
                            WarningsCardView(warnings: scan.warnings)
                        }
                        
                        RecommendationsCardView(recommendations: scan.recommendations)
                        
                        NutritionCardView(nutrition: scan.nutritionInfo, isExpanded: $showingNutrition)
                        
                        ActionButtonsView(scan: scan)
                            .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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

struct ResultHeaderView: View {
    let scan: MeatScan
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(scan.quality.color.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(scan.quality.color.opacity(0.3), lineWidth: 2)
                    )
                
                Text(scan.meatType.icon)
                    .font(.system(size: 60))
            }
            
            Text(scan.meatType.rawValue)
                .font(DesignSystem.Typography.heading1)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Scanned \(scan.date.formatted(date: .abbreviated, time: .shortened))")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.top, DesignSystem.Spacing.lg)
        .padding(.horizontal, DesignSystem.Spacing.base)
    }
}

struct QualityCardView: View {
    let scan: MeatScan
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.base) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Quality Score")
                        .font(DesignSystem.Typography.heading2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack(alignment: .bottom, spacing: DesignSystem.Spacing.xs) {
                        Text("\(Int(scan.quality.score))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(scan.quality.color)
                        
                        Text("/ 100")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.bottom, DesignSystem.Spacing.sm)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("Grade")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(scan.quality.grade)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(scan.quality.color)
                }
            }
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            HStack {
                Label("Freshness", systemImage: "leaf.fill")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text(scan.freshness.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(scan.freshness.color)
            }
        }
        .cardStyle()
    }
}

struct WarningsCardView: View {
    let warnings: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.warning)
            
            ForEach(warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                        .font(DesignSystem.Typography.caption)
                    
                    Text(warning)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(DesignSystem.Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: DesignSystem.Shadow.offsetLight.width,
            y: DesignSystem.Shadow.offsetLight.height
        )
    }
}

struct RecommendationsCardView: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Label("Recommendations", systemImage: "lightbulb.fill")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.primaryRed)
            
            ForEach(recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.success)
                        .font(DesignSystem.Typography.caption)
                    
                    Text(recommendation)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(DesignSystem.Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.primaryRed.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: DesignSystem.Shadow.offsetLight.width,
            y: DesignSystem.Shadow.offsetLight.height
        )
    }
}

struct NutritionCardView: View {
    let nutrition: NutritionInfo
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Label("Nutrition Facts", systemImage: "chart.bar.fill")
                        .font(DesignSystem.Typography.heading2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut, value: isExpanded)
                }
            }
            
            if isExpanded {
                Divider()
                    .background(DesignSystem.Colors.border)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    SimpleNutritionRow(label: "Calories", value: "\(nutrition.calories)")
                    SimpleNutritionRow(label: "Protein", value: "\(String(format: "%.1f", nutrition.protein))g")
                    SimpleNutritionRow(label: "Total Fat", value: "\(String(format: "%.1f", nutrition.fat))g")
                    SimpleNutritionRow(label: "Saturated Fat", value: "\(String(format: "%.1f", nutrition.saturatedFat))g")
                    SimpleNutritionRow(label: "Cholesterol", value: "\(nutrition.cholesterol)mg")
                    SimpleNutritionRow(label: "Sodium", value: "\(nutrition.sodium)mg")
                }
                .font(.subheadline)
            }
        }
        .cardStyle()
    }
}

struct SimpleNutritionRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

struct ActionButtonsView: View {
    let scan: MeatScan
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Button(action: {}) {
                Label("Save to History", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .primaryButton()
            
            Button(action: {}) {
                Label("Share Results", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .secondaryButton()
        }
    }
}

#Preview {
    ScanResultView(scan: MeatScan.mockScans[0])
}