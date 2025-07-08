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
        var hasCompletedIntro = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedIntro)
        var isLoggedIn = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isLoggedIn)
        var selectedTab = 0
        var onboardingIntro = OnboardingIntroFeatureDomain.State()
        var login = LoginFeatureDomain.State()
        var onboarding = OnboardingFeatureDomain.State()
        var scanner = ScannerFeatureDomain.State()
        var explore = ExploreFeatureDomain.State()
        var history = HistoryFeatureDomain.State()
        
        var showOnboardingIntro: Bool {
            !hasCompletedIntro
        }
        
        var showLogin: Bool {
            hasCompletedIntro && !isLoggedIn
        }
        
        var showOnboarding: Bool {
            hasCompletedIntro && isLoggedIn && !hasCompletedOnboarding
        }
        
        var showMainApp: Bool {
            hasCompletedIntro && isLoggedIn && hasCompletedOnboarding
        }
    }
    
    enum Action {
        case tabSelected(Int)
        case onboardingIntro(OnboardingIntroFeatureDomain.Action)
        case login(LoginFeatureDomain.Action)
        case onboarding(OnboardingFeatureDomain.Action)
        case scanner(ScannerFeatureDomain.Action)
        case explore(ExploreFeatureDomain.Action)
        case history(HistoryFeatureDomain.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.onboardingIntro, action: \.onboardingIntro) {
            OnboardingIntroFeatureDomain()
        }
        
        Scope(state: \.login, action: \.login) {
            LoginFeatureDomain()
        }
        
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeatureDomain()
        }
        
        Scope(state: \.scanner, action: \.scanner) {
            ScannerFeatureDomain()
        }
        
        Scope(state: \.explore, action: \.explore) {
            ExploreFeatureDomain()
        }
        
        Scope(state: \.history, action: \.history) {
            HistoryFeatureDomain()
        }
        
        Reduce { state, action in
            switch action {
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .onboardingIntro(.delegate(.introCompleted)):
                // Intro completed, save state and proceed to login
                state.hasCompletedIntro = true
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCompletedIntro)
                return .none
                
            case .onboardingIntro:
                return .none
                
            case .login(.delegate(.navigateToCreateAccount)), .login(.delegate(.navigateToSignIn)):
                // For now, we'll mark as logged in when either button is tapped
                // In a real app, this would navigate to respective flows
                state.isLoggedIn = true
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isLoggedIn)
                return .none
                
            case .login:
                return .none
                
            case .onboarding(.delegate(.onboardingCompleted(let preferences))):
                // Onboarding is completed with preferences data
                state.hasCompletedOnboarding = true
                return .none
                
            case .onboarding(.delegate(.onboardingCancelled)):
                // Handle onboarding cancellation if needed
                return .none
                
            case .onboarding:
                return .none
                
            case .scanner:
                return .none
                
            case .explore:
                return .none
                
            case .history:
                return .none
            }
        }
    }
} 