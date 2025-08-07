//
//  AccountView.swift
//  Scanivore
//
//  Account management view with authentication controls
//

import SwiftUI
import ComposableArchitecture

struct AccountView: View {
    public init(store: StoreOf<AccountFeature>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<AccountFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                if store.isLoading {
                    LoadingOverlay()
                } else {
                    AccountContent(store: store)
                }
            }
            .customNavigationTitle("Account")
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DismissButton()
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
            .alert("Sign Out", isPresented: $store.showingSignOutConfirmation.sending(\.setSignOutConfirmation)) {
                SignOutAlert(store: store)
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $store.showingDeleteConfirmation.sending(\.setDeleteConfirmation)) {
                DeleteAccountAlert(store: store)
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
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
}

// MARK: - Account Content
private struct AccountContent: View {
    let store: StoreOf<AccountFeature>
    
    var body: some View {
        Form {
            if store.isSignedIn {
                SignedInContent(store: store)
            } else {
                GuestContent(store: store)
            }
        }
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Signed In Content
private struct SignedInContent: View {
    let store: StoreOf<AccountFeature>
    
    var body: some View {
        Section("Profile") {
            ProfileInfo(
                userName: store.userName,
                userEmail: store.userEmail
            )
        }
        .listRowBackground(DesignSystem.Colors.background)
        
        Section("Account Actions") {
            Button("Sign Out") {
                store.send(.signOutTapped)
            }
            .foregroundColor(DesignSystem.Colors.primaryRed)
            
            Button("Delete Account") {
                store.send(.deleteAccountTapped)
            }
            .foregroundColor(DesignSystem.Colors.error)
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
}

// MARK: - Guest Content
private struct GuestContent: View {
    let store: StoreOf<AccountFeature>
    
    var body: some View {
        Section {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: DesignSystem.Typography.xxxxxl))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Sign In Required")
                        .font(DesignSystem.Typography.heading2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Sign in to sync your data and access personalized features")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Button("Sign In") {
                    store.send(.signInTapped)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.vertical, DesignSystem.Spacing.xl)
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
}

// MARK: - Profile Info
private struct ProfileInfo: View {
    let userName: String
    let userEmail: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Name")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
                Text(userName)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            if let email = userEmail {
                HStack {
                    Text("Email")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text(email)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
    }
}

// MARK: - Loading Overlay
private struct LoadingOverlay: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Processing...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Dismiss Button
private struct DismissButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button("Done") {
            dismiss()
        }
        .foregroundColor(DesignSystem.Colors.primaryRed)
    }
}

// MARK: - Alert Views
private struct SignOutAlert: View {
    let store: StoreOf<AccountFeature>
    
    var body: some View {
        Group {
            Button("Cancel", role: .cancel) {
                store.send(.cancelSignOut)
            }
            Button("Sign Out", role: .destructive) {
                store.send(.confirmSignOut)
            }
        }
    }
}

private struct DeleteAccountAlert: View {
    let store: StoreOf<AccountFeature>
    
    var body: some View {
        Group {
            Button("Cancel", role: .cancel) {
                store.send(.cancelDeleteAccount)
            }
            Button("Delete", role: .destructive) {
                store.send(.confirmDeleteAccount)
            }
        }
    }
}

private struct ErrorAlert: View {
    let store: StoreOf<AccountFeature>
    
    var body: some View {
        Button("OK") {
            store.send(.dismissError)
        }
    }
}

#Preview {
    AccountView(
        store: Store(initialState: AccountFeature.State(
            userName: "John Doe",
            userEmail: "john@example.com",
            isSignedIn: true
        )) {
            AccountFeature()
        }
    )
}