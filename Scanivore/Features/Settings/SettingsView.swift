
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

// MARK: - User Info
public struct SettingsUserInfo: Equatable {
    public let name: String
    public let email: String?
    
    public init(name: String, email: String?) {
        self.name = name
        self.email = email
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
        public var isProfileLoading: Bool = true
        public var errorMessage: String?
        
        public init(
            destination: Destination.State? = nil,
            isSignedIn: Bool = false,
            userName: String = "Guest User",
            userEmail: String? = nil,
            isProfileLoading: Bool = true
        ) {
            self.destination = destination
            self.isSignedIn = isSignedIn
            self.userName = userName
            self.userEmail = userEmail
            self.showingSignOutConfirmation = false
            self.showingDeleteConfirmation = false
            self.isLoading = false
            self.isProfileLoading = isProfileLoading
            self.errorMessage = nil
        }
    }
    
    public enum Action {
        case onAppear
        case destination(PresentationAction<Destination.Action>)
        
        case dataManagementTapped
        case disclaimerTapped
        case privacyTapped
        case preferencesTapped
        case contactSupportTapped
        
        case loadUserInfo
        case userInfoLoaded(TaskResult<SettingsUserInfo>)
        
        case signOutTapped
        case deleteAccountTapped
        case confirmSignOut
        case cancelSignOut
        case confirmDeleteAccount
        case cancelDeleteAccount
        case setSignOutConfirmation(Bool)
        case setDeleteConfirmation(Bool)
        
        case signOutResponse(TaskResult<Bool>)
        case deleteAccountResponse(TaskResult<Bool>)
        case dismissError
        
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case signOutRequested
            case preferencesUpdated
        }
    }
    
    @Reducer(state: .equatable)
    public enum Destination {
        case dataManagement(DataManagementFeature)
        case disclaimer(DisclaimerFeature)
        case privacy(PrivacyFeature)
        case preferences(PreferencesFeature)
    }
    
    @Dependency(\.authGateway) var authGateway
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.loadUserInfo)
                
            case .loadUserInfo:
                state.isProfileLoading = true
                return .run { send in
                    let hasToken = await TokenManager.shared.hasToken()
                    
                    if !hasToken {
                        await send(.userInfoLoaded(.success(SettingsUserInfo(name: "Guest User", email: nil))))
                        return
                    }
                    
                    await send(.userInfoLoaded(
                        await TaskResult {
                            let user = try await authGateway.getCurrentUser()
                            
                            guard let user = user else {
                                throw AuthError.userNotFound
                            }
                            
                            let displayName: String
                            if let fullName = user.fullName, !fullName.isEmpty {
                                displayName = fullName
                            } else if !user.email.isEmpty {
                                displayName = String(user.email.split(separator: "@").first ?? "User")
                            } else {
                                displayName = "User"
                            }
                            
                            return SettingsUserInfo(name: displayName, email: user.email)
                        }
                    ))
                }
                
            case let .userInfoLoaded(.success(userInfo)):
                state.userName = userInfo.name
                state.userEmail = userInfo.email
                state.isSignedIn = !(userInfo.email?.isEmpty ?? true)
                state.isProfileLoading = false
                return .none
                
            case .userInfoLoaded(.failure):
                state.userName = "Guest User"
                state.userEmail = nil
                state.isSignedIn = true
                state.isProfileLoading = false
                return .none
                
            case .dataManagementTapped:
                state.destination = .dataManagement(DataManagementFeature.State())
                return .none
                
            case .disclaimerTapped:
                state.destination = .disclaimer(DisclaimerFeature.State())
                return .none
                
            case .privacyTapped:
                state.destination = .privacy(PrivacyFeature.State())
                return .none
                
            case .preferencesTapped:
                state.destination = .preferences(PreferencesFeature.State())
                return .none
                
            case .contactSupportTapped:
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
                        await TaskResult { 
                            try await authGateway.logout()
                            return true
                        }
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
                        await TaskResult { 
                            try await authGateway.deleteAccount()
                            return true
                        }
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
                
            case let .signOutResponse(.success(success)):
                state.isLoading = false
                if success {
                    state.isSignedIn = false
                    state.userName = "Guest User"
                    state.userEmail = nil

                    return .merge(
                        .send(.delegate(.signOutRequested)),
                        .send(.loadUserInfo)  // Refresh user info to ensure consistency
                    )
                } else {
                    state.errorMessage = "Failed to sign out"
                    return .none
                }
                
            case let .signOutResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to sign out: \(error.localizedDescription)"
                return .none
                
            case let .deleteAccountResponse(.success(success)):
                state.isLoading = false
                if success {
                    state.isSignedIn = false
                    state.userName = "Guest User"
                    state.userEmail = nil

                    return .merge(
                        .send(.delegate(.signOutRequested)),
                        .send(.loadUserInfo)  // Refresh user info to ensure consistency
                    )
                } else {
                    state.errorMessage = "Failed to delete account"
                    return .none
                }
                
            case let .deleteAccountResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            case .destination(.presented(.preferences(.delegate(.preferencesUpdated)))):
                return .send(.delegate(.preferencesUpdated))
                
            case .destination:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination.body
        }
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
            .sheet(item: $store.scope(state: \.destination?.disclaimer, action: \.destination.disclaimer)) { disclaimerStore in
                DisclaimerView(store: disclaimerStore)
            }
            .sheet(item: $store.scope(state: \.destination?.privacy, action: \.destination.privacy)) { privacyStore in
                PrivacyPolicyView(store: privacyStore)
            }
            .sheet(item: $store.scope(state: \.destination?.preferences, action: \.destination.preferences)) { preferencesStore in
                PreferencesView(store: preferencesStore)
            }
            .settingsAlerts(store: store)
        }
    }
}

