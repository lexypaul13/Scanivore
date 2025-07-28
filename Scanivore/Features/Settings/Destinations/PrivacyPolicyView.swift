//
//  PrivacyPolicyView.swift
//  Scanivore
//
//  Privacy policy view with data usage information
//

import SwiftUI
import ComposableArchitecture

struct PrivacyPolicyView: View {
    public init(store: StoreOf<PrivacyFeature>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<PrivacyFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        PolicyHeader(lastUpdated: store.lastUpdated)
                        PolicySections()
                    }
                    .padding(DesignSystem.Spacing.screenPadding)
                }
            }
            .customNavigationTitle("Privacy Policy")
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

// MARK: - Policy Header
private struct PolicyHeader: View {
    let lastUpdated: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Privacy Policy")
                .font(DesignSystem.Typography.hero)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Last updated: \(lastUpdated)")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Policy Sections
private struct PolicySections: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            PolicySection(
                title: "Data Collection",
                content: "Scanivore collects minimal data necessary to provide meat analysis services. This includes images of meat products and associated metadata."
            )
            
            PolicySection(
                title: "Data Usage",
                content: "Your data is used solely for analysis purposes and improving our AI models. We never sell or share your personal information."
            )
            
            PolicySection(
                title: "Data Storage",
                content: "All data is stored locally on your device. Cloud sync is optional and requires explicit consent."
            )
            
            PolicySection(
                title: "Your Rights",
                content: "You can delete all your data at any time through the Settings menu. You have the right to export your data in a portable format."
            )
        }
        .font(DesignSystem.Typography.body)
    }
}

// MARK: - Policy Section
private struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(content)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(nil)
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
    PrivacyPolicyView(
        store: Store(initialState: PrivacyFeature.State()) {
            PrivacyFeature()
        }
    )
}