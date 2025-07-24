//
//  ProductRecommendationCard.swift
//  Scanivore
//
//  Product recommendation card component for the Explore feature
//

import SwiftUI

struct ProductRecommendationCard: View {
    let recommendation: ProductRecommendation
    let onTap: (() -> Void)?
    
    init(recommendation: ProductRecommendation, onTap: (() -> Void)? = nil) {
        self.recommendation = recommendation
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.base) {
            // Product Image
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .frame(width: 120, height: 120)
                
                if let imageUrl = recommendation.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipped()
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        case .failure(_):
                            // Show placeholder when image fails to load
                            PlaceholderImage()
                        case .empty:
                            HStack {
                                ProgressView()
                                    .tint(DesignSystem.Colors.textSecondary)
                            }
                            .frame(width: 120, height: 120)
                        @unknown default:
                            PlaceholderImage()
                        }
                    }
                } else {
                    PlaceholderImage()
                }
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Name and Brand
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.name)
                        .font(DesignSystem.Typography.buttonText)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(recommendation.brand)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                // Meat type and quality badges
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // Meat Type Badge
                    HStack(spacing: 4) {
                        Text(recommendation.meatType.icon)
                            .font(.system(size: 14))
                        Text(recommendation.meatType.rawValue)
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                    
                    // Quality Badge
                    QualityBadge(level: recommendation.qualityRating)
                }
                
                Spacer()
                
                // Match reasons or concerns
                if recommendation.isRecommended {
                    if !recommendation.matchReasons.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(DesignSystem.Colors.success)
                            
                            Text(recommendation.matchReasons.first ?? "")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                } else {
                    if !recommendation.concerns.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(DesignSystem.Colors.warning)
                            
                            Text(recommendation.concerns.first ?? "")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.base)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.background)
                .shadow(
                    color: DesignSystem.Colors.textPrimary.opacity(0.06),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Quality Badge Component
struct QualityBadge: View {
    let level: QualityLevel
    
    var badgeColor: Color {
        switch level {
        case .excellent:
            return DesignSystem.Colors.success  // A = Green
        case .good:
            return DesignSystem.Colors.warning  // C = Yellow (matches ProductDetail)
        case .poor:
            return Color.orange  // D = Orange
        case .bad:
            return DesignSystem.Colors.error  // F = Red
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)
            
            Text(level.displayName)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.full)
    }
}

// MARK: - Placeholder Image Component
struct PlaceholderImage: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundSecondary)
                .frame(width: 120, height: 120)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "photo")
                    .font(.system(size: 30))
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.6))
                
                Text("No Image")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary.opacity(0.8))
            }
        }
        .frame(width: 120, height: 120)
    }
}

