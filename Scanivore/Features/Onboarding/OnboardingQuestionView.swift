//
//  OnboardingQuestionView.swift
//  Scanivore
//
//  TCA view for individual onboarding questions
//

import SwiftUI
import ComposableArchitecture

struct OnboardingQuestionView: View {
    let store: StoreOf<OnboardingQuestionFeature>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Question
                    Text(store.question.title)
                        .font(DesignSystem.Typography.heading1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                    // Subtitle
                    Text(store.question.subtitle)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xxxl)
                }
                
                Spacer()
                
                // Answer Buttons
                VStack(spacing: DesignSystem.Spacing.base) {
                    AnswerButton(
                        title: "Yes",
                        isPositive: true,
                        action: { store.send(.answerTapped(true)) }
                    )
                    
                    AnswerButton(
                        title: "No",
                        isPositive: false,
                        action: { store.send(.answerTapped(false)) }
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                .padding(.bottom, DesignSystem.Spacing.xxxxxl)
            }
        }
    }
}

struct AnswerButton: View {
    let title: String
    let isPositive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.buttonText)
                .foregroundColor(isPositive ? .white : DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .fill(isPositive ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                                .stroke(isPositive ? Color.clear : DesignSystem.Colors.border, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OnboardingQuestionView(
        store: Store(
            initialState: OnboardingQuestionFeature.State(
                question: OnboardingQuestion.questions[0]
            )
        ) {
            OnboardingQuestionFeature()
        }
    )
} 