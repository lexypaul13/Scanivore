//
//  SettingsView.swift
//  Scanivore
//
//  TCA-compliant Settings view with tree-based navigation
//

import SwiftUI
import ComposableArchitecture

// MARK: - Auth Error
enum AuthError: Error, LocalizedError {
    case userNotFound
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User information not found"
        case .tokenExpired:
            return "Authentication token has expired"
        }
    }
}

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        public var isSignedIn: Bool = false
        public var userName: String = "Guest User"
        public var userEmail: String?
        public var showingSignOutConfirmation: Bool = false
        public var showingDeleteConfirmation: Bool = false
        public var isLoading: Bool = false
        public var errorMessage: String?
        
        public init(
            destination: Destination.State? = nil,
            isSignedIn: Bool = false,
            userName: String = "Guest User",
            userEmail: String? = nil
        ) {
            self.destination = destination
            self.isSignedIn = isSignedIn
            self.userName = userName
            self.userEmail = userEmail
            self.showingSignOutConfirmation = false
            self.showingDeleteConfirmation = false
            self.isLoading = false
            self.errorMessage = nil
        }
    }
    
    public enum Action: Sendable {
        case onAppear
        case destination(PresentationAction<Destination.Action>)
        
        // Navigation actions
        case dataManagementTapped
        case aboutTapped
        case privacyTapped
        case contactSupportTapped
        
        // Profile actions
        case loadUserInfo
        case userInfoLoaded(TaskResult<(String, String?)>)
        
        // Auth actions
        case signOutTapped
        case deleteAccountTapped
        case confirmSignOut
        case cancelSignOut
        case confirmDeleteAccount
        case cancelDeleteAccount
        case setSignOutConfirmation(Bool)
        case setDeleteConfirmation(Bool)
        
        // Async responses
        case signOutResponse(TaskResult<Void>)
        case deleteAccountResponse(TaskResult<Void>)
        case dismissError
        
        // Internal actions
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case signOutRequested
        }
    }
    
    @Reducer(state: .equatable)
    public enum Destination {
        case dataManagement(DataManagementFeature)
        case about(AboutFeature)
        case privacy(PrivacyFeature)
    }
    
    @Dependency(\.authGateway) var authGateway
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                print("Settings onAppear triggered")
                return .send(.loadUserInfo)
                
            case .loadUserInfo:
                return .run { send in
                    // First check if we have a token
                    let hasToken = await TokenManager.shared.hasToken()
                    
                    if !hasToken {
                        // No token, user is not signed in
                        await send(.userInfoLoaded(.success(("Guest User", nil))))
                        return
                    }
                    
                    // We have a token, try to get user info
                    await send(.userInfoLoaded(
                        TaskResult {
                            let user = try await authGateway.getCurrentUser()
                            
                            // If no user object, authentication failed
                            guard let user = user else {
                                throw AuthError.userNotFound
                            }
                            
                            // User is authenticated, determine display name
                            let displayName: String
                            if let fullName = user.fullName, !fullName.isEmpty {
                                displayName = fullName
                            } else if !user.email.isEmpty {
                                // Use email prefix as fallback for authenticated users
                                displayName = String(user.email.split(separator: "@").first ?? "User")
                            } else {
                                displayName = "User"
                            }
                            
                            return (displayName, user.email)
                        }
                    ))
                }
                
            case let .userInfoLoaded(.success((name, email))):
                state.userName = name
                state.userEmail = email
                // User is signed in if we have an email (indicates successful user fetch)
                state.isSignedIn = !(email?.isEmpty ?? true)
                return .none
                
            case .userInfoLoaded(.failure):
                state.userName = "Guest User"
                state.userEmail = nil
                // If we got here, we have a token but it's invalid (401 error)
                // Show as signed in so user can sign out and get a new token
                state.isSignedIn = true
                return .none
                
            case .dataManagementTapped:
                state.destination = .dataManagement(DataManagementFeature.State())
                return .none
                
            case .aboutTapped:
                state.destination = .about(AboutFeature.State())
                return .none
                
            case .privacyTapped:
                state.destination = .privacy(PrivacyFeature.State())
                return .none
                
            case .contactSupportTapped:
                // External link - no navigation state needed
                return .none
                
            case .signOutTapped:
                state.showingSignOutConfirmation = true
                return .none
                
            case .deleteAccountTapped:
                state.showingDeleteConfirmation = true
                return .none
                
            case .confirmSignOut:
                state.showingSignOutConfirmation = false
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    await send(.signOutResponse(
                        TaskResult { try await authGateway.logout() }
                    ))
                }
                
            case .cancelSignOut:
                state.showingSignOutConfirmation = false
                return .none
                
            case .confirmDeleteAccount:
                state.showingDeleteConfirmation = false
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    await send(.deleteAccountResponse(
                        TaskResult { try await authGateway.deleteAccount() }
                    ))
                }
                
            case .cancelDeleteAccount:
                state.showingDeleteConfirmation = false
                return .none
                
            case let .setSignOutConfirmation(isPresented):
                state.showingSignOutConfirmation = isPresented
                return .none
                
            case let .setDeleteConfirmation(isPresented):
                state.showingDeleteConfirmation = isPresented
                return .none
                
            case .signOutResponse(.success):
                state.isLoading = false
                return .send(.delegate(.signOutRequested))
                
            case let .signOutResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to sign out: \(error.localizedDescription)"
                return .none
                
            case .deleteAccountResponse(.success):
                state.isLoading = false
                return .send(.delegate(.signOutRequested))
                
            case let .deleteAccountResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            case .destination:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
        ._printChanges()
    }
}

