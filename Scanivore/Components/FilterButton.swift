//
//  FilterButton.swift
//  Scanivore
//
//  Filter button component for the Explore feature
//

import SwiftUI

struct FilterButton: View {
    let hasActiveFilters: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .font(DesignSystem.Typography.body)
                
                Text("Filters")
                    .font(DesignSystem.Typography.bodyMedium)
                
                if hasActiveFilters {
                    Circle()
                        .fill(DesignSystem.Colors.primaryRed)
                        .frame(width: 8, height: 8)
                }
            }
            .foregroundColor(DesignSystem.Colors.primaryRed)
            .padding(.horizontal, DesignSystem.Spacing.base)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.backgroundSecondary)
            )
        }
    }
}
