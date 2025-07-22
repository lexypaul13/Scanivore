//
//  ProductDetailHero.swift
//  Scanivore
//
//  Hero section and related components for ProductDetail
//

import SwiftUI
import ComposableArchitecture

// MARK: - Hero Section
struct HeroSection: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    let assessment: HealthAssessmentResponse
    
    var body: some View {
        ZStack {
            // Product Image
            AsyncImage(url: URL(string: store.productImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                case .failure(_), .empty:
                    Rectangle()
                        .fill(DesignSystem.Colors.backgroundSecondary)
                        .frame(height: 250)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Text("No Image")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            // Gradient Overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Safety Grade Badge
            VStack {
                HStack {
                    Spacer()
                    SafetyGradeBadge(
                        grade: store.safetyGrade,
                        color: store.safetyColor
                    )
                    .padding(.trailing, DesignSystem.Spacing.base)
                }
                .padding(.top, DesignSystem.Spacing.base)
                Spacer()
            }
        }
        .frame(height: 250)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
    }
}

// MARK: - Safety Grade Badge
struct SafetyGradeBadge: View {
    let grade: String
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 60, height: 60)
            
            Text(grade)
                .font(DesignSystem.Typography.heading2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .shadow(
            color: .black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Headline Section
struct HeadlineSection: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(store.productName ?? "Product name not available")
                .font(DesignSystem.Typography.heading1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Text(store.productBrand ?? "Brand information unavailable")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .padding(.top, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

// MARK: - AI Health Summary
struct AIHealthSummary: View {
    let assessment: HealthAssessmentResponse
    
    private var cleanedSummary: String {
        var cleaned = assessment.summary
        
        // Remove citation markers like [1], [2], etc.
        let citationPattern = "\\[\\d+\\]"
        if let citationRegex = try? NSRegularExpression(pattern: citationPattern, options: []) {
            let range = NSRange(location: 0, length: cleaned.count)
            cleaned = citationRegex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }
        
        // Remove markdown bold formatting like **text**
        let boldPattern = "\\*\\*([^*]+)\\*\\*"
        if let boldRegex = try? NSRegularExpression(pattern: boldPattern, options: []) {
            let range = NSRange(location: 0, length: cleaned.count)
            cleaned = boldRegex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "$1")
        }
        
        // Clean up any double spaces left by removing citations
        cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .font(.system(size: 20, weight: .medium))
                Text("AI Health Summary")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Text(cleanedSummary)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(6)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.primaryRed, lineWidth: 1)
        )
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: 0,
            y: DesignSystem.Shadow.offsetLight.height
        )
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

// MARK: - Fallback Hero Section
struct FallbackHeroSection: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    
    var body: some View {
        ZStack {
            // Product Image
            AsyncImage(url: URL(string: store.productImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                        .overlay(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            DesignSystem.Colors.background.opacity(0.1),
                                            DesignSystem.Colors.background.opacity(0.7)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                case .failure(_), .empty:
                    Rectangle()
                        .fill(DesignSystem.Colors.backgroundSecondary)
                        .frame(height: 250)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Text("No Image")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            // Grade Badge - Always show using originalRiskRating
            VStack {
                HStack {
                    Spacer()
                    
                    // Safety Grade Badge
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text(store.safetyGrade)
                            .font(DesignSystem.Typography.heading1)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Safety Grade")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(store.safetyColor)
                            .shadow(
                                color: DesignSystem.Shadow.medium,
                                radius: DesignSystem.Shadow.radiusMedium,
                                x: 0,
                                y: DesignSystem.Shadow.offsetMedium.height
                            )
                    )
                }
                .padding(.top, DesignSystem.Spacing.lg)
                .padding(.trailing, DesignSystem.Spacing.screenPadding)
                
                Spacer()
            }
        }
    }
}