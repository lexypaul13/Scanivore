# Settings Authentication Test Instructions

## Current Status

✅ **Working Endpoints:**
- `/api/v1/auth/register` - Creates accounts with full_name
- `/api/v1/auth/login` - Returns access tokens
- `/api/v1/auth/logout` - Configured in AuthGateway
- `/api/v1/auth/account` (DELETE) - Configured in AuthGateway

⚠️ **Backend Issue:**
- `/api/v1/users/me` - Returns 500 error (needs backend fix)

## Test Account Created

```
Email: test_settings_013352@example.com
Password: TestPass123!
Full Name: John Settings Test
```

## Steps to Test Settings in iOS App

### 1. Revert Temporary Code Changes

**In `AppFeature.swift` (line ~35):**
```swift
// Change from:
var settings = SettingsFeature.State(
    isSignedIn: true,  // TEMPORARY: For testing Sign Out/Delete buttons
    userName: "Test User",
    userEmail: "test@example.com"
)

// Back to:
var settings = SettingsFeature.State()
```

**In `SettingsView.swift` (line ~260):**
```swift
// Uncomment:
.onAppear {
    store.send(.onAppear)
}
```

### 2. Run the App

1. Build and run in Xcode
2. Login with the test credentials above
3. Navigate to Settings tab

### 3. Expected Behavior

**If `/users/me` is fixed:**
- Shows "John Settings Test" as the name
- Shows email below the name
- Shows "Account" section with Sign Out/Delete buttons

**Current behavior (with 500 error):**
- Shows "Guest User" (because getCurrentUser returns nil)
- No Account section visible
- This is correct behavior for error handling

## Debugging Tips

1. Check Xcode console for "Settings onAppear triggered" message
2. Look for any network error logs
3. You can temporarily hardcode successful user data in AuthGateway.getCurrentUser to test UI

## Alternative Test Method

If you want to test the UI without fixing the backend, in `AuthGateway.swift`, temporarily modify getCurrentUser:

```swift
getCurrentUser: {
    // Temporary mock for testing
    return User(
        id: "test-123",
        email: "test@example.com",
        fullName: "Test User",
        isActive: true,
        preferences: nil
    )
}
```

This will show the Sign Out/Delete buttons without needing the backend fixed.