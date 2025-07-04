//
//  ScanResultView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct ScanResultFeatureDomain {
    @ObservableState
    struct State: Equatable {
        let scan: MeatScan
        var showingNutrition = false
        var isSaving = false
        
        init(scan: MeatScan) {
            self.scan = scan
        }
    }
    
    enum Action {
        case nutritionToggled
        case saveToHistoryTapped
        case shareResultsTapped
        case doneTapped
        case saveCompleted
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .nutritionToggled:
                state.showingNutrition.toggle()
                return .none
                
            case .saveToHistoryTapped:
                state.isSaving = true
                return .run { send in
                    try await Task.sleep(for: .seconds(1))
                    await send(.saveCompleted)
                }
                
            case .saveCompleted:
                state.isSaving = false
                return .none
                
            case .shareResultsTapped:
                // TODO: Implement share functionality
                return .none
                
            case .doneTapped:
                return .run { _ in
                    await dismiss()
                }
            }
        }
    }
}

struct ScanResultView: View {
    @Bindable var store: StoreOf<ScanResultFeatureDomain>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        ResultHeaderView(scan: store.scan)
                        
                        QualityCardView(scan: store.scan)
                        
                        if !store.scan.warnings.isEmpty {
                            WarningsCardView(warnings: store.scan.warnings)
                        }
                        
                        RecommendationsCardView(recommendations: store.scan.recommendations)
                        
                        NutritionCardView(
                            nutrition: store.scan.nutritionInfo,
                            isExpanded: store.showingNutrition,
                            onToggle: { store.send(.nutritionToggled) }
                        )
                        
                        ActionButtonsView(
                            isSaving: store.isSaving,
                            onSave: { store.send(.saveToHistoryTapped) },
                            onShare: { store.send(.shareResultsTapped) }
                        )
                            .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
            }
            .customNavigationTitle("Scan Results")
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
                            .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            store.send(.doneTapped)
                        }
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
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
                    .font(DesignSystem.Typography.hero)
            }
            
            Text(scan.meatType.rawValue)
                .font(DesignSystem.Typography.heading1)
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
                            .font(DesignSystem.Typography.hero)
                            .foregroundColor(scan.quality.color)
                        
                        Text("/ 100")
                            .font(DesignSystem.Typography.heading3)
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
                        .font(DesignSystem.Typography.heading1)
                        .foregroundColor(scan.quality.color)
                }
            }
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            HStack {
                Label("Freshness", systemImage: "leaf.fill")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text(scan.freshness.rawValue)
                    .font(DesignSystem.Typography.bodyMedium)
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
                        .font(DesignSystem.Typography.body)
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
                        .font(DesignSystem.Typography.body)
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
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Button(action: { withAnimation { onToggle() } }) {
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
                .font(DesignSystem.Typography.body)
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
    let isSaving: Bool
    let onSave: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Button(action: onSave) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Label("Save to History", systemImage: "square.and.arrow.down")
                }
                .frame(maxWidth: .infinity)
            }
            .primaryButton()
            .disabled(isSaving)
            
            Button(action: onShare) {
                Label("Share Results", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .secondaryButton()
        }
    }
}

#Preview {
    ScanResultView(
        store: Store(initialState: ScanResultFeatureDomain.State(scan: MeatScan.mockScans[0])) {
            ScanResultFeatureDomain()
        }
    )
}