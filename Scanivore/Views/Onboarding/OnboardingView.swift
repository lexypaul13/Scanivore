//
//  OnboardingView.swift
//  Scanivore
//
//  Main onboarding flow container
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentQuestion = 1
    @State private var preferences = OnboardingPreferences()
    @Binding var showOnboarding: Bool
    
    // Question data
    let questions = [
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar
                    ProgressBar(current: currentQuestion, total: 7)
                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                        .padding(.top, DesignSystem.Spacing.sm)
                    
                    // Content
                    if currentQuestion >= 1 && currentQuestion <= questions.count {
                        OnboardingQuestionView(
                            question: questions[currentQuestion - 1],
                            onAnswer: { answer in
                                handleAnswer(questionId: currentQuestion, answer: answer)
                            }
                        )
                    } else if currentQuestion == 7 {
                        MeatSelectionView(
                            selectedTypes: $preferences.preferredMeatTypes,
                            onContinue: {
                                completeOnboarding()
                            }
                        )
                    } else {
                        // Fallback - reset to first question if out of bounds
                        Text("Loading...")
                            .onAppear {
                                currentQuestion = 1
                            }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentQuestion > 1 {
                        Button(action: { 
                            if currentQuestion > 1 {
                                currentQuestion -= 1 
                            }
                        }) {
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
    
    private func handleAnswer(questionId: Int, answer: Bool) {
        // Update preferences based on question
        switch questionId {
        case 1: preferences.avoidPreservatives = answer
        case 2: preferences.antibioticFree = answer
        case 3: preferences.preferOrganic = answer
        case 4: preferences.avoidSugars = answer
        case 5: preferences.avoidMSG = answer
        case 6: preferences.lowerSodium = answer
        default: break
        }
        
        // Move to next question (with bounds checking)
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentQuestion < 7 {
                currentQuestion += 1
            }
        }
    }
    
    private func completeOnboarding() {
        // Save preferences
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: "onboardingPreferences")
        }
        
        // Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Dismiss onboarding
        withAnimation {
            showOnboarding = false
        }
    }
}

struct OnboardingQuestion {
    let id: Int
    let title: String
    let subtitle: String
}

struct ProgressBar: View {
    let current: Int
    let total: Int
    
    var progress: Double {
        Double(current) / Double(total)
    }
    
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
    OnboardingView(showOnboarding: .constant(true))
}

#Preview("Question 1") {
    @Previewable @State var showOnboarding = true
    OnboardingView(showOnboarding: $showOnboarding)
}

