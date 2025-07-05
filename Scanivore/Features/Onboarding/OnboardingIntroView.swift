//
//  OnboardingIntroView.swift
//  Scanivore
//
//  TCA-compliant onboarding introduction flow
//

import SwiftUI
import ComposableArchitecture

// MARK: - Onboarding Intro Feature Domain
@Reducer
struct OnboardingIntroFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var currentPage = 0
        
        var isLastPage: Bool {
            currentPage == 2
        }
        
        var showPageDots: Bool {
            currentPage < 2
        }
    }
    
    enum Action {
        case pageChanged(Int)
        case skipTapped
        case getStartedTapped
        case nextPage
        
        enum Delegate {
            case introCompleted
        }
        case delegate(Delegate)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .pageChanged(page):
                state.currentPage = page
                return .none
                
            case .nextPage:
                if state.currentPage < 2 {
                    state.currentPage += 1
                }
                return .none
                
            case .skipTapped, .getStartedTapped:
                return .run { send in
                    await send(.delegate(.introCompleted))
                }
                
            case .delegate:
                return .none
            }
        }
    }
}

struct OnboardingIntroView: View {
    let store: StoreOf<OnboardingIntroFeatureDomain>
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                VStack {
                    // Skip button
                    HStack {
                        Spacer()
                        Button("Skip tour") {
                            store.send(.skipTapped)
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.trailing, DesignSystem.Spacing.base)
                        .padding(.top, DesignSystem.Spacing.md)
                    }
                    
                    Spacer()
                    
                    // Content
                    TabView(selection: .init(
                        get: { store.currentPage },
                        set: { store.send(.pageChanged($0)) }
                    )) {
                        ScanScreenView()
                            .tag(0)
                        
                        GradeScreenView()
                            .tag(1)
                        
                        ChooseScreenView {
                            store.send(.getStartedTapped)
                        }
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    Spacer()
                    
                    // Navigation Controls
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        if store.showPageDots {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(0..<2, id: \.self) { index in
                                    Circle()
                                        .fill(index == store.currentPage ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.border)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.bottom, DesignSystem.Spacing.xxl)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Screen 1: Scan
struct ScanScreenView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Visual
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.background)
                    .frame(width: 200, height: 200)
                    .shadow(color: DesignSystem.Colors.shadowMedium, radius: 8, x: 0, y: 4)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Phone icon with scan frame
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(DesignSystem.Colors.primaryRed)
                            .frame(width: 60, height: 100)
                        
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                            .fill(DesignSystem.Colors.background)
                            .frame(width: 50, height: 80)
                        
                        // Scan frame corners
                        ScanFrameCorners()
                            .stroke(DesignSystem.Colors.primaryRed, lineWidth: 2)
                            .frame(width: 40, height: 30)
                    }
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Scan Any Meat")
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .multilineTextAlignment(.center)
                
                Text("Simply point your camera at any meat product to get instant quality analysis")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Screen 2: Grade
struct GradeScreenView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Visual
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.background)
                    .frame(width: 200, height: 200)
                    .shadow(color: DesignSystem.Colors.shadowMedium, radius: 8, x: 0, y: 4)
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Grade dial
                    ZStack {
                        Circle()
                            .stroke(DesignSystem.Colors.border, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Text("B+")
                            .font(DesignSystem.Typography.heading1)
                            .foregroundColor(DesignSystem.Colors.warning)
                    }
                    
                    // Quality indicators
                    HStack(spacing: DesignSystem.Spacing.md) {
                        QualityDot(color: DesignSystem.Colors.success, label: "Fresh")
                        QualityDot(color: DesignSystem.Colors.warning, label: "Quality")
                        QualityDot(color: DesignSystem.Colors.error, label: "Nitrates")
                    }
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Get Instant Grades")
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .multilineTextAlignment(.center)
                
                Text("See quality ratings, freshness levels, and health warnings instantly")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Screen 3: Choose
struct ChooseScreenView: View {
    let onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Visual
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.background)
                    .frame(width: 200, height: 200)
                    .shadow(color: DesignSystem.Colors.shadowMedium, radius: 8, x: 0, y: 4)
                
                HStack(spacing: DesignSystem.Spacing.lg) {
                    // Bad product
                    VStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(DesignSystem.Colors.border)
                            .frame(width: 40, height: 50)
                            .overlay(
                                Image(systemName: "xmark")
                                    .foregroundColor(DesignSystem.Colors.error)
                                    .font(.system(size: 16, weight: .bold))
                            )
                    }
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    // Good product
                    VStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(DesignSystem.Colors.success.opacity(0.2))
                            .frame(width: 40, height: 50)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .foregroundColor(DesignSystem.Colors.success)
                                    .font(.system(size: 16, weight: .bold))
                            )
                    }
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Make Better Choices")
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .multilineTextAlignment(.center)
                
                Text("Get healthier alternatives and better options in one tap")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
            
            Spacer()
            
            // Get Started Button
            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(DesignSystem.Typography.buttonText)
                    .foregroundColor(DesignSystem.Colors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignSystem.Components.Button.primaryHeight)
                    .background(DesignSystem.Colors.primaryRed)
                    .cornerRadius(DesignSystem.Components.Button.primaryCornerRadius)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Helper Views
struct QualityDot: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct ScanFrameCorners: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerLength: CGFloat = 8
        let cornerRadius: CGFloat = 2
        
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY
        
        // Top-left corner
        path.move(to: CGPoint(x: minX + cornerRadius, y: minY))
        path.addLine(to: CGPoint(x: minX + cornerLength, y: minY))
        path.move(to: CGPoint(x: minX, y: minY + cornerRadius))
        path.addLine(to: CGPoint(x: minX, y: minY + cornerLength))
        
        // Top-right corner
        path.move(to: CGPoint(x: maxX - cornerRadius, y: minY))
        path.addLine(to: CGPoint(x: maxX - cornerLength, y: minY))
        path.move(to: CGPoint(x: maxX, y: minY + cornerRadius))
        path.addLine(to: CGPoint(x: maxX, y: minY + cornerLength))
        
        // Bottom-right corner
        path.move(to: CGPoint(x: maxX - cornerRadius, y: maxY))
        path.addLine(to: CGPoint(x: maxX - cornerLength, y: maxY))
        path.move(to: CGPoint(x: maxX, y: maxY - cornerRadius))
        path.addLine(to: CGPoint(x: maxX, y: maxY - cornerLength))
        
        // Bottom-left corner
        path.move(to: CGPoint(x: minX + cornerRadius, y: maxY))
        path.addLine(to: CGPoint(x: minX + cornerLength, y: maxY))
        path.move(to: CGPoint(x: minX, y: maxY - cornerRadius))
        path.addLine(to: CGPoint(x: minX, y: maxY - cornerLength))
        
        return path
    }
}

#Preview {
    OnboardingIntroView(
        store: Store(initialState: OnboardingIntroFeatureDomain.State()) {
            OnboardingIntroFeatureDomain()
        }
    )
}