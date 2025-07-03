//
//  ScannerView.swift
//  Scanivore
//
//  TCA-powered scanner view for meat analysis
//

import SwiftUI
import ComposableArchitecture

// MARK: - Scanner Feature Domain
@Reducer
struct ScannerFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var scanState: ScanState = .idle
        var scanResult: MeatScan?
        
        enum ScanState: Equatable {
            case idle
            case scanning(progress: Double)
            case completed(MeatScan)
        }
        
        var isScanning: Bool {
            if case .scanning = scanState { return true }
            return false
        }
        
        var scanProgress: Double {
            if case .scanning(let progress) = scanState { return progress }
            return 0
        }
        
        var showingResults: Bool {
            if case .completed = scanState { return true }
            return false
        }
    }
    
    enum Action {
        case scanButtonTapped
        case scanProgressTick
        case scanCompleted(MeatScan)
        case cancelScan
        case resultsDismissed
        case helpButtonTapped
    }
    
    @Dependency(\.continuousClock) var clock
    
    private enum ScanTimerID: Hashable {
        case scanner
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .scanButtonTapped:
                state.scanState = .scanning(progress: 0)
                
                return .run { send in
                    await withTaskCancellation(id: ScanTimerID.scanner, cancelInFlight: true) {
                        var progress: Double = 0
                        
                        for await _ in clock.timer(interval: .milliseconds(100)) {
                            progress += 0.05
                            
                            if progress >= 1.0 {
                                let mockResult = MeatScan.mockScans.randomElement()!
                                await send(.scanCompleted(mockResult))
                                break
                            } else {
                                await send(.scanProgressTick)
                            }
                        }
                    }
                }
                
            case .scanProgressTick:
                if case .scanning(let currentProgress) = state.scanState {
                    let newProgress = min(currentProgress + 0.05, 1.0)
                    state.scanState = .scanning(progress: newProgress)
                }
                return .none
                
            case .scanCompleted(let result):
                state.scanState = .completed(result)
                state.scanResult = result
                return .cancel(id: ScanTimerID.scanner)
                
            case .cancelScan:
                state.scanState = .idle
                state.scanResult = nil
                return .cancel(id: ScanTimerID.scanner)
                
            case .resultsDismissed:
                state.scanState = .idle
                state.scanResult = nil
                return .none
                
            case .helpButtonTapped:
                // TODO: Implement help functionality
                return .none
            }
        }
    }
}

struct ScannerView: View {
    let store: StoreOf<ScannerFeatureDomain>
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    DesignSystem.Colors.background
                        .ignoresSafeArea()
                    
                    CameraPreviewView()
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        if store.isScanning {
                            ScanningOverlay(progress: store.scanProgress)
                        }
                        
                        ScanButton(
                            isScanning: store.isScanning,
                            action: { store.send(.scanButtonTapped) }
                        )
                        .padding(.bottom, DesignSystem.Spacing.xxxxxl)
                    }
                }
                .customNavigationTitle("Scan Meat")
                .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { store.send(.helpButtonTapped) }) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(DesignSystem.Colors.primaryRed)
                        }
                    }
                }
                .sheet(isPresented: .init(
                    get: { store.showingResults },
                    set: { _ in store.send(.resultsDismissed) }
                )) {
                    if let result = store.scanResult {
                        ProductDetailView(scan: result)
                    }
                }
            }
        }
        .onDisappear {
            store.send(.cancelScan)
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
    let progress: Double
    
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
                .font(DesignSystem.Typography.heading1)
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

#Preview {
    ScannerView(
        store: Store(
            initialState: ScannerFeatureDomain.State()
        ) {
            ScannerFeatureDomain()
        }
    )
}