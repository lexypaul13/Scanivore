# Onboarding Integration

## Overview
The Scanivore app now includes a two-part onboarding flow:

1. **Introduction Screens** - Three pages explaining the app's core features
2. **Dietary Preferences** - User questionnaire for personalized recommendations

## Integration

The onboarding flow is automatically shown on first app launch. Add `OnboardingIntroView(store:)` and `OnboardingView(store:)` at app launch if `!user.didFinishOnboarding`.

```swift
// In ContentView.swift
if store.showOnboardingIntro {
    OnboardingIntroView(store: store.scope(state: \.onboardingIntro, action: \.onboardingIntro))
} else if store.showOnboarding {
    OnboardingView(store: store.scope(state: \.onboarding, action: \.onboarding))
} else {
    MainTabView(store: store)
}
```

## Features
- TCA-compliant architecture
- Design system integration
- Smooth page transitions
- Skip functionality
- Proper state persistence