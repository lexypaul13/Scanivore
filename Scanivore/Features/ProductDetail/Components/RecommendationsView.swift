//
//  RecommendationsView.swift
//  Scanivore
//
//  Recommended swaps carousel and related components
//

import SwiftUI

// MARK: - Recommended Swaps Carousel
struct RecommendedSwapsCarousel: View {
    let swaps: [ProductRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Recommended Swaps")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(swaps) { swap in
                        SwapProductCard(recommendation: swap)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            }
        }
    }
}

// MARK: - Swap Product Card
struct SwapProductCard: View {
    let recommendation: ProductRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Product Image
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .frame(width: 120, height: 80)
                
                if let imageUrl = recommendation.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 80)
                                .clipped()
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        case .failure(_), .empty:
                            PlaceholderImageView()
                                .frame(width: 120, height: 80)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    PlaceholderImageView()
                        .frame(width: 120, height: 80)
                }
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.name)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(recommendation.brand)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
                
                QualityBadge(level: recommendation.qualityRating)
                    .scaleEffect(0.8, anchor: .leading)
            }
        }
        .frame(width: 120)
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: 0,
            y: DesignSystem.Shadow.offsetLight.height
        )
    }
}

// MARK: - Placeholder Image View
struct PlaceholderImageView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
            .fill(DesignSystem.Colors.backgroundSecondary)
            .overlay(
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("No Image")
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            )
    }
}