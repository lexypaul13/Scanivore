//
//  HistoryView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI
import ComposableArchitecture

// MARK: - History Feature Domain
@Reducer
struct HistoryFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var searchText = ""
        var showingFilters = false
        var scanHistory: [ProductRecommendation] = []
        
        var filteredProducts: [ProductRecommendation] {
            let filtered = searchText.isEmpty 
                ? scanHistory
                : scanHistory.filter { product in
                    product.name.localizedCaseInsensitiveContains(searchText) ||
                    product.brand.localizedCaseInsensitiveContains(searchText)
                }
            // Sort by most recent (mock data: sort by name as proxy)
            return filtered.sorted { $0.name < $1.name }
        }
    }
    
    enum Action {
        case searchTextChanged(String)
        case filterButtonTapped
        case filtersDismissed
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .searchTextChanged(text):
                state.searchText = text
                return .none
                
            case .filterButtonTapped:
                state.showingFilters = true
                return .none
                
            case .filtersDismissed:
                state.showingFilters = false
                return .none
            }
        }
    }
}

struct HistoryView: View {
    let store: StoreOf<HistoryFeatureDomain>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    DesignSystem.Colors.backgroundSecondary
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        if store.filteredProducts.isEmpty {
                            EmptyHistoryView()
                        } else {
                            List {
                                ForEach(store.filteredProducts) { product in
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
                .searchable(
                    text: .init(
                        get: { store.searchText },
                        set: { store.send(.searchTextChanged($0)) }
                    ),
                    prompt: "Search scans..."
                )
                .sheet(
                    isPresented: .init(
                        get: { store.showingFilters },
                        set: { _ in store.send(.filtersDismissed) }
                    )
                ) {
                    FilterView()
                }
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
                .foregroundColor(DesignSystem.Colors.primaryRed)
            
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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Filters coming soon...")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(DesignSystem.Colors.backgroundSecondary)
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

#Preview {
    HistoryView(
        store: Store(initialState: HistoryFeatureDomain.State()) {
            HistoryFeatureDomain()
        }
    )
}
