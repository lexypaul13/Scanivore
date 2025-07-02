//
//  SharedKeys.swift
//  Scanivore
//
//  Shared state keys for TCA features
//

import Foundation
import ComposableArchitecture

// MARK: - Shared Keys for Onboarding
extension SharedReaderKey where Self == AppStorageKey<OnboardingPreferences?>.Default {
    static var onboardingPreferences: Self {
        Self[.appStorage("onboardingPreferences"), default: nil]
    }
}

extension SharedReaderKey where Self == AppStorageKey<Bool>.Default {
    static var hasCompletedOnboarding: Self {
        Self[.appStorage("hasCompletedOnboarding"), default: false]
    }
}

// MARK: - Shared Keys for Settings
extension SharedReaderKey where Self == AppStorageKey<Bool>.Default {
    static var enableNotifications: Self {
        Self[.appStorage("enableNotifications"), default: true]
    }
    
    static var autoSaveScans: Self {
        Self[.appStorage("autoSaveScans"), default: true]
    }
    
    static var useMetricUnits: Self {
        Self[.appStorage("useMetricUnits"), default: false]
    }
}

extension SharedReaderKey where Self == AppStorageKey<String>.Default {
    static var scanQuality: Self {
        Self[.appStorage("scanQuality"), default: "high"]
    }
} 