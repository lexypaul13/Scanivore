//
//  LoginFeatureDomain.swift
//  Scanivore
//
//  TCA-compliant login feature domain
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct LoginFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var errorMessage: String?
    }
    
    enum Action {
        case createAccountTapped
        case signInTapped
        case clearError
        
        enum Delegate {
            case navigateToCreateAccount
            case navigateToSignIn
        }
        case delegate(Delegate)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .createAccountTapped:
                state.errorMessage = nil
                return .run { send in
                    await send(.delegate(.navigateToCreateAccount))
                }
                
            case .signInTapped:
                state.errorMessage = nil
                return .run { send in
                    await send(.delegate(.navigateToSignIn))
                }
                
            case .clearError:
                state.errorMessage = nil
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}