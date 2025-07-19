//
//  ScannerOverlays.swift
//  Scanivore
//
//  Scanner state overlay components
//

import SwiftUI

// MARK: - Scanner State Overlays

struct PermissionOverlay: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2.0)
                .tint(.white)
            
            Text("Requesting Camera Permission...")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xxxl)
        .background(Color.black.opacity(0.8))
        .cornerRadius(DesignSystem.CornerRadius.xxl)
        .shadow(color: .black.opacity(0.5), radius: 8)
    }
}

struct PreparingOverlay: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2.0)
                .tint(.white)
            
            Text("Starting Camera...")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(.white)
        }
        .padding(DesignSystem.Spacing.xxxl)
        .background(Color.black.opacity(0.8))
        .cornerRadius(DesignSystem.CornerRadius.xxl)
        .shadow(color: .black.opacity(0.5), radius: 8)
    }
}

struct ScanningActiveOverlay: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "viewfinder")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.primaryRed)
            
            Text("Scanning for Barcode...")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Point camera at product barcode")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xxxl)
        .background(DesignSystem.Colors.background.opacity(0.95))
        .cornerRadius(DesignSystem.CornerRadius.xxl)
        .shadow(color: DesignSystem.Shadow.medium, radius: DesignSystem.Shadow.radiusMedium)
    }
}

struct ProcessingOverlay: View {
    let barcode: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2.5)
                .tint(DesignSystem.Colors.primaryRed)
            
            Text("Analyzing Product...")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Barcode: \(barcode)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.horizontal)
        }
        .padding(DesignSystem.Spacing.xxxl)
        .background(DesignSystem.Colors.background.opacity(0.95))
        .cornerRadius(DesignSystem.CornerRadius.xxl)
        .shadow(color: DesignSystem.Shadow.medium, radius: DesignSystem.Shadow.radiusMedium)
    }
}

struct ErrorOverlay: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.warning)
            
            Text("Scanning Error")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                onDismiss()
            }
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.background)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primaryRed)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .padding(DesignSystem.Spacing.xxxl)
        .background(DesignSystem.Colors.background.opacity(0.95))
        .cornerRadius(DesignSystem.CornerRadius.xxl)
        .shadow(color: DesignSystem.Shadow.medium, radius: DesignSystem.Shadow.radiusMedium)
    }
}

struct ProductNotFoundOverlay: View {
    let barcode: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.primaryRed)
            
            Text("Product Not Found")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("We couldn't find this product in our database. Try scanning again or check if the barcode is clear.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Barcode: \(barcode)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.horizontal)
            
            Button("Try Again") {
                onDismiss()
            }
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.background)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primaryRed)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .padding(DesignSystem.Spacing.xxxl)
        .background(DesignSystem.Colors.background.opacity(0.95))
        .cornerRadius(DesignSystem.CornerRadius.xxl)
        .shadow(color: DesignSystem.Shadow.medium, radius: DesignSystem.Shadow.radiusMedium)
    }
}