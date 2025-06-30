//
//  MeatSelectionView.swift
//  Scanivore
//
//  View for selecting preferred meat types
//

import SwiftUI

struct MeatSelectionView: View {
    @Binding var selectedTypes: Set<MeatType>
    let onContinue: () -> Void
    
    let availableMeatTypes: [(type: MeatType, name: String)] = [
        (.chicken, "Chicken"),
        (.turkey, "Turkey"),
        (.beef, "Beef"),
        (.lamb, "Lamb")
    ]
    
    var body: some View {
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
                ForEach(availableMeatTypes, id: \.type) { meatInfo in
                    MeatTypeRow(
                        type: meatInfo.type,
                        name: meatInfo.name,
                        isSelected: selectedTypes.contains(meatInfo.type),
                        onTap: {
                            toggleSelection(meatInfo.type)
                        }
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            
            Spacer()
            
            // Continue Button
            Button(action: onContinue) {
                Text("Continue")
                    .font(DesignSystem.Typography.buttonText)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Components.Button.primaryHeight)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Components.Button.primaryCornerRadius)
                            .fill(selectedTypes.isEmpty ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.primaryRed)
                    )
            }
            .disabled(selectedTypes.isEmpty)
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            .padding(.bottom, DesignSystem.Spacing.xxxxxl)
        }
    }
    
    private func toggleSelection(_ type: MeatType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
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
        selectedTypes: .constant([.chicken, .beef]),
        onContinue: {}
    )
}