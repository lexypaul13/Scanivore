//
//  AppFeatureTests.swift
//  ScanivoreTests
//
//  Unit tests for the main app feature and user flow
//

import XCTest
import ComposableArchitecture
@testable import Scanivore

@MainActor
final class AppFeatureTests: XCTestCase {
    
    // MARK: - New User Complete Flow Tests
    
    func testNewUserSignupCompleteFlow() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.authState = .testValue
            $0.onboarding = .testValue
        }
        
        // Initial state - should show intro
        XCTAssertTrue(store.state.showOnboardingIntro)
        XCTAssertFalse(store.state.showLogin)
        XCTAssertFalse(store.state.showOnboarding)
        XCTAssertFalse(store.state.showMainApp)
        
        // Step 1: User creates account
        await store.send(.createAccount(.delegate(.accountCreated))) {
            $0.authState.isLoggedIn = true
            $0.authState.hasCompletedIntro = false  // Should still show intro
            $0.authState.hasCompletedOnboarding = false
            $0.authFlow = .login
        }
        
        // After account creation - should still show intro animations
        XCTAssertTrue(store.state.showOnboardingIntro)
        XCTAssertFalse(store.state.showLogin)
        XCTAssertFalse(store.state.showOnboarding)
        XCTAssertFalse(store.state.showMainApp)
        
        // Step 2: User completes intro animations
        await store.send(.onboardingIntro(.delegate(.introCompleted))) {
            $0.authState.hasCompletedIntro = true
        }
        
        // After intro completion - should show onboarding questions
        XCTAssertFalse(store.state.showOnboardingIntro)
        XCTAssertFalse(store.state.showLogin)
        XCTAssertTrue(store.state.showOnboarding)
        XCTAssertFalse(store.state.showMainApp)
        
        // Step 3: User completes onboarding
        let mockPreferences = OnboardingPreferences()
        await store.send(.onboarding(.delegate(.onboardingCompleted(mockPreferences)))) {
            $0.authState.hasCompletedOnboarding = true
        }
        
        // After onboarding completion - should show main app
        XCTAssertFalse(store.state.showOnboardingIntro)
        XCTAssertFalse(store.state.showLogin)
        XCTAssertFalse(store.state.showOnboarding)
        XCTAssertTrue(store.state.showMainApp)
    }
    
    func testIntroCompletedDoesNotReappear() async {
        // Start with user who just created account
        let initialState = AppFeature.State(
            authState: AuthState(
                hasCompletedIntro: false,
                hasCompletedOnboarding: false,
                isLoggedIn: true
            )
        )
        
        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.authState = .testValue
            $0.onboarding = .testValue
        }
        
        // Should show intro
        XCTAssertTrue(store.state.showOnboardingIntro)
        
        // Complete intro
        await store.send(.onboardingIntro(.delegate(.introCompleted))) {
            $0.authState.hasCompletedIntro = true
        }
        
        // Should now show onboarding, NOT intro
        XCTAssertFalse(store.state.showOnboardingIntro)
        XCTAssertTrue(store.state.showOnboarding)
        
        // Simulate any potential state updates that might cause reversion
        // This test ensures intro doesn't reappear after completion
        XCTAssertFalse(store.state.showOnboardingIntro, "Intro should not reappear after completion")
    }
    
    func testStateComputedPropertiesLogic() {
        // Test all possible state combinations
        
        // Brand new user (not logged in, no intro, no onboarding)
        var state = AppFeature.State(
            authState: AuthState(
                hasCompletedIntro: false,
                hasCompletedOnboarding: false,
                isLoggedIn: false
            )
        )
        
        XCTAssertTrue(state.showOnboardingIntro)
        XCTAssertFalse(state.showLogin)
        XCTAssertFalse(state.showOnboarding)
        XCTAssertFalse(state.showMainApp)
        
        // User completed intro but not logged in
        state.authState.hasCompletedIntro = true
        
        XCTAssertFalse(state.showOnboardingIntro)
        XCTAssertTrue(state.showLogin)
        XCTAssertFalse(state.showOnboarding)
        XCTAssertFalse(state.showMainApp)
        
        // User logged in but hasn't completed onboarding
        state.authState.isLoggedIn = true
        
        XCTAssertFalse(state.showOnboardingIntro)
        XCTAssertFalse(state.showLogin)
        XCTAssertTrue(state.showOnboarding)
        XCTAssertFalse(state.showMainApp)
        
        // User completed everything
        state.authState.hasCompletedOnboarding = true
        
        XCTAssertFalse(state.showOnboardingIntro)
        XCTAssertFalse(state.showLogin)
        XCTAssertFalse(state.showOnboarding)
        XCTAssertTrue(state.showMainApp)
        
        // New user after account creation (the problematic case)
        state = AppFeature.State(
            authState: AuthState(
                hasCompletedIntro: false,  // Should see intro
                hasCompletedOnboarding: false,
                isLoggedIn: true
            )
        )
        
        XCTAssertTrue(state.showOnboardingIntro, "New logged-in user should see intro animations")
        XCTAssertFalse(state.showLogin)
        XCTAssertFalse(state.showOnboarding)
        XCTAssertFalse(state.showMainApp)
    }
    
    func testOnboardingCompletedTransition() async {
        // Start with user who completed intro and is in onboarding
        let initialState = AppFeature.State(
            authState: AuthState(
                hasCompletedIntro: true,
                hasCompletedOnboarding: false,
                isLoggedIn: true
            )
        )
        
        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.authState = .testValue
            $0.onboarding = .testValue
        }
        
        // Should show onboarding
        XCTAssertTrue(store.state.showOnboarding)
        
        // Complete onboarding
        let mockPreferences = OnboardingPreferences()
        await store.send(.onboarding(.delegate(.onboardingCompleted(mockPreferences)))) {
            $0.authState.hasCompletedOnboarding = true
        }
        
        // Should now show main app
        XCTAssertFalse(store.state.showOnboardingIntro)
        XCTAssertFalse(store.state.showLogin)
        XCTAssertFalse(store.state.showOnboarding)
        XCTAssertTrue(store.state.showMainApp)
    }
    
    func testExistingUserSignIn() async {
        // Test existing user who has completed intro before
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.authState = .testValue
        }
        
        // Simulate loading existing user state with completed intro
        await store.send(.authStateLoaded(AuthState(
            hasCompletedIntro: true,
            hasCompletedOnboarding: true,
            isLoggedIn: false
        ))) {
            $0.authState = AuthState(
                hasCompletedIntro: true,
                hasCompletedOnboarding: true,
                isLoggedIn: false
            )
        }
        
        // Should show login (not intro)
        XCTAssertFalse(store.state.showOnboardingIntro)
        XCTAssertTrue(store.state.showLogin)
        XCTAssertFalse(store.state.showOnboarding)
        XCTAssertFalse(store.state.showMainApp)
        
        // User signs in
        await store.send(.signIn(.delegate(.signedIn))) {
            $0.authState.isLoggedIn = true
            $0.authFlow = .login
        }
        
        // Should go directly to main app (skip intro and onboarding)
        XCTAssertFalse(store.state.showOnboardingIntro)
        XCTAssertFalse(store.state.showLogin)
        XCTAssertFalse(store.state.showOnboarding)
        XCTAssertTrue(store.state.showMainApp)
    }
    
    // MARK: - Edge Case Tests
    
    func testResetOnboarding() async {
        // Start with completed user
        let initialState = AppFeature.State(
            authState: AuthState(
                hasCompletedIntro: true,
                hasCompletedOnboarding: true,
                isLoggedIn: true
            )
        )
        
        let store = TestStore(initialState: initialState) {
            AppFeature()
        } withDependencies: {
            $0.authState = .testValue
        }
        
        // Should show main app
        XCTAssertTrue(store.state.showMainApp)
        
        // Reset onboarding
        await store.send(.resetOnboarding) {
            $0.authState = AuthState.initial
        }
        
        // Should show intro again
        XCTAssertTrue(store.state.showOnboardingIntro)
        XCTAssertFalse(store.state.showMainApp)
    }
}

// MARK: - Test Dependencies

extension AuthStateClient {
    static let testValue = Self(
        load: { AuthState.initial },
        save: { _ in },
        markIntroCompleted: { },
        markOnboardingCompleted: { },
        markLoggedIn: { _ in },
        reset: { }
    )
}

extension OnboardingClient {
    static let testValue = Self(
        load: { OnboardingPreferences() },
        save: { _ in },
        clear: { }
    )
}