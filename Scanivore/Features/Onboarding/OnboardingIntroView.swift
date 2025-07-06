//
//  OnboardingIntroView.swift
//  Scanivore
//
//  TCA-compliant onboarding introduction flow
//

import SwiftUI
import ComposableArchitecture
import Lottie

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
                    // Only keep top spacer on the first two screens so that the final screen isn't pushed downward
                    if !store.isLastPage {
                        Spacer()
                    }
                    
                    // Content
                    TabView(selection: .init(
                        get: { store.currentPage },
                        set: { store.send(.pageChanged($0)) }
                    )) {
                        ScanScreenView()
                            .tag(0)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        
                        GradeScreenView()
                            .tag(1)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        
                        ChooseScreenView {
                            store.send(.getStartedTapped)
                        }
                        .tag(2)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.4), value: store.currentPage)
                    
                    // Balance layout with bottom spacer on first two pages
                    if !store.isLastPage {
                        Spacer()
                    }
                    
                    // Navigation Controls
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        if store.showPageDots {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(0..<2, id: \.self) { index in
                                    Circle()
                                        .fill(index == store.currentPage ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.border)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(index == store.currentPage ? 1.2 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: store.currentPage)
                                }
                            }
                            .padding(.bottom, DesignSystem.Spacing.xxl)
                        } else {
                            // Placeholder to keep the overall height consistent when dots are hidden
                            Spacer()
                                .frame(height: DesignSystem.Spacing.xxl + 8) // 8 for dot size + same bottom padding
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Screen 1: Scan
struct ScanScreenView: View {
    @State private var contentOpacity: Double = 0
    @State private var scanPulseScale: CGFloat = 1.0
    @State private var particlesVisible = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Visual with Lottie Animation
            ZStack {
                // Animated background glow
                Circle()
                    .fill(DesignSystem.Colors.primaryRed.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 20)
                
                Circle()
                    .fill(DesignSystem.Colors.background)
                    .frame(width: 280, height: 280)
                    .shadow(color: DesignSystem.Colors.shadowMedium, radius: 8, x: 0, y: 4)
                
                // Main animation container
                ZStack {
                    // Animated scanning radar effect
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(DesignSystem.Colors.primaryRed.opacity(0.3), lineWidth: 2)
                            .frame(width: CGFloat(150 + index * 40), height: CGFloat(150 + index * 40))
                            .scaleEffect(scanPulseScale)
                            .opacity(particlesVisible ? 0 : 1)
                            .animation(
                                .easeOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.5),
                                value: scanPulseScale
                            )
                    }
                    
                    // Phone scanner perfectly centered
                    PhoneScannerView()
                    
                    // Floating scan particles
                    if particlesVisible {
                        ForEach(0..<8, id: \.self) { index in
                            ScanParticle(index: index)
                        }
                    }
                }
            }
            .opacity(contentOpacity)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Scan Any Animal Food Products ")
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .multilineTextAlignment(.center)
                
                Text("Simply point your camera at any animal product to get instant quality analysis")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            contentOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            scanPulseScale = 1.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                particlesVisible = true
            }
        }
    }
}

// MARK: - Screen 2: Grade
struct GradeScreenView: View {
    @State private var gradeText = ""
    @State private var gradeRotation: Double = 0
    @State private var circleColor: Color = DesignSystem.Colors.error
    @State private var dotsScale: [CGFloat] = Array(repeating: 0, count: 3)
    @State private var contentOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var dataPoints: [DataPoint] = []
    
