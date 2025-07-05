//
//  SharedKeys.swift
//  Scanivore
//
//  Shared state keys for TCA features - Simplified approach
//

import Foundation
import ComposableArchitecture

// MARK: - UserDefaults Keys
enum UserDefaultsKeys {
    static let hasCompletedIntro = "hasCompletedIntro"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let onboardingPreferences = "onboardingPreferences"
    static let enableNotifications = "enableNotifications"
    static let autoSaveScans = "autoSaveScans"
    static let useMetricUnits = "useMetricUnits"
    static let scanQuality = "scanQuality"
}

// MARK: - UserDefaults Helper
extension UserDefaults {
    func setOnboardingPreferences(_ preferences: OnboardingPreferences?) {
        if let preferences = preferences,
           let data = try? JSONEncoder().encode(preferences) {
            set(data, forKey: UserDefaultsKeys.onboardingPreferences)
        } else {
            removeObject(forKey: UserDefaultsKeys.onboardingPreferences)
        }
    }
    
    func getOnboardingPreferences() -> OnboardingPreferences? {
        guard let data = data(forKey: UserDefaultsKeys.onboardingPreferences),
              let preferences = try? JSONDecoder().decode(OnboardingPreferences.self, from: data) else {
            return nil
        }
        return preferences
    }
} 