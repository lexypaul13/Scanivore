//
//  OnboardingView.swift
//  Scanivore
//
//  Main TCA onboarding flow with navigation stack
//

import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStackStore(store.scope(state: \.path, action: \.path)) {
                OnboardingRootView(store: store)
            } destination: { destinationStore in
                switch destinationStore.case {
                case let .question(questionStore):
                    OnboardingQuestionView(store: questionStore)
                case let .meatSelection(meatSelectionStore):
                    MeatSelectionView(store: meatSelectionStore)
                }
            }
            .onAppear {
                store.send(.startOnboarding)
            }
        }
    }
}

struct OnboardingRootView: View {
    let store: StoreOf<OnboardingFeature>
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar
                    ProgressBar(
                        current: store.currentStep,
                        total: store.totalSteps,
                        progress: store.progress
                    )
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    .padding(.top, DesignSystem.Spacing.sm)
                    
                    // Content area - this will be filled by the navigation stack
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if store.canGoBack {
                        Button(action: { store.send(.backButtonTapped) }) {
                            Image(systemName: "chevron.left")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(DesignSystem.Colors.backgroundSecondary)
                                )
                        }
                    }
                }
            }
        }
    }
}

struct ProgressBar: View {
    let current: Int
    let total: Int
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignSystem.Colors.primaryRed)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    OnboardingView(
        store: Store(
            initialState: OnboardingFeature.State()
        ) {
            OnboardingFeature()
        }
    )
} 