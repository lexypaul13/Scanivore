//
//  IngredientSections.swift
//  Scanivore
//
//  Ingredient analysis components for ProductDetail
//

import SwiftUI
import ComposableArchitecture
import SafariServices

// MARK: - Collapsible Ingredient Sections
struct CollapsibleIngredientSections: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    let assessment: HealthAssessmentResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Ingredients Analysis")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            
            VStack(spacing: DesignSystem.Spacing.base) {
                // High Risk Ingredients - using direct API fields
                if let highRisk = assessment.high_risk, !highRisk.isEmpty {
                    CollapsibleIngredientSection(
                        sectionId: "high-risk",
                        title: "High Risk",
                        ingredients: highRisk,
                        color: DesignSystem.Colors.primaryRed,
                        isExpanded: store.expandedSections.contains("high-risk"),
                        onToggle: { store.send(.toggleIngredientSection("high-risk")) },
                        onIngredientTap: { ingredient in
                            store.send(.ingredientTappedWithCitations(ingredient, assessment.citations ?? []))
                        }
                    )
                }
                
                // Moderate Risk Ingredients - using direct API fields
                if let moderateRisk = assessment.moderate_risk, !moderateRisk.isEmpty {
                    CollapsibleIngredientSection(
                        sectionId: "moderate-risk",
                        title: "Moderate Risk",
                        ingredients: moderateRisk,
                        color: DesignSystem.Colors.warning,
                        isExpanded: store.expandedSections.contains("moderate-risk"),
                        onToggle: { store.send(.toggleIngredientSection("moderate-risk")) },
                        onIngredientTap: { ingredient in
                            store.send(.ingredientTappedWithCitations(ingredient, assessment.citations ?? []))
                        }
                    )
                }
                
                // Low Risk Ingredients - using direct API fields
                if let lowRisk = assessment.low_risk, !lowRisk.isEmpty {
                    CollapsibleIngredientSection(
                        sectionId: "low-risk",
                        title: "Low Risk",
                        ingredients: lowRisk,
                        color: DesignSystem.Colors.success,
                        isExpanded: store.expandedSections.contains("low-risk"),
                        onToggle: { store.send(.toggleIngredientSection("low-risk")) },
                        onIngredientTap: { ingredient in
                            store.send(.ingredientTappedWithCitations(ingredient, assessment.citations ?? []))
                        }
                    )
                }
                
                // Show message if no risk ingredients found
                if (assessment.high_risk?.isEmpty ?? true) &&
                   (assessment.moderate_risk?.isEmpty ?? true) &&
                   (assessment.low_risk?.isEmpty ?? true) {
                    Text("Ingredient analysis not available for this product")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        }
    }
}

