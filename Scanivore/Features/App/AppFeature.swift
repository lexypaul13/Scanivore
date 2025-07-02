//
//  AppFeature.swift
//  Scanivore
//
//  Main application TCA feature
//

import Foundation
import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedOnboarding)
        var selectedTab = 0
        var onboarding = OnboardingFeature.State(path: StackState<OnboardingPath.State>())
        
        var showOnboarding: Bool {
            !hasCompletedOnboarding
        }
    }
    
    enum Action {
        case tabSelected(Int)
        case onboarding(OnboardingFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
        
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .onboarding(.delegate(.onboardingCompleted)):
                // Onboarding is completed, update local state
                state.hasCompletedOnboarding = true
                return .none
                
            case .onboarding:
                return .none
            }
        }
    }
} 