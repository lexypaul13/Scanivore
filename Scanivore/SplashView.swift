//
//  SplashView.swift
//  Scanivore
//
//  Animated splash screen with logo and scan beam
//

import SwiftUI

struct SplashView: View {
    @State private var showMainApp = false
    @State private var scanBeamOffset: CGFloat = -50
    
    private let brandRed = Color(hex: "#C62828")
    private let brandWhite = Color.white
    private let frameCornerRadius: CGFloat = 12
    private let frameStrokeWidth: CGFloat = 3
    private let beamStrokeWidth: CGFloat = 4
    private let rimStrokeWidth: CGFloat = 6
    
    var body: some View {
        ZStack {
            // Background
            brandWhite
                .ignoresSafeArea()
            
            // Logo Container
            ZStack {
                // Scan Frame Corners
                ScanCorners()
                    .stroke(brandRed, lineWidth: frameStrokeWidth)
                    .frame(width: 200, height: 200)
                
                // Steak Icon
                ZStack {
                    // Steak fill
                    SteakShape()
                        .fill(brandRed)
                        .frame(width: 128, height: 90) // Adjusted height for better steak proportions
                    
                    // White rim around steak
                    SteakShape()
                        .stroke(brandWhite, lineWidth: rimStrokeWidth)
                        .frame(width: 128, height: 90)
                }
                .rotationEffect(.degrees(-15)) // rotationDeg from JSON
                
                // Animated Scan Beam
                Rectangle()
                    .fill(brandRed.opacity(0.6))
                    .frame(width: 200, height: beamStrokeWidth)
                    .offset(y: scanBeamOffset)
            }
        }
        .onAppear {
            animateScanBeam()
        }
        .fullScreenCover(isPresented: $showMainApp) {
            // TODO: Replace with MainAppView
            Text("Main App View")
        }
    }
    
    private func animateScanBeam() {
        // Animate down (2 seconds)
        withAnimation(.easeInOut(duration: 2)) {
            scanBeamOffset = 50
        }
        
        // After 2 seconds, animate back up (2 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 2)) {
                scanBeamOffset = -50
            }
        }
        
        // After full 4-second cycle, show main app
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            showMainApp = true
        }
    }
}

// MARK: - Helper Shapes

struct SteakShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Create an actual steak-like shape (ribeye cut)
        // Start from top left, moving clockwise
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.2))
        
        // Top edge with slight curve
        path.addQuadCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.18),
            control: CGPoint(x: width * 0.5, y: height * 0.15)
        )
        
        // Top right curve
        path.addQuadCurve(
            to: CGPoint(x: width * 0.85, y: height * 0.3),
            control: CGPoint(x: width * 0.8, y: height * 0.22)
        )
        
        // Right side with characteristic steak bulge
        path.addCurve(
            to: CGPoint(x: width * 0.82, y: height * 0.7),
            control1: CGPoint(x: width * 0.88, y: height * 0.45),
            control2: CGPoint(x: width * 0.86, y: height * 0.6)
        )
        
        // Bottom right curve
        path.addQuadCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.82),
            control: CGPoint(x: width * 0.75, y: height * 0.78)
        )
        
        // Bottom edge
        path.addQuadCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.83),
            control: CGPoint(x: width * 0.5, y: height * 0.85)
        )
        
        // Bottom left curve
        path.addQuadCurve(
            to: CGPoint(x: width * 0.18, y: height * 0.72),
            control: CGPoint(x: width * 0.25, y: height * 0.8)
        )
        
        // Left side
        path.addCurve(
            to: CGPoint(x: width * 0.15, y: height * 0.32),
            control1: CGPoint(x: width * 0.14, y: height * 0.6),
            control2: CGPoint(x: width * 0.13, y: height * 0.45)
        )
        
        // Close back to start
        path.addQuadCurve(
            to: CGPoint(x: width * 0.3, y: height * 0.2),
            control: CGPoint(x: width * 0.2, y: height * 0.24)
        )
        
        path.closeSubpath()
        
        return path
    }
}

struct ScanCorners: Shape {
    private let cornerRadius: CGFloat = 12
    private let cornerLength: CGFloat = 40
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY
        
        // Top-left corner
        path.move(to: CGPoint(x: minX + cornerRadius, y: minY))
        path.addArc(
            center: CGPoint(x: minX + cornerRadius, y: minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-180),
            clockwise: true
        )
        path.addLine(to: CGPoint(x: minX, y: minY + cornerLength))
        
        path.move(to: CGPoint(x: minX + cornerLength, y: minY))
        path.addLine(to: CGPoint(x: minX + cornerRadius, y: minY))
        
        // Top-right corner
        path.move(to: CGPoint(x: maxX - cornerRadius, y: minY))
        path.addArc(
            center: CGPoint(x: maxX - cornerRadius, y: minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: maxX, y: minY + cornerLength))
        
        path.move(to: CGPoint(x: maxX - cornerLength, y: minY))
        path.addLine(to: CGPoint(x: maxX - cornerRadius, y: minY))
        
        // Bottom-right corner
        path.move(to: CGPoint(x: maxX, y: maxY - cornerRadius))
        path.addArc(
            center: CGPoint(x: maxX - cornerRadius, y: maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: maxX - cornerLength, y: maxY))
        
        path.move(to: CGPoint(x: maxX, y: maxY - cornerLength))
        path.addLine(to: CGPoint(x: maxX, y: maxY - cornerRadius))
        
        // Bottom-left corner
        path.move(to: CGPoint(x: minX + cornerRadius, y: maxY))
        path.addArc(
            center: CGPoint(x: minX + cornerRadius, y: maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: minX, y: maxY - cornerLength))
        
        path.move(to: CGPoint(x: minX + cornerLength, y: maxY))
        path.addLine(to: CGPoint(x: minX + cornerRadius, y: maxY))
        
        return path
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SplashView()
}
