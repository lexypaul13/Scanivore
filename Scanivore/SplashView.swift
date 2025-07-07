//
//  SplashView.swift
//  Scanivore
//
//  Sift-style animated splash screen with floating food icons
//

import SwiftUI

struct SplashView: View {
    @State private var showMainApp = false
    @State private var iconOffsets: [CGSize] = Array(repeating: .zero, count: 5)
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            // Edge decorations
            FloatingIcon(
                iconName: "Steak_Icon",
                position: .topLeft,
                offset: iconOffsets[0]
            )
            
            FloatingIcon(
                iconName: "Bacon_Icon",
                position: .topRight,
                offset: iconOffsets[1]
            )
            
            FloatingIcon(
                iconName: "Fish_Icon",
                position: .bottomRight,
                offset: iconOffsets[2]
            )
            
            FloatingIcon(
                iconName: "Cheese_Icon",
                position: .bottomLeft,
                offset: iconOffsets[3]
            )
            
            FloatingIcon(
                iconName: "Eggs_icon",
                position: .topCenter,
                offset: iconOffsets[4]
            )
            
            // Central content
            VStack(spacing: 0) {
                // Logo
                Image("Scanivore_Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                
                // App name
                Text("Scanivore")
                    .font(DesignSystem.Typography.hero)
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .padding(.top, 12)
                
                // Welcome caption
                Text("Welcome! Scan any animal product")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.top, 8)
                
                // Tagline
                Text("Know what's in your meat & dairy")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.top, 24)
            }
        }
        .onAppear {
            startAnimations()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            // TODO: Replace with MainAppView
            Text("Main App View")
        }
    }
    
    private func startAnimations() {
        // Start floating animations for each icon
        for index in 0..<5 {
            withAnimation(
                .easeInOut(duration: 6)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.2)
            ) {
                iconOffsets[index] = CGSize(width: 4, height: 4)
            }
        }
        
        // Transition to main app after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showMainApp = true
            }
        }
    }
}

// MARK: - Helper Views

struct FloatingIcon: View {
    let iconName: String
    let position: IconPosition
    let offset: CGSize
    
    private var rotation: Double {
        switch position {
        case .topLeft, .bottomRight:
            return -8
        case .topRight, .bottomLeft:
            return 8
        case .topCenter:
            return -5
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .opacity(0.8)
                .rotationEffect(.degrees(rotation))
                .offset(x: offset.width, y: offset.height)
                .position(getPosition(in: geometry.size))
        }
    }
    
    private func getPosition(in size: CGSize) -> CGPoint {
        switch position {
        case .topLeft:
            return CGPoint(x: -30, y: 60)
        case .topRight:
            return CGPoint(x: size.width + 30, y: 60)
        case .bottomRight:
            return CGPoint(x: size.width + 30, y: size.height - 60)
        case .bottomLeft:
            return CGPoint(x: -30, y: size.height - 60)
        case .topCenter:
            return CGPoint(x: size.width / 2, y: -30)
        }
    }
}

enum IconPosition {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
    case topCenter
}

#Preview {
    SplashView()
}