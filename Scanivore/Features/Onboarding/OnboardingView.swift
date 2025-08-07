//
//  OnboardingView.swift
//  Scanivore
//
//  Main TCA onboarding flow with navigation stack
//

import SwiftUI
import ComposableArchitecture

// MARK: - Onboarding Path
@Reducer(state: .equatable)
@CasePathable
enum OnboardingPath {
    case question(OnboardingQuestionFeatureDomain)
    case meatSelection(MeatSelectionFeatureDomain)
}

// MARK: - Main Onboarding Feature Domain
@Reducer
struct OnboardingFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var path = StackState<OnboardingPath.State>()
        var preferences = OnboardingPreferences()
        var currentQuestionIndex = 0
        
        var currentStep: Int {
            path.count + 1 // Add 1 because root question is not in path
        }
        
        var totalSteps: Int {
            OnboardingQuestion.questions.count + 1 // questions + meat selection
        }
        
        var progress: Double {
            guard totalSteps > 0 else { return 0 }
            return Double(currentStep) / Double(totalSteps)
        }
        
        var canGoBack: Bool {
            !path.isEmpty
        }
        
        init() {
            // Start with empty path - first question will be shown as root
        }
    }
    
    enum Action {
        case path(StackActionOf<OnboardingPath>)
        case backButtonTapped
        case rootQuestionAnswered(questionId: Int, answer: Bool)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case onboardingCompleted(OnboardingPreferences)
            case onboardingCancelled
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                guard state.canGoBack else { return .none }
                state.path.removeLast()
                // Update question index if going back to a question
                if case .question = state.path.last {
                    state.currentQuestionIndex = max(0, state.currentQuestionIndex - 1)
                } else if state.path.isEmpty {
                    // Going back to root question
                    state.currentQuestionIndex = 0
                }
                return .none
                
            case let .rootQuestionAnswered(questionId, answer):
                // Save the answer to preferences (first question)
                state.preferences.avoidPreservatives = answer
                
                // Move to next question
                state.currentQuestionIndex = 1
                if let nextQuestion = OnboardingQuestion.questions.first(where: { $0.id == 2 }) {
                    state.path.append(.question(OnboardingQuestionFeatureDomain.State(question: nextQuestion)))
                }
                return .none
                
            // ── Question delegates ────────────────────────────────────
            case let .path(.element(_, action: .question(.delegate(event)))):
                switch event {
                case .questionAnswered(let questionId, let answer):
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
                    state.currentQuestionIndex += 1
                    if let nextQuestion = OnboardingQuestion.questions.first(where: { $0.id == questionId + 1 }) {
                        state.path.append(.question(OnboardingQuestionFeatureDomain.State(question: nextQuestion)))
                    } else {
                        // All questions answered, go to meat selection
                        state.path.append(.meatSelection(MeatSelectionFeatureDomain.State()))
                    }
                    return .none
                }
                
            // ── Meat Selection delegates ────────────────────────────────────
            case let .path(.element(_, action: .meatSelection(.delegate(event)))):
                switch event {
                case .meatSelectionCompleted(let selectedTypes):
                    // Save meat selection to preferences
                    state.preferences.preferredMeatTypes = selectedTypes
                    
                    // Onboarding is complete - delegate will handle persistence
                    return .send(.delegate(.onboardingCompleted(state.preferences)))
                }
                
            // Bubble-up no-ops
            case .path, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeatureDomain>
    @Bindable private var bindableStore: StoreOf<OnboardingFeatureDomain>
    
    init(store: StoreOf<OnboardingFeatureDomain>) {
        self.store = store
        self.bindableStore = store
    }
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                NavigationStack(path: $bindableStore.scope(state: \.path, action: \.path)) {
                    // Show first question as root to avoid empty view
                    if let firstQuestion = OnboardingQuestion.questions.first {
                        RootQuestionView(
                            question: firstQuestion,
                            onAnswer: { answer in
                                bindableStore.send(.rootQuestionAnswered(questionId: firstQuestion.id, answer: answer))
                            }
                        )
                        .navigationBarBackButtonHidden(true)
                        .toolbarRole(.editor)
                    } else {
                        EmptyView()
                    }
                } destination: { store in
                    switch store.case {
                    case let .question(questionStore):
                        OnboardingQuestionView(store: questionStore)
                            .navigationBarBackButtonHidden(true)
                            .toolbarRole(.editor)
                    case let .meatSelection(meatSelectionStore):
                        MeatSelectionView(store: meatSelectionStore)
                            .navigationBarBackButtonHidden(true)
                            .toolbarRole(.editor)
                    }
                }
                
                // Progress bar and back button overlay
                VStack {
                    // Progress bar
                    ProgressBar(
                        current: bindableStore.currentStep,
                        total: bindableStore.totalSteps,
                        progress: bindableStore.progress
                    )
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    .padding(.top, DesignSystem.Spacing.sm)
                    
                    // Back button positioned below progress bar
                    HStack {
                        if bindableStore.canGoBack {
                            Button(action: { bindableStore.send(.backButtonTapped) }) {
                                Image(systemName: "chevron.left")
                                    .font(DesignSystem.Typography.heading3)
                                    .foregroundColor(DesignSystem.Colors.primaryRed)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(DesignSystem.Colors.background)
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                            }
                            .padding(.leading, DesignSystem.Spacing.screenPadding)
                            .padding(.top, DesignSystem.Spacing.sm)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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

// Manual Equatable implementation for Action
extension OnboardingFeatureDomain.Action: Equatable {
    static func == (lhs: OnboardingFeatureDomain.Action, rhs: OnboardingFeatureDomain.Action) -> Bool {
        switch (lhs, rhs) {
        case (.backButtonTapped, .backButtonTapped):
            return true
        case let (.rootQuestionAnswered(lhsId, lhsAnswer), .rootQuestionAnswered(rhsId, rhsAnswer)):
            return lhsId == rhsId && lhsAnswer == rhsAnswer
        case let (.delegate(lhsDelegate), .delegate(rhsDelegate)):
            return lhsDelegate == rhsDelegate
        case (.path, .path):
            // StackAction comparison is complex, treat as equal for compilation
            return true
        default:
            return false
        }
    }
}

// MARK: - Root Question View
struct RootQuestionView: View {
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
                OnboardingAnswerButton(
                    title: "Yes",
                    isPositive: true,
                    action: { onAnswer(true) }
                )
                
                OnboardingAnswerButton(
                    title: "No",
                    isPositive: false,
                    action: { onAnswer(false) }
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            .padding(.bottom, 60) // Reduced padding since back button is now at top
        }
    }
}

// MARK: - Answer Button Component
struct OnboardingAnswerButton: View {
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
    OnboardingView(
        store: Store(
            initialState: OnboardingFeatureDomain.State()
        ) {
            OnboardingFeatureDomain()
        }
    )
} 
 