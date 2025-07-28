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

// MARK: - Actions Section
private struct ActionsSection: View {
    let store: StoreOf<DataManagementFeature>
    
    var body: some View {
        Section("Actions") {
            DeleteAllDataButton(store: store)
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
                DataManagementFeature()._printChanges()
            } withDependencies: {
                $0.scanHistoryClient = .previewValue
            }
        )
    }
}
