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
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: Self.store)
            // SplashView() // Uncomment to test splash screen
        }
    }
}
