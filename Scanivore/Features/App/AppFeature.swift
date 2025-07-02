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
        @Shared(.hasCompletedOnboarding) var hasCompletedOnboarding = false
        var selectedTab = 0
        var onboarding = OnboardingFeature.State()
        
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
                // Onboarding is completed, the shared state will automatically update
                // and the UI will transition to the main app
                return .none
                
            case .onboarding:
                return .none
            }
        }
    }
} 