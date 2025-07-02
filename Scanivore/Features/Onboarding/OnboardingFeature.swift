//
//  OnboardingFeature.swift
//  Scanivore
//
//  TCA feature for the main onboarding flow with navigation stack
//

import Foundation
import ComposableArchitecture

// MARK: - Onboarding Path
@Reducer
enum OnboardingPath {
    case question(OnboardingQuestionFeature)
    case meatSelection(MeatSelectionFeature)
}

// MARK: - Main Onboarding Feature
@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var path = StackState<OnboardingPath.State>()
        @Shared(.onboardingPreferences) var preferences = OnboardingPreferences()
        @Shared(.hasCompletedOnboarding) var hasCompleted = false
        
        var currentStep: Int {
            path.count + 1
        }
        
        var totalSteps: Int {
            OnboardingQuestion.questions.count + 1 // questions + meat selection
        }
        
        var progress: Double {
            Double(currentStep) / Double(totalSteps)
        }
        
        var canGoBack: Bool {
            !path.isEmpty
        }
    }
    
    enum Action {
        case path(StackActionOf<OnboardingPath>)
        case backButtonTapped
        case startOnboarding
        case delegate(Delegate)
        
        enum Delegate {
            case onboardingCompleted
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startOnboarding:
                // Start with first question
                if let firstQuestion = OnboardingQuestion.questions.first {
                    state.path.append(.question(OnboardingQuestionFeature.State(question: firstQuestion)))
                }
                return .none
                
            case .backButtonTapped:
                guard state.canGoBack else { return .none }
                state.path.removeLast()
                return .none
                
            case let .path(stackAction):
                switch stackAction {
                case .element(id: _, action: .question(.delegate(.questionAnswered(let questionId, let answer)))):
                    // Save the answer to preferences
                    switch questionId {
                    case 1: state.preferences.avoidPreservatives = answer
                    case 2: state.preferences.antibioticFree = answer
                    case 3: state.preferences.preferOrganic = answer
                    case 4: state.preferences.avoidSugars = answer
                    case 5: state.preferences.avoidMSG = answer
                    case 6: state.preferences.lowerSodium = answer
                    default: break
                    }
                    
                    // Move to next question or meat selection
                    if let nextQuestion = OnboardingQuestion.questions.first(where: { $0.id == questionId + 1 }) {
                        state.path.append(.question(OnboardingQuestionFeature.State(question: nextQuestion)))
                    } else {
                        // All questions answered, go to meat selection
                        state.path.append(.meatSelection(MeatSelectionFeature.State()))
                    }
                    return .none
                    
                case .element(id: _, action: .meatSelection(.delegate(.meatSelectionCompleted(let selectedTypes)))):
                    // Save meat selection and complete onboarding
                    state.preferences.preferredMeatTypes = selectedTypes
                    state.hasCompleted = true
                    
                    return .run { send in
                        await send(.delegate(.onboardingCompleted))
                    }
                    
                default:
                    return .none
                }
                
            case .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

// MARK: - Convenience Initializers
extension OnboardingFeature.State {
    init() {
        self.init(path: StackState<OnboardingPath.State>())
    }
} 