    private let gradeLetters = ["D", "C", "B", "A"]
    private let gradeColors: [Color] = [
        DesignSystem.Colors.error,      // D - Red
        DesignSystem.Colors.warning,    // C - Orange
        Color.green.opacity(0.8),       // B - Light Green
        Color.green                     // A - Dark Green
    ]
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Visual
            ZStack {
                // Animated background data visualization
                ForEach(dataPoints) { point in
                    DataPointView(point: point)
                }
                
                // Glowing circle background
                Circle()
                    .fill(DesignSystem.Colors.primaryRed.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 20)
                
                Circle()
                    .fill(DesignSystem.Colors.background)
                    .frame(width: 280, height: 280)
                    .shadow(color: DesignSystem.Colors.shadowMedium, radius: 8, x: 0, y: 4)
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Animated grade dial
                    ZStack {
                        // Full circle with color changes
                        Circle()
                            .stroke(circleColor, lineWidth: 6)
                            .frame(width: 100, height: 100)
                        
                        // Scrambling grade text
                        Text(gradeText)
                            .font(DesignSystem.Typography.heading1)
                            .foregroundColor(circleColor)
                            .rotationEffect(.degrees(gradeRotation))
                    }
                    
                    // Quality indicators with staggered animation
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        AnimatedQualityDot(
                            color: DesignSystem.Colors.success,
                            label: "Fresh",
                            scale: dotsScale.indices.contains(0) ? dotsScale[0] : 0
                        )
                        AnimatedQualityDot(
                            color: DesignSystem.Colors.warning,
                            label: "Quality",
                            scale: dotsScale.indices.contains(1) ? dotsScale[1] : 0
                        )
                        AnimatedQualityDot(
                            color: DesignSystem.Colors.error,
                            label: "Nitrates",
                            scale: dotsScale.indices.contains(2) ? dotsScale[2] : 0
                        )
                    }
                }
            }
            .opacity(contentOpacity)
            
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
        .onAppear {
            startGradeAnimations()
        }
    }
    
    private func startGradeAnimations() {
        // Generate random data points
        dataPoints = (0..<15).map { _ in
            DataPoint(
                x: CGFloat.random(in: -100...100),
                y: CGFloat.random(in: -100...100)
            )
        }
        
        withAnimation(.easeInOut(duration: 0.8)) {
            contentOpacity = 1.0
        }
        
        // Start with red circle
        circleColor = DesignSystem.Colors.error
        
        // Scramble through grades before settling
        animateGradeScramble()
        
        // Glow effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowRadius = 20
        }
        
        // Staggered dots animation
        for i in 0..<min(3, dotsScale.count) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.5 + Double(i) * 0.2)) {
                if dotsScale.indices.contains(i) {
                    dotsScale[i] = 1.0
                }
            }
        }
    }
    
    private func animateGradeScramble() {
        var scrambleCount = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if scrambleCount < 15 {
                if !gradeLetters.isEmpty {
                    let randomIndex = Int.random(in: 0..<gradeLetters.count)
                    gradeText = gradeLetters[randomIndex]
                    
                    // Update circle color to match the grade
                    withAnimation(.easeInOut(duration: 0.1)) {
                        circleColor = gradeColors[randomIndex]
                        gradeRotation = Double.random(in: -10...10)
                    }
                }
                scrambleCount += 1
            } else {
                timer.invalidate()
                // Always end at A (index 3)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    gradeText = "A"
                    circleColor = gradeColors[3] // A - Dark Green
                    gradeRotation = 0
                }
            }
        }
        
        // Ensure timer runs on main thread
        RunLoop.main.add(timer, forMode: .common)
    }
}

// MARK: - Screen 3: Choose
struct ChooseScreenView: View {
    let onGetStarted: () -> Void
    @State private var badProductOpacity: Double = 1.0
    @State private var badProductScale: CGFloat = 1.0
    @State private var goodProductOpacity: Double = 0
    @State private var goodProductScale: CGFloat = 0.5
    @State private var arrowRotation: Double = 0
    @State private var contentOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Visual
            ZStack {
                // Animated glow effect
                Circle()
                    .fill(DesignSystem.Colors.primaryRed.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 30)
                    .opacity(goodProductOpacity)
                
                Circle()
                    .fill(DesignSystem.Colors.background)
                    .frame(width: 280, height: 280)
                    .shadow(color: DesignSystem.Colors.shadowMedium, radius: 8, x: 0, y: 4)
                
                ZStack {
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        // Bad product that dissolves
                        DissolvinProductView(
                            opacity: badProductOpacity,
                            scale: badProductScale
                        )
                        
                        // Magical transformation arrow
                        ZStack {
                            // Thumbs up effect
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(Color.green)
                                .rotationEffect(.degrees(arrowRotation))
                                .opacity(goodProductOpacity)
                            
                            Image(systemName: "hand.thumbsdown.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.error)
                                .opacity(1 - goodProductOpacity)
                        }
                        
                        // Good product that materializes
                        MaterializingProductView(
                            opacity: goodProductOpacity,
                            scale: goodProductScale
                        )
                    }
                }
            }
            .opacity(contentOpacity)
            
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
        .onAppear {
            startChooseAnimations()
        }
        .padding(.top, 120)
    }
    
    private func startChooseAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            contentOpacity = 1.0
        }
        
        // Start the transformation sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            animateTransformation()
        }
        
    }
    
    private func animateTransformation() {
        // Dissolve bad product
        withAnimation(.easeOut(duration: 0.8)) {
            badProductOpacity = 0.3
            badProductScale = 0.8
        }
        
        // Rotate arrow to wand
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
            arrowRotation = 360
        }
        
        // Materialize good product
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(1.0)) {
            goodProductOpacity = 1.0
            goodProductScale = 1.0
        }
        
        // Complete dissolve
        withAnimation(.easeOut(duration: 0.9).delay(3.0)) {
            badProductOpacity = 0
        }
        
        // Repeat the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                // Reset states
                badProductOpacity = 1.0
                badProductScale = 1.0
                goodProductOpacity = 0
                goodProductScale = 0.5
                arrowRotation = 0
            }
            
            // Restart animation after a brief pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateTransformation()
            }
        }
    }
}

