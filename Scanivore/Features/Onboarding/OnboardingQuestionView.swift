//
//  OnboardingQuestionView.swift
//  Scanivore
//
//  TCA view for individual onboarding questions
//

import SwiftUI
import ComposableArchitecture

// MARK: - Question Data Model
struct OnboardingQuestion: Equatable {
    let id: Int
    let title: String
    let subtitle: String
}

// MARK: - OnboardingQuestion Feature Domain
@Reducer
struct OnboardingQuestionFeatureDomain: Equatable {
    @ObservableState
    struct State: Equatable {
        let question: OnboardingQuestion
    }
    
    enum Action: Equatable {
        case answerTapped(Bool)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case questionAnswered(questionId: Int, answer: Bool)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .answerTapped(answer):
                return .run { [questionId = state.question.id] send in
                    await send(.delegate(.questionAnswered(questionId: questionId, answer: answer)))
                }
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Question Data
extension OnboardingQuestion {
    static let questions = [
        OnboardingQuestion(
            id: 1,
            title: "Avoid artificial preservatives?",
            subtitle: "We'll help you find products without synthetic additives"
        ),
        OnboardingQuestion(
            id: 2,
            title: "Is antibiotic-free important?",
            subtitle: "Identify meat raised without antibiotics"
        ),
        OnboardingQuestion(
            id: 3,
            title: "Do you prefer organic or grass-fed meat?",
            subtitle: "Find products that meet your standards"
        ),
        OnboardingQuestion(
            id: 4,
            title: "Avoid added sugars?",
            subtitle: "We'll flag products with added sweeteners"
        ),
        OnboardingQuestion(
            id: 5,
            title: "Avoid flavor enhancers (MSG)?",
            subtitle: "Identify products with natural flavoring only"
        ),
        OnboardingQuestion(
            id: 6,
            title: "Interested in lower sodium?",
            subtitle: "Find options with reduced salt content"
        )
    ]
}

struct OnboardingQuestionView: View {
    let store: StoreOf<OnboardingQuestionFeatureDomain>
    
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
            initialState: OnboardingQuestionFeatureDomain.State(
                question: OnboardingQuestion.questions[0]
            )
        ) {
            OnboardingQuestionFeatureDomain()
        }
    )
}
