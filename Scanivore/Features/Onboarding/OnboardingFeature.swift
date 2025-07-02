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
enum OnboardingPath: Equatable {
    case question(OnboardingQuestionFeature)
    case meatSelection(MeatSelectionFeature)
}

// MARK: - Main Onboarding Feature
@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var path = StackState<OnboardingPath.State>()
        var preferences: OnboardingPreferences? = UserDefaults.standard.getOnboardingPreferences()
        var hasCompleted = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedOnboarding)
        
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
                    // Initialize preferences if nil
                    if state.preferences == nil {
                        state.preferences = OnboardingPreferences()
                    }
                    
                    // Save the answer to preferences
                    switch questionId {
                    case 1: state.preferences?.avoidPreservatives = answer
                    case 2: state.preferences?.antibioticFree = answer
                    case 3: state.preferences?.preferOrganic = answer
                    case 4: state.preferences?.avoidSugars = answer
                    case 5: state.preferences?.avoidMSG = answer
                    case 6: state.preferences?.lowerSodium = answer
                    default: break
                    }
                    
                    // Persist to UserDefaults
                    UserDefaults.standard.setOnboardingPreferences(state.preferences)
                    
                    // Move to next question or meat selection
                    if let nextQuestion = OnboardingQuestion.questions.first(where: { $0.id == questionId + 1 }) {
                        state.path.append(.question(OnboardingQuestionFeature.State(question: nextQuestion)))
                    } else {
                        // All questions answered, go to meat selection
                        state.path.append(.meatSelection(MeatSelectionFeature.State()))
                    }
                    return .none
                    
                case .element(id: _, action: .meatSelection(.delegate(.meatSelectionCompleted(let selectedTypes)))):
                    // Initialize preferences if nil and save meat selection
                    if state.preferences == nil {
                        state.preferences = OnboardingPreferences()
                    }
                    state.preferences?.preferredMeatTypes = selectedTypes
                    state.hasCompleted = true
                    
                    // Persist to UserDefaults
                    UserDefaults.standard.setOnboardingPreferences(state.preferences)
                    UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasCompletedOnboarding)
                    
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

 