// MARK: - Scan Screen Components
struct PhoneScannerView: View {
    @State private var scanOffset: CGFloat = -50
    @State private var glowOpacity: Double = 0.3
    
    // iPhone 14 Pro specifications scaled down
    private let phoneWidth: CGFloat = 70
    private let phoneHeight: CGFloat = 140
    private let strokeWidth: CGFloat = 2
    private let cornerRadius: CGFloat = 16
    private let islandWidth: CGFloat = 45
    private let islandHeight: CGFloat = 13
    private let islandCornerRadius: CGFloat = 6.5
    private let islandInsetTop: CGFloat = 7
    
    var body: some View {
        ZStack {
            // iPhone 14 Pro outline shape
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(DesignSystem.Colors.primaryRed, lineWidth: strokeWidth)
                .frame(width: phoneWidth, height: phoneHeight)
            
            // Screen area (inside the phone outline)
            RoundedRectangle(cornerRadius: cornerRadius - strokeWidth)
                .fill(DesignSystem.Colors.background)
                .frame(width: phoneWidth - strokeWidth * 2, height: phoneHeight - strokeWidth * 2)
                .overlay(
                    VStack(spacing: 0) {
                        // Dynamic Island cutout
                        Capsule()
                            .fill(DesignSystem.Colors.primaryRed)
                            .frame(width: islandWidth, height: islandHeight)
                            .padding(.top, islandInsetTop)
                        
                        Spacer()
                        
                        // Steak image with grid overlay
                        ZStack {
                            Image("SteakIcon")
                                .resizable()
                                .frame(width: 60, height: 60)
                            
                            // Scanning grid overlay
                            ScanningGrid()
                                .stroke(DesignSystem.Colors.primaryRed.opacity(0.3), lineWidth: 0.5)
                                .frame(width: phoneWidth - strokeWidth * 4, height: phoneHeight - strokeWidth * 8)
                        }
                        
                        Spacer()
                    }
                )
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primaryRed.opacity(0),
                                    DesignSystem.Colors.primaryRed,
                                    DesignSystem.Colors.primaryRed.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: phoneWidth - strokeWidth * 4, height: 3)
                        .blur(radius: 1)
                        .offset(y: scanOffset)
                        .shadow(color: DesignSystem.Colors.primaryRed, radius: 3)
                        .opacity(glowOpacity)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius - strokeWidth))
        }
        .onAppear {
            animateScan()
        }
    }
    
    private func animateScan() {
        // Scan line goes up and down
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
            scanOffset = 50
        }
        
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            glowOpacity = 1.0
        }
    }
}

struct ScanningGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gridSize: CGFloat = 10
        
        // Vertical lines
        for i in stride(from: 0, through: rect.width, by: gridSize) {
            path.move(to: CGPoint(x: i, y: 0))
            path.addLine(to: CGPoint(x: i, y: rect.height))
        }
        
        // Horizontal lines
        for i in stride(from: 0, through: rect.height, by: gridSize) {
            path.move(to: CGPoint(x: 0, y: i))
            path.addLine(to: CGPoint(x: rect.width, y: i))
        }
        
        return path
    }
}

struct ScanParticle: View {
    let index: Int
    @State private var offset = CGSize.zero
    @State private var opacity: Double = 0
    
    private var randomDelay: Double {
        Double.random(in: 0...2)
    }
    
    private var randomDuration: Double {
        Double.random(in: 3...5)
    }
    
    var body: some View {
        Circle()
            .fill(DesignSystem.Colors.primaryRed)
            .frame(width: 4, height: 4)
            .opacity(opacity)
            .offset(offset)
            .onAppear {
                startAnimation()
            }
    }
    
    private func startAnimation() {
        let angle = Double(index) * (360.0 / 8.0) * (.pi / 180)
        let radius: CGFloat = 100
        
        withAnimation(
            .easeInOut(duration: randomDuration)
            .repeatForever(autoreverses: true)
            .delay(randomDelay)
        ) {
            offset = CGSize(
                width: cos(angle) * radius,
                height: sin(angle) * radius
            )
            opacity = 1.0
        }
    }
}

// MARK: - Grade Screen Components
struct DataPoint: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
}

struct DataPointView: View {
    let point: DataPoint
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0
    
    var body: some View {
        Circle()
            .fill(DesignSystem.Colors.primaryRed.opacity(0.3))
            .frame(width: 6, height: 6)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: point.x, y: point.y)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 0.8)
                    .delay(Double.random(in: 0...0.5))
                ) {
                    opacity = 1.0
                    scale = 1.0
                }
                
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...1))
                ) {
                    scale = 1.3
                }
            }
    }
}

