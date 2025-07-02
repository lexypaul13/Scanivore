//
//  MeatSelectionView.swift
//  Scanivore
//
//  TCA view for selecting preferred meat types
//

import SwiftUI
import ComposableArchitecture

struct MeatSelectionView: View {
    let store: StoreOf<MeatSelectionFeature>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: DesignSystem.Spacing.xl)
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Question
                    Text("Primary meat types?")
                        .font(DesignSystem.Typography.heading1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    // Subtitle
                    Text("Select the types of meat you purchase most often")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xxxl)
                }
                
                Spacer()
                    .frame(height: DesignSystem.Spacing.xxxl)
                
                // Meat Type Selection
                VStack(spacing: DesignSystem.Spacing.base) {
                    ForEach(MeatSelectionFeature.availableMeatTypes, id: \.type) { meatInfo in
                        MeatTypeRow(
                            type: meatInfo.type,
                            name: meatInfo.name,
                            isSelected: store.selectedTypes.contains(meatInfo.type),
                            onTap: {
                                store.send(.meatTypeToggled(meatInfo.type))
                            }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                
                Spacer()
                
                // Continue Button
                Button(action: { store.send(.continueButtonTapped) }) {
                    Text("Continue")
                        .font(DesignSystem.Typography.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Components.Button.primaryHeight)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Components.Button.primaryCornerRadius)
                                .fill(store.canContinue ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.textSecondary)
                        )
                }
                .disabled(!store.canContinue)
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                .padding(.bottom, DesignSystem.Spacing.xxxxxl)
            }
        }
    }
}

struct MeatTypeRow: View {
    let type: MeatType
    let name: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.base) {
                // Icon
                Text(type.icon)
                    .font(DesignSystem.Typography.heading2)
                    .frame(width: 40)
                
                // Name
                Text(name)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(isSelected ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.border)
            }
            .padding(DesignSystem.Spacing.base)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isSelected ? DesignSystem.Colors.primaryRed.opacity(0.1) : DesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(isSelected ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MeatSelectionView(
        store: Store(
            initialState: MeatSelectionFeature.State(
                selectedTypes: [.chicken, .beef]
            )
        ) {
            MeatSelectionFeature()
        }
    )
} 