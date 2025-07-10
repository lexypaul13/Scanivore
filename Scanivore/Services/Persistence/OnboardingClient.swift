//
//  OnboardingClient.swift
//  Scanivore
//
//  TCA-compliant onboarding preferences client
//

import Foundation
import Dependencies
import ComposableArchitecture

// Note: OnboardingPreferences is defined in Models/OnboardingPreferences.swift

// MARK: - Onboarding Client
@DependencyClient
public struct OnboardingClient: Sendable {
    public var load: @Sendable () async -> OnboardingPreferences? = { nil }
    public var save: @Sendable (OnboardingPreferences) async -> Void
    public var clear: @Sendable () async -> Void
}

// MARK: - Dependency Key Conformance
extension OnboardingClient: DependencyKey {
    public static let liveValue: Self = .init(
        load: {
            @Dependency(\.userDefaults) var userDefaults
            
            guard let data = await userDefaults.getData("onboardingPreferences") else {
                return nil
            }
            
            return try? JSONDecoder().decode(OnboardingPreferences.self, from: data)
        },
        save: { preferences in
            @Dependency(\.userDefaults) var userDefaults
            
            let data = try? JSONEncoder().encode(preferences)
            await userDefaults.setData("onboardingPreferences", data)
        },
        clear: {
            @Dependency(\.userDefaults) var userDefaults
            await userDefaults.remove("onboardingPreferences")
        }
    )
    
    public static let testValue = Self(
        load: { nil },
        save: { _ in },
        clear: { }
    )
    
    public static let previewValue = Self(
        load: { nil },
        save: { _ in },
        clear: { }
    )
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var onboarding: OnboardingClient {
        get { self[OnboardingClient.self] }
        set { self[OnboardingClient.self] = newValue }
    }
}