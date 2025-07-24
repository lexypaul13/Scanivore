//
//  ContentView.swift
//  Scanivore
//
//  Main TCA-powered content view
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if store.isShowingLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                } else if store.showOnboardingIntro {
                    OnboardingIntroView(
                        store: store.scope(state: \.onboardingIntro, action: \.onboardingIntro)
                    )
                    .transition(.move(edge: .trailing))
                } else if store.showLogin {
                    LoginView(
                        store: store.scope(state: \.login, action: \.login)
                    )
                    .transition(.move(edge: .trailing))
                } else if store.showCreateAccount {
                    CreateAccountView(
                        store: store.scope(state: \.createAccount, action: \.createAccount)
                    )
                    .transition(.move(edge: .trailing))
                } else if store.showSignIn {
                    SignInView(
                        store: store.scope(state: \.signIn, action: \.signIn)
                    )
                    .transition(.move(edge: .trailing))
                } else if store.showOnboarding {
                    OnboardingView(
                        store: store.scope(state: \.onboarding, action: \.onboarding)
                    )
                    .transition(.move(edge: .trailing))
                } else {
                    MainTabView(store: store)
                }
            }
        }
    }
}

struct MainTabView: View {
    let store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            TabView(selection: .init(
                get: { store.selectedTab },
                set: { store.send(.tabSelected($0)) }
            )) {
                ExploreView(
                    store: store.scope(state: \.explore, action: \.explore)
                )
                    .tabItem {
                        Label("Explore", systemImage: "star.fill")
                    }
                    .tag(0)

                ScannerView(
                    store: store.scope(state: \.scanner, action: \.scanner)
                )
                    .tabItem {
                        Label("Scan", systemImage: "camera.fill")
                    }
                    .tag(1)
                
                HistoryView(
                    store: store.scope(state: \.history, action: \.history)
                )
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
    ContentView(
        store: Store(
            initialState: AppFeature.State()
        ) {
            AppFeature()
        }
    )
}

#Preview("With Onboarding") {
    ContentView(
        store: Store(
            initialState: AppFeature.State()
        ) {
            AppFeature()
        }
    )
    .onAppear {
        // Reset onboarding for preview
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}
