//
//  ScannerView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct ScannerView: View {
    @State private var isScanning = false
    @State private var showingResults = false
    @State private var scanProgress: Double = 0
    @State private var mockScanResult: MeatScan?
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                CameraPreviewView()
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    if isScanning {
                        ScanningOverlay(progress: $scanProgress)
                    }
                    
                    ScanButton(isScanning: $isScanning) {
                        startScanning()
                    }
                    .padding(.bottom, DesignSystem.Spacing.xxxxxl)
                }
            }
            .navigationTitle("Scan Meat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                }
            }
            .sheet(isPresented: $showingResults) {
                if let result = mockScanResult {
                    ProductDetailView(scan: result)
                }
            }
        }
    }
    
    private func startScanning() {
        withAnimation {
            isScanning = true
            scanProgress = 0
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            scanProgress += 0.05
            
            if scanProgress >= 1.0 {
                timer.invalidate()
                isScanning = false
                mockScanResult = MeatScan.mockScans.randomElement()
                showingResults = true
                scanProgress = 0
            }
        }
    }
}

struct CameraPreviewView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.black)
                
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .stroke(DesignSystem.Colors.primaryRed.opacity(0.8), lineWidth: 3)
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                
                VStack {
                    Text("Position meat within frame")
                        .font(DesignSystem.Typography.heading2)
                        .foregroundColor(DesignSystem.Colors.background)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.textPrimary.opacity(0.8))
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .padding(.top, 100)
                    
                    Spacer()
                }
            }
        }
    }
}

struct ScanningOverlay: View {
    @Binding var progress: Double
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView(value: progress)
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2.5)
                .tint(DesignSystem.Colors.primaryRed)
            
            Text("Analyzing...")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("\(Int(progress * 100))%")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryRed)
        }
        .padding(DesignSystem.Spacing.xxxl)
        .background(DesignSystem.Colors.background.opacity(0.95))
        .cornerRadius(DesignSystem.CornerRadius.xxl)
        .shadow(
            color: DesignSystem.Shadow.medium,
            radius: DesignSystem.Shadow.radiusMedium,
            x: DesignSystem.Shadow.offsetMedium.width,
            y: DesignSystem.Shadow.offsetMedium.height
        )
    }
}

struct ScanButton: View {
    @Binding var isScanning: Bool
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
                    .font(.system(size: 30, weight: .medium))
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

#Preview {
    ScannerView()
}