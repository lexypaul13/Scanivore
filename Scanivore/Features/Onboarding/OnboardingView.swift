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
        
        init() {
            // Clean initializer - flow starts with onAppear
        }
    }
    
    enum Action {
        case onAppear
        case path(StackActionOf<OnboardingPath>)
        case backButtonTapped
        case delegate(Delegate)
        
        enum Delegate {
            case onboardingCompleted(OnboardingPreferences)
            case onboardingCancelled
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Start with first question
                if let firstQuestion = OnboardingQuestion.questions.first {
                    state.currentQuestionIndex = 0
                    state.path.append(.question(OnboardingQuestionFeatureDomain.State(question: firstQuestion)))
                }
                return .none
                
            case .backButtonTapped:
                guard state.canGoBack else { return .none }
                state.path.removeLast()
                // Update question index if going back to a question
                if case .question = state.path.last {
                    state.currentQuestionIndex = max(0, state.currentQuestionIndex - 1)
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
                    EmptyView() // Root view is never shown
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
                
                // Progress bar overlay
                VStack {
                    ProgressBar(
                        current: bindableStore.currentStep,
                        total: bindableStore.totalSteps,
                        progress: bindableStore.progress
                    )
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                    .padding(.top, DesignSystem.Spacing.sm)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if bindableStore.canGoBack {
                        Button(action: { bindableStore.send(.backButtonTapped) }) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .medium))

                            }
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                        }
                    }
                }
            }
        }
        .onAppear {
            bindableStore.send(.onAppear)
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
            initialState: OnboardingFeatureDomain.State()
        ) {
            OnboardingFeatureDomain()
        }
    )
} 
 