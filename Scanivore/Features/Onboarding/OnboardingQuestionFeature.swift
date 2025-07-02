//
//  OnboardingQuestionFeature.swift
//  Scanivore
//
//  TCA feature for individual onboarding questions
//

import Foundation
import ComposableArchitecture

// MARK: - Question Data Model
struct OnboardingQuestion: Equatable {
    let id: Int
    let title: String
    let subtitle: String
}

// MARK: - OnboardingQuestion Feature
@Reducer
struct OnboardingQuestionFeature {
    @ObservableState
    struct State: Equatable {
        let question: OnboardingQuestion
    }
    
    enum Action {
        case answerTapped(Bool)
        case delegate(Delegate)
        
        enum Delegate {
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