struct SettingsView: View {
    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<SettingsFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                Form {
                    ProfileSection(store: store)
                    if store.isSignedIn {
                        AccountActionsSection(store: store)
                    }
                    DataPrivacySection(store: store)
                    SupportSection()
                    InfoSection(store: store)
                }
                .scrollContentBackground(.hidden)
            }
            .customNavigationTitle("Settings")
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                store.send(.onAppear)
            }
            .navigationDestination(item: $store.scope(state: \.destination?.dataManagement, action: \.destination.dataManagement)) { dataStore in
                DataManagementView(store: dataStore)
            }
            .sheet(item: $store.scope(state: \.destination?.about, action: \.destination.about)) { aboutStore in
                AboutView(store: aboutStore)
            }
            .sheet(item: $store.scope(state: \.destination?.privacy, action: \.destination.privacy)) { privacyStore in
                PrivacyPolicyView(store: privacyStore)
            }
            .alert("Sign Out", isPresented: $store.showingSignOutConfirmation.sending(\.setSignOutConfirmation)) {
                Button("Cancel", role: .cancel) {
                    store.send(.cancelSignOut)
                }
                Button("Sign Out", role: .destructive) {
                    store.send(.confirmSignOut)
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $store.showingDeleteConfirmation.sending(\.setDeleteConfirmation)) {
                Button("Cancel", role: .cancel) {
                    store.send(.cancelDeleteAccount)
                }
                Button("Delete", role: .destructive) {
                    store.send(.confirmDeleteAccount)
                }
            } message: {
                Text("This action cannot be undone. Your account and all data will be permanently deleted.")
            }
            .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
                Button("OK") {
                    store.send(.dismissError)
                }
            } message: {
                if let error = store.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

// MARK: - Profile Section
private struct ProfileSection: View {
    let store: StoreOf<SettingsFeature>
    
    var body: some View {
        Section {
            ProfileHeaderView(
                userName: store.userName,
                userEmail: store.userEmail,
                isSignedIn: store.isSignedIn
            )
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
}

// MARK: - Account Actions Section
private struct AccountActionsSection: View {
    let store: StoreOf<SettingsFeature>
    
    var body: some View {
        Section("Account") {
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

// MARK: - Data & Privacy Section
private struct DataPrivacySection: View {
    let store: StoreOf<SettingsFeature>
    
    var body: some View {
        Section("Data & Privacy") {
            SettingsRowView(
                title: "Manage Scan Data",
                systemImage: "folder",
                color: DesignSystem.Colors.textPrimary,
                action: { store.send(.dataManagementTapped) }
            )
            
            SettingsRowView(
                title: "Privacy Policy",
                systemImage: "hand.raised",
                color: DesignSystem.Colors.textPrimary,
                action: { store.send(.privacyTapped) }
            )
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
}

// MARK: - Support Section
private struct SupportSection: View {
    var body: some View {
        Section("Support") {
            Link(destination: URL(string: "mailto:support@scanivore.app")!) {
                Label("Contact Support", systemImage: "envelope")
                    .foregroundColor(DesignSystem.Colors.primaryRed)
            }
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
}

// MARK: - Info Section
private struct InfoSection: View {
    let store: StoreOf<SettingsFeature>
    
    var body: some View {
        Section {
            SettingsRowView(
                title: "About Scanivore",
                systemImage: "info.circle",
                color: DesignSystem.Colors.textPrimary,
                action: { store.send(.aboutTapped) }
            )
            
            HStack {
                Text("Version")
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
}

#Preview {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}
