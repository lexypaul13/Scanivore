//
//  DisclaimerView.swift
//  Scanivore
//
//  Disclaimer view with AI limitations and privacy information
//

import SwiftUI
import ComposableArchitecture

struct DisclaimerView: View {
    public init(store: StoreOf<DisclaimerFeature>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<DisclaimerFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        DisclaimerHeader()
                        DisclaimerSections(store: store)
                    }
                    .padding(DesignSystem.Spacing.screenPadding)
                }
            }
            .customNavigationTitle("Disclaimer")
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

// MARK: - Disclaimer Header
private struct DisclaimerHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Text("Disclaimer")
                .font(DesignSystem.Typography.hero)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Important information about Scanivore's capabilities")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Disclaimer Sections
private struct DisclaimerSections: View {
    let store: StoreOf<DisclaimerFeature>
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            DisclaimerSection(
                title: "AI Limitations",
                content: "Our AI-powered analysis is continuously improving. While we strive for accuracy, results may have limitations. We're actively working on adding citations to support our assessments."
            )
            
            DisclaimerSection(
                title: "Privacy",
                content: "Your privacy is our priority. No personal data is collected or stored on our servers. All analysis is performed locally on your device."
            )
            
            ContactSection(store: store)
        }
        .font(DesignSystem.Typography.body)
    }
}

// MARK: - Disclaimer Section
private struct DisclaimerSection: View {
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

// MARK: - Contact Section
private struct ContactSection: View {
    let store: StoreOf<DisclaimerFeature>
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Contact")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
                Text("If you have questions or concerns about our analysis or privacy practices, please contact us:")
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(nil)
                
                Link(destination: URL(string: "mailto:lexypaul14@gmail.com")!) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "envelope")
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                        Text("lexypaul14@gmail.com")
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
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
    DisclaimerView(
        store: Store(initialState: DisclaimerFeature.State()) {
            DisclaimerFeature()
        }
    )
}