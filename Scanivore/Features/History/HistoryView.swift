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
        var savedProducts: [SavedProduct] = []
        var isLoading = false
        var error: String?
        @Presents var destination: Destination.State?
        
        var filteredProducts: [SavedProduct] {
            let filtered = searchText.isEmpty 
                ? savedProducts
                : savedProducts.filter { product in
                    product.productName.localizedCaseInsensitiveContains(searchText) ||
                    (product.productBrand?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            // Sort by most recent scan date
            return filtered.sorted { $0.scanDate > $1.scanDate }
        }
    }
    
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case productDetail(ProductDetailFeatureDomain)
    }
    
    enum Action: Equatable {
        case onAppear
        case loadHistory
        case historyLoaded([SavedProduct])
        case searchTextChanged(String)
        case filterButtonTapped
        case filtersDismissed
        case productTapped(SavedProduct)
        case destination(PresentationAction<Destination.Action>)
        case deleteProduct(String)
        case toggleFavorite(String)
    }
    
    @Dependency(\.scannedProducts) var scannedProducts
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.loadHistory)
                }
                
            case .loadHistory:
                state.isLoading = true
                state.error = nil
                return .run { send in
                    let products = await scannedProducts.loadAll()
                    await send(.historyLoaded(products))
                }
                
            case let .historyLoaded(products):
                state.isLoading = false
                state.savedProducts = products
                print("📱 History: Loaded \(products.count) saved products")
                return .none
                
            case let .searchTextChanged(text):
                state.searchText = text
                return .none
                
            case .filterButtonTapped:
                state.showingFilters = true
                return .none
                
            case .filtersDismissed:
                state.showingFilters = false
                return .none
                
            case let .productTapped(product):
                state.destination = .productDetail(
                    ProductDetailFeatureDomain.State(
                        productCode: product.id,
                        productName: product.productName,
                        productBrand: product.productBrand,
                        productImageUrl: nil
                    )
                )
                return .none
                
            case .destination:
                return .none
                
            case let .deleteProduct(productId):
                return .run { send in
                    await scannedProducts.delete(productId)
                    await send(.loadHistory)
                }
                
            case let .toggleFavorite(productId):
                return .run { send in
                    await scannedProducts.toggleFavorite(productId)
                    await send(.loadHistory)
                }
            }
        }
        .ifLet(\.$destination, action: \.destination)
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
                        if store.isLoading {
                            LoadingHistoryView()
                        } else if store.filteredProducts.isEmpty {
                            EmptyHistoryView()
                        } else {
                            List {
                                ForEach(store.filteredProducts) { product in
                                    SavedProductRowView(product: product) {
                                        store.send(.productTapped(product))
                                    }
                                    .listRowBackground(DesignSystem.Colors.background)
                                    .swipeActions(edge: .trailing) {
                                        Button("Delete") {
                                            store.send(.deleteProduct(product.id))
                                        }
                                        .tint(.red)
                                        
                                        Button(product.isFavorite ? "Unfavorite" : "Favorite") {
                                            store.send(.toggleFavorite(product.id))
                                        }
                                        .tint(.orange)
                                    }
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
                .sheet(
                    store: store.scope(
                        state: \.$destination.productDetail,
                        action: \.destination.productDetail
                    )
                ) { store in
                    ProductDetailView(store: store)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

struct SavedProductRowView: View {
    let product: SavedProduct
    let onTap: () -> Void
    
    private var safetyGrade: SafetyGrade {
        // Map quality score to safety grade
        let score = product.meatScan.quality.score
        switch score {
        case 80...100: return .excellent
        case 60..<80: return .fair
        default: return .bad
        }
    }
    
    private var safetyColor: Color {
        switch safetyGrade {
        case .excellent: return DesignSystem.Colors.success
        case .fair: return DesignSystem.Colors.warning
        case .bad: return DesignSystem.Colors.error
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Text(product.meatScan.meatType.icon)
                    .font(DesignSystem.Typography.heading2)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(safetyColor.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(safetyColor.opacity(0.3), lineWidth: 2)
                            )
                    )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(product.productName)
                        .font(DesignSystem.Typography.heading3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(product.productBrand ?? "Unknown Brand")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("•")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(safetyGrade.rawValue)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(safetyColor)
                    }
                    
                    // Show scan date
                    Text(DateFormatter.historyFormatter.string(from: product.scanDate))
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    if product.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                            .font(DesignSystem.Typography.caption)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(DesignSystem.Typography.small)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LoadingHistoryView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text("Loading scan history...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundSecondary)
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

// MARK: - Extensions
extension DateFormatter {
    static let historyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    HistoryView(
        store: Store(initialState: HistoryFeatureDomain.State()) {
            HistoryFeatureDomain()
        }
    )
}
