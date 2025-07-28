//
//  AboutView.swift
//  Scanivore
//
//  About view for app information and credits
//

import SwiftUI
import ComposableArchitecture

struct AboutView: View {
    public init(store: StoreOf<AboutFeature>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<AboutFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xxxl) {
                        Spacer()
                        
                        AppIcon()
                        AppInfo(store: store)
                        ExternalLinks()
                        
                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.screenPadding)
                }
            }
            .customNavigationTitle("About")
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DismissButton()
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - App Icon
private struct AppIcon: View {
    var body: some View {
        Image(systemName: "camera.metering.center.weighted")
            .font(.system(size: 80))
            .foregroundColor(DesignSystem.Colors.primaryRed)
    }
}

// MARK: - App Info
private struct AppInfo: View {
    let store: StoreOf<AboutFeature>
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Scanivore")
                    .font(DesignSystem.Typography.hero)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("AI-Powered Meat Analysis")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            VStack(spacing: DesignSystem.Spacing.base) {
                Text("Version \(store.appVersion) (\(store.buildNumber))")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(store.copyright)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - External Links
private struct ExternalLinks: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ExternalLink(
                title: "Terms of Service",
                url: "https://scanivore.app/terms"
            )
            
            ExternalLink(
                title: "Privacy Policy",
                url: "https://scanivore.app/privacy"
            )
            
            ExternalLink(
                title: "Acknowledgments",
                url: "https://scanivore.app/credits"
            )
        }
        .font(DesignSystem.Typography.body)
    }
}

// MARK: - External Link
private struct ExternalLink: View {
    let title: String
    let url: String
    
    var body: some View {
        Link(title, destination: URL(string: url)!)
            .foregroundColor(DesignSystem.Colors.primaryRed)
    }
}

// MARK: - Dismiss Button
private struct DismissButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button("Done") {
            dismiss()
        }
        .foregroundColor(DesignSystem.Colors.primaryRed)
    }
}

#Preview {
    AboutView(
        store: Store(initialState: AboutFeature.State()) {
            AboutFeature()
        }
    )
}