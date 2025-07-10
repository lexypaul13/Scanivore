//
//  SharedKeys.swift
//  Scanivore
//
//  Legacy file - UserDefaults keys are now managed by TCA persistence clients
//  This file is kept for migration purposes and will be removed in future versions
//

import Foundation

// MARK: - Deprecated UserDefaults Keys
// These keys are now managed by TCA persistence clients:
// - UserDefaultsClient for low-level key-value storage
// - AuthStateClient for authentication state
// - SettingsClient for app settings
// - OnboardingClient for onboarding preferences

@available(*, deprecated, message: "Use TCA persistence clients instead")
enum UserDefaultsKeys {
    static let hasCompletedIntro = "hasCompletedIntro"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let isLoggedIn = "isLoggedIn"
    static let onboardingPreferences = "onboardingPreferences"
    static let enableNotifications = "enableNotifications"
    static let autoSaveScans = "autoSaveScans"
    static let useMetricUnits = "useMetricUnits"
    static let scanQuality = "scanQuality"
    static let freshnessAlerts = "freshnessAlerts"
    static let weeklyReports = "weeklyReports"
    static let priceAlerts = "priceAlerts"
    static let hasAuthToken = "has_auth_token"
}

// MARK: - Migration Notes
// These keys and methods have been replaced by TCA persistence clients:
//
// 1. AuthState management: Use @Dependency(\.authState) 
// 2. App settings: Use @Dependency(\.settings)
// 3. Onboarding preferences: Use @Dependency(\.onboarding)
// 4. Low-level UserDefaults: Use @Dependency(\.userDefaults)
//
// Benefits of TCA approach:
// - Better testability with dependency injection
// - Centralized state management
// - Type-safe persistence
// - Easier to mock for testing
// - Follows TCA architectural patterns 