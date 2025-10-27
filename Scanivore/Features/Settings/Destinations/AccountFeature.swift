
import Foundation
import ComposableArchitecture

@Reducer
public struct AccountFeature {
    @ObservableState
    public struct State: Equatable {
        public var userName: String
        public var userEmail: String?
        public var isSignedIn: Bool
        public var isLoading: Bool = false
        public var showingSignOutConfirmation: Bool = false
        public var showingDeleteConfirmation: Bool = false
        public var errorMessage: String?
        
        public init(
            userName: String = "Guest User",
            userEmail: String? = nil,
            isSignedIn: Bool = false
        ) {
            self.userName = userName
            self.userEmail = userEmail
            self.isSignedIn = isSignedIn
        }
    }
    
    public enum Action: Equatable {
        case onAppear
        case signInTapped
        case signOutTapped
        case deleteAccountTapped
        case confirmSignOut
        case confirmDeleteAccount
        case cancelSignOut
        case cancelDeleteAccount
        case dismissError
        case setSignOutConfirmation(Bool)
        case setDeleteConfirmation(Bool)
        
        case signOutResponse(TaskResult<Bool>)
        case deleteAccountResponse(TaskResult<Bool>)
        
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case signOutCompleted
            case accountDeleted
            case signInRequested
        }
    }
    
    @Dependency(\.authGateway) var authGateway
    @Dependency(\.dismiss) var dismiss
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case .signInTapped:
                return .send(.delegate(.signInRequested))
                
            case .signOutTapped:
                if state.isSignedIn {
                    state.showingSignOutConfirmation = true
                }
                return .none
                
            case .deleteAccountTapped:
                if state.isSignedIn {
                    state.showingDeleteConfirmation = true
                }
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
                
            case .cancelSignOut:
                state.showingSignOutConfirmation = false
                return .none
                
            case .cancelDeleteAccount:
                state.showingDeleteConfirmation = false
                return .none
                
            case let .signOutResponse(.success(success)):
                state.isLoading = false
                if success {
                    return .run { send in
                        await dismiss()
                        await send(.delegate(.signOutCompleted))
                    }
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
                    return .run { send in
                        await dismiss()
                        await send(.delegate(.accountDeleted))
                    }
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
                
            case let .setSignOutConfirmation(isPresented):
                state.showingSignOutConfirmation = isPresented
                return .none
                
            case let .setDeleteConfirmation(isPresented):
                state.showingDeleteConfirmation = isPresented
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
