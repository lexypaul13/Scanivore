//
//  OnboardingFlowTests.swift
//  ScanivoreTests
//
//  Simple unit tests to verify the onboarding flow works correctly
//

import XCTest
import ComposableArchitecture
@testable import Scanivore

@MainActor
final class OnboardingFlowTests: XCTestCase {
    
    func testNewUserFlowStateTransitions() {
        // Test the computed properties that control the UI flow
        
        // 1. New user after account creation
        var state = AppFeature.State(
            authState: AuthState(
                hasCompletedIntro: false,
                hasCompletedOnboarding: false,
                isLoggedIn: true
            )
        )
        
        // Should show intro animations
        XCTAssertTrue(state.showOnboardingIntro, "New user should see intro animations")
        XCTAssertFalse(state.showLogin, "Should not show login")
        XCTAssertFalse(state.showOnboarding, "Should not show onboarding yet")
        XCTAssertFalse(state.showMainApp, "Should not show main app yet")
        
        // 2. After completing intro animations
        state.authState.hasCompletedIntro = true
        
        // Should show onboarding questions
        XCTAssertFalse(state.showOnboardingIntro, "Should not show intro after completion")
        XCTAssertFalse(state.showLogin, "Should not show login")
        XCTAssertTrue(state.showOnboarding, "Should show onboarding questions")
        XCTAssertFalse(state.showMainApp, "Should not show main app yet")
        
        // 3. After completing onboarding
        state.authState.hasCompletedOnboarding = true
        
        // Should show main app
        XCTAssertFalse(state.showOnboardingIntro, "Should not show intro")
        XCTAssertFalse(state.showLogin, "Should not show login")
        XCTAssertFalse(state.showOnboarding, "Should not show onboarding after completion")
        XCTAssertTrue(state.showMainApp, "Should show main app")
    }
    
    func testIntroDoesNotReappearAfterCompletion() {
        // Test that once intro is completed, it never reappears
        var state = AppFeature.State(
            authState: AuthState(
                hasCompletedIntro: true,  // Already completed
                hasCompletedOnboarding: false,
                isLoggedIn: true
            )
        )
        
        // Should be in onboarding, not intro
        XCTAssertFalse(state.showOnboardingIntro, "Intro should not reappear after completion")
        XCTAssertTrue(state.showOnboarding, "Should be in onboarding phase")
        
        // Even if we modify other state, intro should not reappear
        state.selectedTab = 1
        XCTAssertFalse(state.showOnboardingIntro, "Intro should not reappear on tab change")
        
        state.authFlow = .createAccount
        XCTAssertFalse(state.showOnboardingIntro, "Intro should not reappear on auth flow change")
    }
    
    func testExistingUserDoesNotSeeIntro() {
        // Test existing user who has already completed everything
        let state = AppFeature.State(
            authState: AuthState(
                hasCompletedIntro: true,
                hasCompletedOnboarding: true,
                isLoggedIn: false  // Signed out
            )
        )
        
        // Should see login, not intro
        XCTAssertFalse(state.showOnboardingIntro, "Existing user should not see intro")
        XCTAssertTrue(state.showLogin, "Should see login")
        XCTAssertFalse(state.showOnboarding, "Should not see onboarding")
        XCTAssertFalse(state.showMainApp, "Should not see main app when signed out")
    }
    
    func testBrandNewUserSeeIntro() {
        // Test completely new user (fresh install)
        let state = AppFeature.State()  // All defaults are false
        
        // Should see intro first
        XCTAssertTrue(state.showOnboardingIntro, "Brand new user should see intro")
        XCTAssertFalse(state.showLogin, "Should not see login")
        XCTAssertFalse(state.showOnboarding, "Should not see onboarding")
        XCTAssertFalse(state.showMainApp, "Should not see main app")
    }
}