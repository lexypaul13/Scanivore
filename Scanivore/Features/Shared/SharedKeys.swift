
import Foundation

// MARK: - Deprecated UserDefaults Keys

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
