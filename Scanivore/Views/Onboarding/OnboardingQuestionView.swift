//
//  OnboardingQuestionView.swift
//  Scanivore
//
//  View for yes/no onboarding questions
//

import SwiftUI

struct OnboardingQuestionView: View {
    let question: OnboardingQuestion
    let onAnswer: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Question
                Text(question.title)
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                
                // Subtitle
                Text(question.subtitle)
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
                    action: { onAnswer(true) }
                )
                
                AnswerButton(
                    title: "No",
                    isPositive: false,
                    action: { onAnswer(false) }
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            .padding(.bottom, DesignSystem.Spacing.xxxxxl)
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
        question: OnboardingQuestion(
            id: 1,
            title: "Avoid artificial preservatives?",
            subtitle: "We'll help you find products without synthetic additives"
        ),
        onAnswer: { _ in }
    )
}