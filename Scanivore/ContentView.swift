//
//  ContentView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                ScannerView()
                    .tabItem {
                        Label("Scan", systemImage: "camera.fill")
                    }
                    .tag(0)
                
                ExploreView()
                    .tabItem {
                        Label("Explore", systemImage: "star.fill")
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

#Preview {
    ContentView()
}