// MARK: - View Extensions for Settings Alerts
private extension View {
    func settingsAlerts(store: StoreOf<SettingsFeature>) -> some View {
        self
            .signOutAlert(store: store)
            .deleteAccountAlert(store: store)
            .errorAlert(store: store)
    }
    
    func signOutAlert(store: StoreOf<SettingsFeature>) -> some View {
        alert("Sign Out", 
              isPresented: Binding(
                  get: { store.showingSignOutConfirmation },
                  set: { store.send(.setSignOutConfirmation($0)) }
              )) {
            Button("Cancel", role: .cancel) {
                store.send(.cancelSignOut)
            }
            Button("Sign Out", role: .destructive) {
                store.send(.confirmSignOut)
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    func deleteAccountAlert(store: StoreOf<SettingsFeature>) -> some View {
        alert("Delete Account",
              isPresented: Binding(
                  get: { store.showingDeleteConfirmation },
                  set: { store.send(.setDeleteConfirmation($0)) }
              )) {
            Button("Cancel", role: .cancel) {
                store.send(.cancelDeleteAccount)
            }
            Button("Delete", role: .destructive) {
                store.send(.confirmDeleteAccount)
            }
        } message: {
            Text("This action cannot be undone. Your account and all data will be permanently deleted.")
        }
    }
    
    func errorAlert(store: StoreOf<SettingsFeature>) -> some View {
        alert("Error",
              isPresented: .constant(store.errorMessage != nil)) {
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

// MARK: - Profile Section
private struct ProfileSection: View {
    let store: StoreOf<SettingsFeature>
    
    var body: some View {
        Section {
            if store.isProfileLoading {
                HStack(spacing: DesignSystem.Spacing.base) {
                    Circle()
                        .fill(DesignSystem.Colors.backgroundSecondary)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.Colors.backgroundSecondary)
                            .frame(width: 140, height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.Colors.backgroundSecondary)
                            .frame(width: 200, height: 12)
                    }
                }
                .redacted(reason: .placeholder)
            } else {
                ProfileHeaderView(
                    userName: store.userName,
                    userEmail: store.userEmail,
                    isSignedIn: store.isSignedIn
                )
            }
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
                color: DesignSystem.Colors.primaryRed,
                action: { store.send(.dataManagementTapped) }
            )
            
            if store.isSignedIn {
                SettingsRowView(
                    title: "Dietary Preferences",
                    systemImage: "fork.knife",
                    color: DesignSystem.Colors.primaryRed,
                    action: { store.send(.preferencesTapped) }
                )
            }
            
            SettingsRowView(
                title: "Privacy Policy",
                systemImage: "hand.raised",
                color: DesignSystem.Colors.primaryRed,
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
            Link(destination: URL(string: "mailto:lexypaul14@gmail.com")!) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                    Text("Contact Support")
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
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
                title: "Disclaimer",
                systemImage: "exclamationmark.triangle",
                color: DesignSystem.Colors.primaryRed,
                action: { store.send(.disclaimerTapped) }
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


