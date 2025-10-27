
import Foundation
import Dependencies
import ComposableArchitecture

// MARK: - Auth State Models
public struct AuthState: Codable, Equatable {
    public var hasCompletedIntro: Bool
    public var hasCompletedOnboarding: Bool
    public var isLoggedIn: Bool
    
    public init(
        hasCompletedIntro: Bool = false,
        hasCompletedOnboarding: Bool = false,
        isLoggedIn: Bool = false
    ) {
        self.hasCompletedIntro = hasCompletedIntro
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isLoggedIn = isLoggedIn
    }
    
    public static let initial = AuthState()
}

// MARK: - Auth State Client
@DependencyClient
public struct AuthStateClient: Sendable {
    public var load: @Sendable () async -> AuthState = { .initial }
    public var save: @Sendable (AuthState) async -> Void
    public var markIntroCompleted: @Sendable () async -> Void
    public var markOnboardingCompleted: @Sendable () async -> Void
    public var markLoggedIn: @Sendable (Bool) async -> Void
    public var reset: @Sendable () async -> Void
}

// MARK: - Dependency Key Conformance
extension AuthStateClient: DependencyKey {
    public static let liveValue: Self = .init(
        load: {
            @Dependency(\.userDefaults) var userDefaults
            
            return AuthState(
                hasCompletedIntro: await userDefaults.getBool("hasCompletedIntro"),
                hasCompletedOnboarding: await userDefaults.getBool("hasCompletedOnboarding"),
                isLoggedIn: await userDefaults.getBool("isLoggedIn")
            )
        },
        save: { state in
            @Dependency(\.userDefaults) var userDefaults
            
            await userDefaults.setBool("hasCompletedIntro", state.hasCompletedIntro)
            await userDefaults.setBool("hasCompletedOnboarding", state.hasCompletedOnboarding)
            await userDefaults.setBool("isLoggedIn", state.isLoggedIn)
        },
        markIntroCompleted: {
            @Dependency(\.userDefaults) var userDefaults
            await userDefaults.setBool("hasCompletedIntro", true)
        },
        markOnboardingCompleted: {
            @Dependency(\.userDefaults) var userDefaults
            await userDefaults.setBool("hasCompletedOnboarding", true)
        },
        markLoggedIn: { isLoggedIn in
            @Dependency(\.userDefaults) var userDefaults
            await userDefaults.setBool("isLoggedIn", isLoggedIn)
        },
        reset: {
            @Dependency(\.userDefaults) var userDefaults
            
            await userDefaults.remove("hasCompletedIntro")
            await userDefaults.remove("hasCompletedOnboarding")
            await userDefaults.remove("isLoggedIn")
        }
    )
    
    public static let testValue = Self()
    
    public static let previewValue = Self()
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var authState: AuthStateClient {
        get { self[AuthStateClient.self] }
        set { self[AuthStateClient.self] = newValue }
    }
}
