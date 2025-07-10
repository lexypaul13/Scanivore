# TCA Persistence Migration Guide

## Overview

This directory contains TCA-compliant persistence clients that replace direct UserDefaults usage throughout the Scanivore app. This migration provides better testability, type safety, and follows TCA architectural patterns.

## New Persistence Clients

### 1. UserDefaultsClient
**File:** `UserDefaultsClient.swift`  
**Purpose:** Low-level UserDefaults abstraction for TCA  
**Usage:** Base client for other persistence clients

```swift
@Dependency(\.userDefaults) var userDefaults
let value = await userDefaults.getBool("someKey")
await userDefaults.setBool("someKey", true)
```

### 2. AuthStateClient
**File:** `AuthStateClient.swift`  
**Purpose:** Manages authentication-related state persistence  
**Replaces:** Direct UserDefaults calls for auth flags

```swift
@Dependency(\.authState) var authState
let state = await authState.load()
await authState.markLoggedIn(true)
await authState.markOnboardingCompleted()
```

### 3. SettingsClient
**File:** `SettingsClient.swift`  
**Purpose:** Manages app settings and user preferences  
**Replaces:** @AppStorage properties

```swift
@Dependency(\.settings) var settings
let appSettings = await settings.load()
await settings.save(updatedSettings)
```

### 4. OnboardingClient
**File:** `OnboardingClient.swift`  
**Purpose:** Manages onboarding preferences persistence  
**Replaces:** Custom UserDefaults extensions

```swift
@Dependency(\.onboarding) var onboarding
let preferences = await onboarding.load()
await onboarding.save(newPreferences)
```

## Migration Changes Made

### AppFeature.swift
- ✅ Replaced direct UserDefaults initialization with AuthState loading
- ✅ Added `appDidLaunch` action to load persisted state
- ✅ Updated all auth state mutations to use AuthStateClient
- ✅ Maintained existing computed properties for backwards compatibility

### AuthGateway.swift
- ✅ Removed direct UserDefaults calls for auth token flag
- ✅ Simplified token storage to rely only on TokenManager
- ✅ Made isLoggedIn async to properly check token existence
- ✅ Removed debug print statements

### ScanivoreApp.swift
- ✅ Added `appDidLaunch` trigger on app start
- ✅ Kept legacy reset function with migration note

### SharedKeys.swift
- ✅ Marked as deprecated with clear migration path
- ✅ Added comprehensive migration documentation
- ✅ Kept keys for backwards compatibility during transition

## Benefits of TCA Persistence

### 1. **Better Testability**
- All persistence operations are dependency-injected
- Easy to mock for unit tests
- Predictable state management

### 2. **Type Safety**
- Strongly-typed preference models
- Compile-time validation of persistence operations
- Reduced runtime errors

### 3. **TCA Compliance**
- All state changes go through reducers
- Proper effect management
- Clean separation of concerns

### 4. **Maintainability**
- Centralized persistence logic
- Clear data models
- Easier to refactor and extend

## Usage Examples

### Loading App State on Launch
```swift
case .appDidLaunch:
    return .run { send in
        @Dependency(\.authState) var authState
        let state = await authState.load()
        await send(.authStateLoaded(state))
    }
```

### Saving Settings
```swift
case .settingChanged(let newSettings):
    return .run { _ in
        @Dependency(\.settings) var settings
        await settings.save(newSettings)
    }
```

### Managing Onboarding
```swift
case .onboardingCompleted(let preferences):
    return .run { _ in
        @Dependency(\.onboarding) var onboarding
        @Dependency(\.authState) var authState
        
        await onboarding.save(preferences)
        await authState.markOnboardingCompleted()
    }
```

## Testing Support

All clients include:
- `testValue`: Empty implementations for unit tests
- `previewValue`: Safe implementations for SwiftUI previews
- Dependency injection for easy mocking

## Migration Checklist

- ✅ Created all TCA persistence clients
- ✅ Updated AppFeature to use AuthStateClient
- ✅ Updated AuthGateway to remove UserDefaults
- ✅ Marked legacy code as deprecated
- ⏳ Update any remaining @AppStorage usage (if found)
- ⏳ Update any remaining direct UserDefaults calls
- ⏳ Add tests for persistence clients
- ⏳ Eventually remove deprecated SharedKeys.swift

## Future Considerations

1. **Migration Helper**: Consider adding a one-time migration effect to transfer existing UserDefaults data to new format
2. **Persistence Layer**: Could extend to use Core Data, SQLite, or other storage backends
3. **Sync Support**: Could add iCloud sync capabilities in the future
4. **Performance**: File-based storage could be optimized for frequent reads/writes

This migration establishes a solid foundation for scalable, testable persistence in the Scanivore app while maintaining TCA architectural principles.