//
//  ScanivoreApp.swift
//  Scanivore
//
//  Main TCA application entry point
//

import SwiftUI
import ComposableArchitecture

@main
struct ScanivoreApp: App {
    static let store = Store(
        initialState: AppFeature.State()
    ) {
        AppFeature()
    }
    
    init() {
        // Uncomment to reset onboarding for testing
        // resetOnboarding()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: Self.store)
                .onAppear {
                    Self.store.send(.appDidLaunch)
                    // Uncomment to reset onboarding for testing
                    // Self.store.send(.resetOnboarding)
                }
        }
    }
}