// MARK: - Collapsible Ingredient Section
struct CollapsibleIngredientSection: View {
    let sectionId: String
    let title: String
    let ingredients: [IngredientRisk]
    let color: Color
    let isExpanded: Bool
    let onToggle: () -> Void
    let onIngredientTap: (IngredientRisk) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            // Section Header
            Button(action: onToggle) {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    Text("\(title) (\(ingredients.count))")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.vertical, DesignSystem.Spacing.base)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Ingredients List (Expandable)
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: DesignSystem.Spacing.sm)
                ], spacing: DesignSystem.Spacing.sm) {
                    ForEach(ingredients, id: \.name) { ingredient in
                        CollapsibleIngredientPill(
                            ingredient: ingredient,
                            color: color,
                            onTap: { onIngredientTap(ingredient) }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.md)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
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

// MARK: - Collapsible Ingredient Pill
struct CollapsibleIngredientPill: View {
    let ingredient: IngredientRisk
    let color: Color
    let onTap: () -> Void
    
    // Generate consistent darker color variations based on ingredient name
    var ingredientColor: Color {
        let baseColor = color // Category color (red/yellow/green)
        let hash = abs(ingredient.name.hashValue)
        
        // Generate hue shift (-15 to +15 degrees for subtle variation)
        let hueShift = Double((hash % 30) - 15) / 360.0
        
        // Higher saturation for more vibrant colors (0.7 to 0.9)
        let saturationMultiplier = 0.7 + (Double(hash % 20) / 100.0)
        
        // Darker brightness for better contrast (0.6 to 0.8)
        let brightnessMultiplier = 0.6 + (Double(hash % 20) / 100.0)
        
        // Apply color modifications
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var opacity: CGFloat = 0
        
        UIColor(baseColor).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &opacity)
        
        // Apply variations
        hue += CGFloat(hueShift)
        saturation *= CGFloat(saturationMultiplier)
        brightness *= CGFloat(brightnessMultiplier)
        
        // Ensure values are in valid ranges
        hue = max(0, min(1, hue))
        saturation = max(0, min(1, saturation))
        brightness = max(0, min(1, brightness))
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: opacity))
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(ingredient.name)
                .font(DesignSystem.Typography.small)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            ingredientColor,
                            ingredientColor.opacity(0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(DesignSystem.CornerRadius.md)
                .shadow(color: ingredientColor.opacity(0.3), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Ingredient Detail Sheet
struct EnhancedIngredientDetailSheet: View {
    let ingredient: IngredientRisk
    let citations: [Citation]
    @Environment(\.dismiss) private var dismiss
    
    private var riskColor: Color {
        switch ingredient.riskLevel?.lowercased() {
        case "high": return DesignSystem.Colors.primaryRed
        case "moderate": return DesignSystem.Colors.warning
        case "low": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.textSecondary
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Header Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text(ingredient.name)
                            .font(DesignSystem.Typography.heading1)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if let riskLevel = ingredient.riskLevel {
                            HStack {
                                Circle()
                                    .fill(riskColor)
                                    .frame(width: 8, height: 8)
                                
                                Text("\(riskLevel.capitalized) Risk")
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(riskColor)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.base)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(riskColor.opacity(0.1))
                            .cornerRadius(DesignSystem.CornerRadius.full)
                        }
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Analysis")
                            .font(DesignSystem.Typography.heading3)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(ingredient.overview ?? ingredient.microReport)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineSpacing(4)
                    }
                    
                    // Citations Section with graceful degradation
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        if !citations.isEmpty {
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(citations.prefix(3), id: \.id) { citation in
                                    CitationCard(citation: citation)
                                }
                            }
                            
                            if citations.count > 3 {
                                Text("+ \(citations.count - 3) more references")
                                    .font(DesignSystem.Typography.small)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.top, DesignSystem.Spacing.xs)
                            }
                        } else {
                            // Disclaimer when citations are not available
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(DesignSystem.Typography.small)
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                    
                                    Text("Health Information Disclaimer")
                                        .font(DesignSystem.Typography.small)
                                        .fontWeight(.semibold)
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                }
                                
                                Text("This analysis is AI-generated based on ingredient databases and nutritional research. Always consult healthcare professionals for medical advice.")
                                    .font(DesignSystem.Typography.small)
                                    .foregroundColor(DesignSystem.Colors.primaryRed.opacity(0.9))
                                    .lineSpacing(2)
                            }
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.primaryRed.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .stroke(DesignSystem.Colors.primaryRed.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.base)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Ingredient Details")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Citation Card with Enhanced Web Browsing
struct CitationCard: View {
    let citation: Citation
    @State private var showingSafari = false
    
    var citationURL: URL? {
        guard let urlString = citation.url, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(citation.title)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text(citation.source)
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("(\(citation.year))")
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                // Show appropriate icon and tap instruction based on URL availability
                if citationURL != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(DesignSystem.Typography.small)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                        Text("Tap to read")
                            .font(DesignSystem.Typography.small)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                } else {
                    Image(systemName: "doc.text")
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(citationURL != nil ? DesignSystem.Colors.backgroundSecondary : DesignSystem.Colors.backgroundSecondary.opacity(0.5))
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(citationURL != nil ? DesignSystem.Colors.primaryRed.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard let url = citationURL else { return }
            showingSafari = true
        }
        .safariView(isPresented: $showingSafari, url: citationURL)
    }
}

// MARK: - Legacy Ingredient Detail Sheet (for backward compatibility)
struct IngredientDetailSheet: View {
    let ingredient: IngredientRisk
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        EnhancedIngredientDetailSheet(ingredient: ingredient, citations: [])
    }
}