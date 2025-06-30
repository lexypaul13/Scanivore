//
//  HistoryView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct HistoryView: View {
    @State private var searchText = ""
    @State private var selectedFilter: MeatType? = nil
    @State private var sortOption: SortOption = .dateDescending
    @State private var showingFilters = false
    
    let historyProducts = ProductRecommendation.mockRecommendations
    
    var filteredProducts: [ProductRecommendation] {
        var products = historyProducts
        
        if !searchText.isEmpty {
            products = products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.brand.localizedCaseInsensitiveContains(searchText) ||
                product.meatType.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let filter = selectedFilter {
            products = products.filter { $0.meatType == filter }
        }
        
        switch sortOption {
        case .dateDescending, .dateAscending:
            // Since ProductRecommendation doesn't have date, we'll sort by name
            products.sort { sortOption == .dateDescending ? $0.name < $1.name : $0.name > $1.name }
        case .qualityDescending:
            products.sort { $0.qualityRating.sortValue > $1.qualityRating.sortValue }
        case .qualityAscending:
            products.sort { $0.qualityRating.sortValue < $1.qualityRating.sortValue }
        }
        
        return products
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if filteredProducts.isEmpty {
                        EmptyHistoryView()
                    } else {
                        List {
                            ForEach(filteredProducts) { product in
                                ProductHistoryRowView(product: product)
                                    .listRowBackground(DesignSystem.Colors.background)
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .customNavigationTitle("Scan History")
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search scans...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(
                    selectedFilter: $selectedFilter,
                    sortOption: $sortOption
                )
            }
        }
    }
}

struct ProductHistoryRowView: View {
    let product: ProductRecommendation
    @State private var showingDetail = false
    
    var qualityColor: Color {
        switch product.qualityRating {
        case .excellent: return DesignSystem.Colors.success
        case .good: return Color.blue
        case .poor: return Color.orange
        case .bad: return DesignSystem.Colors.error
        }
    }
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Text(product.meatType.icon)
                    .font(DesignSystem.Typography.heading2)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(qualityColor.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(qualityColor.opacity(0.3), lineWidth: 2)
                            )
                    )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(product.name)
                        .font(DesignSystem.Typography.heading3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(product.brand)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("•")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(product.qualityRating.displayName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(qualityColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    if product.isRecommended {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.success)
                            .font(DesignSystem.Typography.caption)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            // We'll need to create a ProductDetailView for ProductRecommendation
            // For now, let's comment this out
            // ProductDetailView(product: product)
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "clock.badge.xmark")
                .font(DesignSystem.Typography.hero)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("No Products Yet")
                .font(DesignSystem.Typography.heading1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Your scanned products will appear here")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

struct FilterView: View {
    @Binding var selectedFilter: MeatType?
    @Binding var sortOption: SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                Form {
                    Section("Filter by Meat Type") {
                        ForEach([nil] + MeatType.allCases.filter { $0 != .unknown }, id: \.self) { type in
                            HStack {
                                if let type = type {
                                    Text("\(type.icon) \(type.rawValue)")
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                } else {
                                    Text("All Types")
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                                
                                Spacer()
                                
                                if selectedFilter == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFilter = type
                            }
                            .listRowBackground(DesignSystem.Colors.background)
                        }
                    }
                    
                    Section("Sort By") {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            HStack {
                                Text(option.displayName)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                sortOption = option
                            }
                            .listRowBackground(DesignSystem.Colors.background)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filters")
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

enum SortOption: CaseIterable {
    case dateDescending
    case dateAscending
    case qualityDescending
    case qualityAscending
    
    var displayName: String {
        switch self {
        case .dateDescending: return "Newest First"
        case .dateAscending: return "Oldest First"
        case .qualityDescending: return "Highest Quality"
        case .qualityAscending: return "Lowest Quality"
        }
    }
}

#Preview {
    HistoryView()
}