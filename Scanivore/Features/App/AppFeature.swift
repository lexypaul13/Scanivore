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
        var authState = AuthState.initial
        var isShowingLaunchScreen = true
        var hasCompletedOnboarding: Bool {
            authState.hasCompletedOnboarding
        }
        var hasCompletedIntro: Bool {
            authState.hasCompletedIntro
        }
        var isLoggedIn: Bool {
            authState.isLoggedIn
        }
        var selectedTab = 0
        var onboardingIntro = OnboardingIntroFeatureDomain.State()
        var login = LoginFeatureDomain.State()
        var createAccount = CreateAccountFeatureDomain.State()
        var signIn = SignInFeatureDomain.State()
        var onboarding = OnboardingFeatureDomain.State()
        var scanner = ScannerFeatureDomain.State()
        var explore = ExploreFeatureDomain.State()
        var history = HistoryFeatureDomain.State()
        var settings = SettingsFeature.State()
        
        // Auth flow state
        var authFlow: AuthFlow = .login
        
        enum AuthFlow {
            case login
            case createAccount
            case signIn
        }
        
        var showOnboardingIntro: Bool {
            !hasCompletedIntro
        }
        
        var showLogin: Bool {
            hasCompletedIntro && !isLoggedIn && authFlow == .login
        }
        
        var showCreateAccount: Bool {
            hasCompletedIntro && !isLoggedIn && authFlow == .createAccount
        }
        
        var showSignIn: Bool {
            hasCompletedIntro && !isLoggedIn && authFlow == .signIn
        }
        
        var showOnboarding: Bool {
            hasCompletedIntro && isLoggedIn && !hasCompletedOnboarding
        }
        
        var showMainApp: Bool {
            hasCompletedIntro && isLoggedIn && hasCompletedOnboarding
        }
    }
    
    enum Action {
        case appDidLaunch
        case launchScreenFinished
        case authStateLoaded(AuthState)
        case resetOnboarding
        case tabSelected(Int)
        case onboardingIntro(OnboardingIntroFeatureDomain.Action)
        case login(LoginFeatureDomain.Action)
        case createAccount(CreateAccountFeatureDomain.Action)
        case signIn(SignInFeatureDomain.Action)
        case onboarding(OnboardingFeatureDomain.Action)
        case scanner(ScannerFeatureDomain.Action)
        case explore(ExploreFeatureDomain.Action)
        case history(HistoryFeatureDomain.Action)
        case settings(SettingsFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.onboardingIntro, action: \.onboardingIntro) {
            OnboardingIntroFeatureDomain()
        }
        
        Scope(state: \.login, action: \.login) {
            LoginFeatureDomain()
        }
        
        Scope(state: \.createAccount, action: \.createAccount) {
            CreateAccountFeatureDomain()
        }
        
        Scope(state: \.signIn, action: \.signIn) {
            SignInFeatureDomain()
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
        
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .appDidLaunch:
                return .run { send in
                    @Dependency(\.authState) var authState
                    let loadedState = await authState.load()
                    await send(.authStateLoaded(loadedState))
                    
                    // Show launch screen for 1.5 seconds
                    try await Task.sleep(for: .seconds(1.5))
                    await send(.launchScreenFinished)
                }
                
            case .launchScreenFinished:
                state.isShowingLaunchScreen = false
                return .none
                
            case let .authStateLoaded(authState):
                state.authState = authState
                return .none
                
            case .resetOnboarding:
                state.authState = AuthState.initial
                return .run { _ in
                    @Dependency(\.authState) var authState
                    await authState.reset()
                }
                
            case let .tabSelected(tab):
                state.selectedTab = tab
                return .none
                
            case .onboardingIntro(.delegate(.introCompleted)):
                state.authState.hasCompletedIntro = true
                return .run { _ in
                    @Dependency(\.authState) var authState
                    await authState.markIntroCompleted()
                }
                
            case .onboardingIntro:
                return .none
                
            case .login(.delegate(.navigateToCreateAccount)):
                state.authFlow = .createAccount
                return .none
                
            case .login(.delegate(.navigateToSignIn)):
                state.authFlow = .signIn
                return .none
                
            case .login:
                return .none
                
            case .createAccount(.delegate(.accountCreated)):
                state.authState.isLoggedIn = true
                state.authFlow = .login
                return .run { _ in
                    @Dependency(\.authState) var authState
                    await authState.markLoggedIn(true)
                }
                
            case .createAccount(.delegate(.navigateBack)):
                state.authFlow = .login
                return .none
                
            case .createAccount:
                return .none
                
            case .signIn(.delegate(.signedIn)):
                state.authState.isLoggedIn = true
                state.authFlow = .login
                return .run { _ in
                    @Dependency(\.authState) var authState
                    await authState.markLoggedIn(true)
                }
                
            case .signIn(.delegate(.navigateBack)):
                state.authFlow = .login
                return .none
                
            case .signIn(.delegate(.navigateToForgotPassword)):
                // Handle forgot password flow (placeholder)
                return .none
                
            case .signIn:
                return .none
                
            case .onboarding(.delegate(.onboardingCompleted(let preferences))):
                state.authState.hasCompletedOnboarding = true
                return .run { _ in
                    @Dependency(\.authState) var authState
                    @Dependency(\.onboarding) var onboarding
                    await authState.markOnboardingCompleted()
                    await onboarding.save(preferences)
                }
                
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
                
            case .settings(.delegate(.signOutRequested)):
                // Handle sign out request from settings
                state.authState.isLoggedIn = false
                state.authFlow = .login
                return .run { _ in
                    @Dependency(\.authState) var authState
                    await authState.markLoggedIn(false)
                }
                
            case .settings:
                return .none
            }
        }
    }
} 