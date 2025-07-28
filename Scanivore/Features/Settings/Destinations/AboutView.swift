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
        Image("Scanivore_Logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
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