struct AnimatedQualityDot: View {
    let color: Color
    let label: String
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .scaleEffect(scale * 1.5)
                    .opacity(scale > 0 ? 0.5 : 0)
                
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                    .scaleEffect(scale)
            }
            
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .opacity(scale)
        }
    }
}

// MARK: - Choose Screen Components
struct ShoppingCartView: View {
    let isGoodCart: Bool
    let opacity: Double
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Try Lottie animation first, fallback to custom
                if isGoodCart {
                    // Good cart with Lottie animation
                    LottieAnimationView(
                        animationName: "shopping-cart-good",
                        loopMode: .loop,
                        animationSpeed: 0.5
                    )
                    .frame(width: 60, height: 50)
                    .opacity(opacity > 0.5 ? 1 : 0)
                    
                    // Fallback: Custom good cart
                    if opacity <= 0.5 {
                        CustomShoppingCart(isGood: true)
                    }
                } else {
                    // Poor cart with Lottie animation
                    LottieAnimationView(
                        animationName: "shopping-cart-poor",
                        loopMode: .loop,
                        animationSpeed: 0.8
                    )
                    .frame(width: 60, height: 50)
                    .opacity(opacity > 0.5 ? 1 : 0)
                    
                    // Fallback: Custom poor cart
                    if opacity <= 0.5 {
                        CustomShoppingCart(isGood: false)
                    }
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
            
            // Grade badge
            GradeBadge(isGood: isGoodCart)
                .scaleEffect(scale * 0.8)
                .opacity(opacity)
        }
    }
}

struct CustomShoppingCart: View {
    let isGood: Bool
    
    var body: some View {
        ZStack {
            // Cart body
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystem.Colors.background)
                .frame(width: 40, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(DesignSystem.Colors.border, lineWidth: 2)
                )
            
            // Cart contents (meat packages)
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    MeatPackage(grade: isGood ? "A" : "D")
                    MeatPackage(grade: isGood ? "A" : "C")
                }
                HStack(spacing: 2) {
                    MeatPackage(grade: isGood ? "B" : "D")
                    MeatPackage(grade: isGood ? "A" : "C")
                }
            }
            .offset(y: -2)
        }
    }
}

struct MeatPackage: View {
    let grade: String
    
    private var packageColor: Color {
        switch grade {
        case "A": return Color.green
        case "B": return Color.green.opacity(0.8)
        case "C": return DesignSystem.Colors.warning
        case "D": return DesignSystem.Colors.error
        default: return DesignSystem.Colors.border
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(packageColor.opacity(0.3))
            .frame(width: 8, height: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(packageColor, lineWidth: 0.5)
            )
    }
}

struct GradeBadge: View {
    let isGood: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isGood ? Color.green : DesignSystem.Colors.error)
                .frame(width: 20, height: 20)
            
            Text(isGood ? "A" : "D")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct MagicParticle: Identifiable {
    let id = UUID()
    let startX = CGFloat.random(in: -50...50)
    let startY = CGFloat.random(in: -50...50)
    let color = DesignSystem.Colors.primaryRed.opacity(Double.random(in: 0.3...0.8))
    let size = CGFloat.random(in: 2...6)
}

struct MagicParticleView: View {
    let particle: MagicParticle
    @State private var offset = CGSize.zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .offset(x: particle.startX + offset.width, y: particle.startY + offset.height)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    offset = CGSize(
                        width: CGFloat.random(in: -100...100),
                        height: CGFloat.random(in: -100...100)
                    )
                    opacity = 1.0
                }
                
                withAnimation(
                    .easeIn(duration: 2.0)
                    .delay(1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    opacity = 0
                }
            }
    }
}

struct DissolvinProductView: View {
    let opacity: Double
    let scale: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
            .fill(DesignSystem.Colors.primaryRed.opacity(0.2))
            .frame(width: 80, height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.primaryRed, lineWidth: 3)
            )
            .overlay(
                Image(systemName: "xmark")
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .font(.system(size: 32, weight: .bold))
            )
            .scaleEffect(scale)
            .opacity(opacity)
    }
}

struct MaterializingProductView: View {
    let opacity: Double
    let scale: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
            .fill(DesignSystem.Colors.background)
            .frame(width: 80, height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(Color.green, lineWidth: 3)
            )
            .overlay(
                Image(systemName: "checkmark")
                    .foregroundColor(Color.green)
                    .font(.system(size: 32, weight: .bold))
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .shadow(
                color: Color.green.opacity(opacity * 0.3),
                radius: 10,
                x: 0,
                y: 0
            )
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
