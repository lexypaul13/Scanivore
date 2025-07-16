//
//  ScanButton.swift
//  Scanivore
//
//  Main scan button component for scanner
//

import SwiftUI

struct ScanButton: View {
    let isScanning: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primaryRed)
                    .frame(width: DesignSystem.Components.Scanner.buttonSize, height: DesignSystem.Components.Scanner.buttonSize)
                
                Circle()
                    .stroke(DesignSystem.Colors.background, lineWidth: 4)
                    .frame(width: DesignSystem.Components.Scanner.buttonSize, height: DesignSystem.Components.Scanner.buttonSize)
                
                Image(systemName: "camera.fill")
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.background)
            }
        }
        .disabled(isScanning)
        .scaleEffect(isScanning ? 0.9 : 1.0)
        .opacity(isScanning ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isScanning)
        .shadow(
            color: DesignSystem.Shadow.medium,
            radius: DesignSystem.Shadow.radiusMedium,
            x: DesignSystem.Shadow.offsetMedium.width,
            y: DesignSystem.Shadow.offsetMedium.height
        )
    }
}