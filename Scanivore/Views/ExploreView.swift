//
//  ExploreView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedMeatTypes: Set<MeatType> = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                        .padding(.top, DesignSystem.Spacing.sm)
                        .padding(.bottom, DesignSystem.Spacing.base)
                    
                    // Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                            // Recommendations Header
                            Text("Recommendations")
                                .font(DesignSystem.Typography.heading1)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                            
                            // Product Grid
                            VStack(spacing: DesignSystem.Spacing.lg) {
                                ForEach(filteredRecommendations) { recommendation in
                                    ProductRecommendationCard(recommendation: recommendation)
                                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                                }
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.base)
                    }
                }
            }
            .customNavigationTitle("Explore")
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilters = true }) {
                        Text("Filter")
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                            .font(DesignSystem.Typography.body)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                MeatTypeFilterView(selectedMeatTypes: $selectedMeatTypes)
            }
        }
    }
    
    private var filteredRecommendations: [ProductRecommendation] {
        var recommendations = ProductRecommendation.mockRecommendations
        
        // Filter by search text
        if !searchText.isEmpty {
            recommendations = recommendations.filter { recommendation in
                recommendation.name.localizedCaseInsensitiveContains(searchText) ||
                recommendation.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by selected meat types
        if !selectedMeatTypes.isEmpty {
            recommendations = recommendations.filter { recommendation in
                selectedMeatTypes.contains(recommendation.meatType)
            }
        }
        
        return recommendations
    }
}

// MARK: - Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            TextField("Search products...", text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .autocapitalization(.none)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.inputPadding)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Components.Input.cornerRadius)
    }
}

// MARK: - Product Recommendation Card
struct ProductRecommendationCard: View {
    let recommendation: ProductRecommendation
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.base) {
            // Product Image
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundSecondary)
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                )
            
            // Product Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text(recommendation.name)
                    .font(DesignSystem.Typography.bodySemibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(recommendation.brand)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                QualityBadge(level: recommendation.qualityRating)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.base)
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

// MARK: - Quality Badge Component
struct QualityBadge: View {
    let level: QualityLevel
    
    var badgeColor: Color {
        switch level {
        case .excellent:
            return DesignSystem.Colors.success
        case .good:
            return Color.blue
        case .poor:
            return Color.orange
        case .bad:
            return DesignSystem.Colors.error
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

// MARK: - Meat Type Filter View
struct MeatTypeFilterView: View {
    @Binding var selectedMeatTypes: Set<MeatType>
    @Environment(\.dismiss) private var dismiss
    
    private let availableMeatTypes: [MeatType] = [.beef, .pork, .chicken, .lamb, .turkey, .fish]
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                Form {
                    Section("Filter by Meat Type") {
                        ForEach(availableMeatTypes, id: \.self) { meatType in
                            HStack {
                                Text("\(meatType.icon) \(meatType.rawValue)")
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                if selectedMeatTypes.contains(meatType) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedMeatTypes.contains(meatType) {
                                    selectedMeatTypes.remove(meatType)
                                } else {
                                    selectedMeatTypes.insert(meatType)
                                }
                            }
                            .listRowBackground(DesignSystem.Colors.background)
                        }
                        
                        // Show All option
                        HStack {
                            Text("Show All")
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            if selectedMeatTypes.isEmpty {
                                Image(systemName: "checkmark")
                                    .foregroundColor(DesignSystem.Colors.primaryRed)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedMeatTypes.removeAll()
                        }
                        .listRowBackground(DesignSystem.Colors.background)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filter")
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

// MARK: - Data Models
struct ProductRecommendation: Identifiable {
    let id = UUID()
    let name: String
    let brand: String
    let image: String
    let meatType: MeatType
    let qualityRating: QualityLevel
    let isRecommended: Bool
}

enum QualityLevel {
    case excellent
    case good
    case poor
    case bad
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .poor: return "Poor"
        case .bad: return "Bad"
        }
    }
    
    var sortValue: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .poor: return 2
        case .bad: return 1
        }
    }
}

// MARK: - Mock Data
extension ProductRecommendation {
    static let mockRecommendations: [ProductRecommendation] = [
        ProductRecommendation(
            name: "Sliced Oven Roasted Turkey Breast",
            brand: "Kirkland Signature",
            image: "turkey1",
            meatType: .turkey,
            qualityRating: .poor,
            isRecommended: false
        ),
        ProductRecommendation(
            name: "Organic Roasted Turkey Breast",
            brand: "Dietz & Watson",
            image: "turkey2",
            meatType: .turkey,
            qualityRating: .excellent,
            isRecommended: true
        ),
        ProductRecommendation(
            name: "Jamaican Style Beef Patties",
            brand: "Caribbean Food Delights",
            image: "beef1",
            meatType: .beef,
            qualityRating: .bad,
            isRecommended: false
        ),
        ProductRecommendation(
            name: "Beef and Vegetables Empanadas",
            brand: "Maspanadas",
            image: "beef2",
            meatType: .beef,
            qualityRating: .excellent,
            isRecommended: true
        ),
        ProductRecommendation(
            name: "Premium Grass-Fed Ribeye",
            brand: "Whole Foods Market",
            image: "beef3",
            meatType: .beef,
            qualityRating: .excellent,
            isRecommended: true
        ),
        ProductRecommendation(
            name: "Organic Free-Range Chicken Breast",
            brand: "Nature's Promise",
            image: "chicken1",
            meatType: .chicken,
            qualityRating: .good,
            isRecommended: true
        ),
        ProductRecommendation(
            name: "Heritage Pork Chops",
            brand: "Local Farms",
            image: "pork1",
            meatType: .pork,
            qualityRating: .good,
            isRecommended: true
        ),
        ProductRecommendation(
            name: "Wild-Caught Salmon Fillets",
            brand: "Pacific Seafood",
            image: "fish1",
            meatType: .fish,
            qualityRating: .excellent,
            isRecommended: true
        ),
        ProductRecommendation(
            name: "New Zealand Lamb Chops",
            brand: "Silver Fern Farms",
            image: "lamb1",
            meatType: .lamb,
            qualityRating: .excellent,
            isRecommended: true
        )
    ]
}

#Preview {
    ExploreView()
}