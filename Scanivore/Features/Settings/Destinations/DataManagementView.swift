//
//  DataManagementView.swift
//  Scanivore
//
//  Data management view for scan history and storage
//

import SwiftUI
import ComposableArchitecture

struct DataManagementView: View {
    public init(store: StoreOf<DataManagementFeature>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<DataManagementFeature>
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.backgroundSecondary
                .ignoresSafeArea()
            
            if store.isLoading {
                LoadingView()
            } else {
                DataManagementContent(store: store)
            }
        }
        .customNavigationTitle("Data Management")
        .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            store.send(.onAppear)
        }
        .alert("Delete All Data?", isPresented: $store.showingDeleteConfirmation.sending(\.setDeleteConfirmation)) {
            DeleteConfirmationAlert(store: store)
        } message: {
            Text("This action cannot be undone. All your scan history will be permanently deleted.")
        }
        .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
            ErrorAlert(store: store)
        } message: {
            if let error = store.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Content
private struct DataManagementContent: View {
    let store: StoreOf<DataManagementFeature>
    
    var body: some View {
        Form {
            StorageSection(
                totalScans: store.totalScans,
                storageUsed: store.storageUsed
            )
            
            if store.totalScans > 0 {
                RecentScansSection(store: store)
            }
            
            ActionsSection(store: store)
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Storage Section
private struct StorageSection: View {
    let totalScans: Int
    let storageUsed: String
    
    var body: some View {
        Section("Storage") {
            StorageInfoRow(
                title: "Total Scans",
                value: "\(totalScans)"
            )
            
            StorageInfoRow(
                title: "Storage Used",
                value: storageUsed
            )
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
}

// MARK: - Storage Info Row
private struct StorageInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Recent Scans Section
private struct RecentScansSection: View {
    let store: StoreOf<DataManagementFeature>
    
    var body: some View {
        Section("Recent Scans") {
            ForEach(store.recentScans.prefix(5)) { scan in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scan.productName)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(formatScanDate(scan.scanDate))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if let size = scan.estimatedSize {
                        Text(formatBytes(size))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            if store.totalScans > 5 {
                HStack {
                    Text("And \(store.totalScans - 5) more...")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
    
    private func formatScanDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Actions Section
private struct ActionsSection: View {
    let store: StoreOf<DataManagementFeature>
    
    var body: some View {
        Section("Actions") {
            if store.totalScans > 0 {
                DeleteAllDataButton(store: store)
            } else {
                Text("No scan data to manage")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
}

// MARK: - Delete All Data Button
private struct DeleteAllDataButton: View {
    let store: StoreOf<DataManagementFeature>
    
    var body: some View {
        Button(role: .destructive) {
            store.send(.deleteAllDataTapped)
        } label: {
            Label("Delete All Data", systemImage: "trash")
                .foregroundColor(DesignSystem.Colors.error)
        }
    }
}



// MARK: - Alert Views
private struct DeleteConfirmationAlert: View {
    let store: StoreOf<DataManagementFeature>
    
    var body: some View {
        Group {
            Button("Cancel", role: .cancel) {
                store.send(.cancelDeleteAllData)
            }
            Button("Delete", role: .destructive) {
                store.send(.confirmDeleteAllData)
            }
        }
    }
}

private struct ErrorAlert: View {
    let store: StoreOf<DataManagementFeature>
    
    var body: some View {
        Button("OK") {
            store.send(.dismissError)
        }
    }
}

#Preview {
    NavigationStack {
        DataManagementView(
            store: Store(initialState: DataManagementFeature.State()) {
                DataManagementFeature()
            } withDependencies: {
                $0.scanHistoryClient = .previewValue
            }
        )
    }
}
