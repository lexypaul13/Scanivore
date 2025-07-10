//
//  SplashView.swift
//  Scanivore
//
//  Clean modern splash screen design
//

import SwiftUI

struct SplashView: View {
    @State private var showMainApp = false
    private let transitionDelay: TimeInterval = 5
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            // Subtle food icons around edges
            FoodIcon(name: "Steak_Icon", position: .topLeft)
            FoodIcon(name: "Bacon_Icon", position: .topRight)
            FoodIcon(name: "Fish_Icon", position: .rightCenter)
            FoodIcon(name: "Cheese_Icon", position: .bottomRight)
            FoodIcon(name: "Eggs_icon", position: .bottomLeft)
            FoodIcon(name: "Milk_Icon", position: .leftCenter)

            // Central brand content
            VStack(spacing: 0) {
                // Logo
                Image("Scanivore_Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)

                // App name
                Text("Scanivore")
                    .font(Font.custom("AirbnbCereal_W_Bd", size: DesignSystem.Typography.xxxxxl))
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .padding(.top, DesignSystem.Spacing.lg)

                // Welcome message
                Text("Scan any animal product")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.top, DesignSystem.Spacing.md)

                // Tagline
                Text("Know what's in your meat & dairy")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.top, DesignSystem.Spacing.sm)
            }
            .multilineTextAlignment(.center)
        }
        .onAppear {
            // Transition after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + transitionDelay) {
                showMainApp = true
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            ContentView(store: ScanivoreApp.store)
        }
    }
}

// MARK: - Food Icon Component
struct FoodIcon: View {
    enum Position {
        case topLeft, topRight
        case leftCenter, rightCenter
        case bottomLeft, bottomRight
    }

    let name: String
    let position: Position
    private let iconSize: CGFloat = 80
    @State private var floatOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            Image(name)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(DesignSystem.Colors.primaryRed)
                .position(iconPosition(in: geo.size))
                .offset(floatOffset)
                .onAppear {
                    startFloatingAnimation()
                }
        }
    }
    
    private func startFloatingAnimation() {
        withAnimation(
            .easeInOut(duration: Double.random(in: 2...4))
            .repeatForever(autoreverses: true)
            .delay(Double.random(in: 0...0.5))
        ) {
            floatOffset = CGSize(
                width: Double.random(in: -15...15),
                height: Double.random(in: -20...20)
            )
        }
    }

    private func iconPosition(in size: CGSize) -> CGPoint {
        switch position {
        case .topLeft:
            return CGPoint(x: 60, y: 80)
        case .topRight:
            return CGPoint(x: size.width - 60, y: 80)
        case .leftCenter:
            return CGPoint(x: 40, y: size.height / 2)
        case .rightCenter:
            return CGPoint(x: size.width - 40, y: size.height / 2)
        case .bottomLeft:
            return CGPoint(x: 60, y: size.height - 80)
        case .bottomRight:
            return CGPoint(x: size.width - 60, y: size.height - 80)
        }
    }
}

#Preview {
    SplashView()
}
