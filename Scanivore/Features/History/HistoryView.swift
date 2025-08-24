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
        case createAccountTapped
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case requestAccountCreation
        }
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
                state.destination = .productDetail(ProductDetailFeatureDomain.State(
                    productCode: product.id,
                    context: .history,
                    productName: product.productName,
                    productBrand: product.productBrand,
                    productImageUrl: product.productImageUrl,
                    healthAssessment: product.healthAssessment
                ))
                return .none
                
            case .destination:
                return .none
                
            case let .deleteProduct(productId):
                return .run { send in
                    await scannedProducts.delete(productId)
                    await send(.loadHistory)
                }
                
            case .createAccountTapped:
                return .send(.delegate(.requestAccountCreation))
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

struct HistoryView: View {
    let store: StoreOf<HistoryFeatureDomain>
    @State private var isGuest = true
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    DesignSystem.Colors.backgroundSecondary
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        if isGuest {
                            GuestHistoryView {
                                store.send(.createAccountTapped)
                            }
                        } else if store.isLoading {
                            LoadingHistoryView()
                        } else if store.filteredProducts.isEmpty {
                            EmptyHistoryView()
                        } else {
                            List {
                                ForEach(store.filteredProducts) { product in
                                    SavedProductRowView(product: product) {
                                        store.send(.productTapped(product))
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: DesignSystem.Spacing.xs,
                                        leading: DesignSystem.Spacing.screenPadding,
                                        bottom: DesignSystem.Spacing.xs,
                                        trailing: DesignSystem.Spacing.screenPadding
                                    ))
                                    .swipeActions(edge: .trailing) {
                                        Button("Delete") {
                                            store.send(.deleteProduct(product.id))
                                        }
                                        .tint(DesignSystem.Colors.error)
                                    }
                                }
                            }
                            .listStyle(.plain)
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
                
                // Check authentication state
                Task {
                    @Dependency(\.authState) var authState
                    let currentState = await authState.load()
                    await MainActor.run {
                        isGuest = !currentState.isLoggedIn
                    }
                }
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
        HStack(spacing: DesignSystem.Spacing.base) {
            // Product Image
            HistoryPlaceholderImage(meatType: product.meatScan.meatType)
            
            // Product Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // Name and Brand
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.productName)
                        .font(DesignSystem.Typography.buttonText)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(product.productBrand ?? "Unknown Brand")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                // Meat type and quality badges
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // Meat Type Badge
                    HStack(spacing: 4) {
                        Text(product.meatScan.meatType.icon)
                            .font(DesignSystem.Typography.body)
                        Text(product.meatScan.meatType.rawValue)
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .fixedSize(horizontal: true, vertical: false)
                            .allowsTightening(true)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
                    
                    // Quality Badge
                    HistoryQualityBadge(grade: safetyGrade)
                }
                
                // Scan Date
                Text(DateFormatter.historyFormatter.string(from: product.scanDate))
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(DesignSystem.Typography.body)
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
            onTap()
        }
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

struct GuestHistoryView: View {
    let onCreateAccount: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(DesignSystem.Typography.hero)
                .foregroundColor(DesignSystem.Colors.primaryRed)
            
            Text("Sign Up to Save Scans")
                .font(DesignSystem.Typography.heading1)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Create an account to save your scan history and access it anytime")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Button("Create Account") {
                onCreateAccount()
            }
            .font(DesignSystem.Typography.buttonText)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primaryRed)
            .cornerRadius(DesignSystem.CornerRadius.md)
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
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
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

// MARK: - History Placeholder Image Component
struct HistoryPlaceholderImage: View {
    let meatType: MeatType
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundSecondary)
                .frame(width: 120, height: 120)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(meatType.icon)
                    .font(.system(size: 32))
                
                Text(meatType.rawValue)
                    .font(DesignSystem.Typography.captionMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - History Quality Badge Component
struct HistoryQualityBadge: View {
    let grade: SafetyGrade
    
    var badgeColor: Color {
        switch grade {
        case .excellent:
            return DesignSystem.Colors.success
        case .fair:
            return DesignSystem.Colors.warning
        case .bad:
            return DesignSystem.Colors.error
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)
            
            Text(grade.rawValue)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .fixedSize(horizontal: true, vertical: false)
                .allowsTightening(true)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.full)
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
