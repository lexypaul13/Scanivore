//
//  ContentView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .transition(.move(edge: .trailing))
            } else {
                TabView(selection: $selectedTab) {
                    
                    ExploreView()
                        .tabItem {
                            Label("Explore", systemImage: "star.fill")
                        }
                        .tag(0)

                    ScannerView()
                        .tabItem {
                            Label("Scan", systemImage: "camera.fill")
                        }
                        .tag(1)
                    
                    
                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock.fill")
                        }
                        .tag(2)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(3)
                    
                }
                .tint(DesignSystem.Colors.primaryRed)
            }
        }
    }
}

#Preview {
    ContentView()
}

#Preview("With Onboarding") {
    ContentView()
        .onAppear {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
}
