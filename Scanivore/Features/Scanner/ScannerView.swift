//
//  ScannerView.swift
//  Scanivore
//
//  TCA-powered scanner view for meat analysis
//

import SwiftUI
import ComposableArchitecture
import AVFoundation

// MARK: - Scanner Events
private enum ScannerEvent {
    case barcodeDetected(String)
    case scanFailed(ScannerError)
}

// MARK: - Scanner Feature Domain
@Reducer
struct ScannerFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var scanState: ScanState = .idle
        var scannedProductCode: String?
        var productName: String?
        var productBrand: String?
        var cameraPermissionStatus: CameraPermissionStatus = .notRequested
        var errorMessage: String?
        var isSessionActive: Bool = false
        
        enum ScanState: Equatable {
            case idle
            case requestingPermission
            case preparing
            case scanning
            case processing(barcode: String)
            case presentingDetail(productCode: String)
            case error(String)
        }
        
        var isScanning: Bool {
            switch scanState {
            case .scanning, .processing:
                return true
            default:
                return false
            }
        }
        
        var showingResults: Bool {
            if case .presentingDetail = scanState { return true }
            return false
        }
        
        var showingError: Bool {
            if case .error = scanState { return true }
            return false
        }
        
        var shouldShowCameraPreview: Bool {
            switch scanState {
            case .scanning, .processing:
                return true
            default:
                return isSessionActive
            }
        }
    }
    
    enum Action {
        case onAppear
        case onDisappear
        case permissionResponse(CameraPermissionStatus)
        case sessionStarted
        case barcodeDetected(String)
        case checkProductAvailability(String)
        case productAvailabilityResponse(String, TaskResult<Void>)
        case scanFailed(ScannerError)
        case resultsDismissed
        case errorDismissed
        case retryTapped
        case pauseDetection
        case resumeDetection
        case helpButtonTapped
    }
    
    @Dependency(\.barcodeScanner) var barcodeScanner
    @Dependency(\.productGateway) var productGateway
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // Auto-start camera when view appears
                guard state.scanState == .idle else { return .none }
                
                state.scanState = .requestingPermission
                print("🔍 Scanner: View appeared, requesting camera permission")
                
                return .run { send in
                    let permissionStatus = await barcodeScanner.requestCameraPermission()
                    print("🔍 Scanner: Permission status: \(permissionStatus)")
                    await send(.permissionResponse(permissionStatus))
                }
                
            case .onDisappear:
                // Stop scanning when view disappears
                barcodeScanner.stopScanning()
                state.isSessionActive = false
                state.scanState = .idle
                return .cancel(id: "scanner_session")
                
            case .permissionResponse(let status):
                state.cameraPermissionStatus = status
                
                switch status {
                case .granted:
                    state.scanState = .preparing
                    print("🔍 Scanner: Permission granted, starting session")
                    
                    return .run { send in
                        // Small delay to show preparing state
                        try await Task.sleep(for: .milliseconds(300))
                        await send(.sessionStarted)
                        
                        // Start the long-running scanner effect
                        for await event in AsyncStream<ScannerEvent> { continuation in
                            barcodeScanner.startScanning(
                                { barcode in
                                    print("🔍 Scanner: Barcode detected: \(barcode)")
                                    continuation.yield(.barcodeDetected(barcode))
                                },
                                { error in
                                    print("🔍 Scanner: Error occurred: \(error)")
                                    continuation.yield(.scanFailed(error))
                                }
                            )
                            
                            continuation.onTermination = { _ in
                                barcodeScanner.stopScanning()
                            }
                        } {
                            switch event {
                            case .barcodeDetected(let barcode):
                                await send(.barcodeDetected(barcode))
                            case .scanFailed(let error):
                                await send(.scanFailed(error))
                            }
                        }
                    }
                    .cancellable(id: "scanner_session")
                    
                case .denied, .restricted:
                    state.scanState = .error("Camera permission is required to scan barcodes. Please enable camera access in Settings.")
                    print("🔍 Scanner: Permission denied or restricted")
                    return .none
                    
                case .notRequested:
                    state.scanState = .idle
                    print("🔍 Scanner: Permission not requested")
                    return .none
                }
                
            case .sessionStarted:
                state.scanState = .scanning
                state.isSessionActive = true
                print("🔍 Scanner: Session started, ready to scan")
                return .none
                
            case .barcodeDetected(let barcode):
                // Don't stop scanning - keep session active for next scan
                state.scanState = .processing(barcode: barcode)
                print("🔍 Scanner: Processing barcode: \(barcode)")
                
                return .run { send in
                    // Brief delay for visual feedback
                    try await Task.sleep(for: .milliseconds(500))
                    
                    // Check if product exists before showing detail view
                    await send(.checkProductAvailability(barcode))
                }
                
            case .checkProductAvailability(let barcode):
                return .run { send in
                    await send(.productAvailabilityResponse(barcode, TaskResult {
                        // Try to get health assessment to check if product exists
                        _ = try await productGateway.getHealthAssessment(barcode)
                    }))
                }
                
            case .productAvailabilityResponse(let barcode, let result):
                switch result {
                case .success:
                    // Product exists, show detail view
                    state.scannedProductCode = barcode
                    state.scanState = .presentingDetail(productCode: barcode)
                    print("🔍 Scanner: Product found, presenting detail for: \(barcode)")
                    
                case .failure(let error):
                    // Show error but keep scanning session active
                    state.scanState = .error("Product not found in database. Try scanning again.")
                    print("🔍 Scanner: Product not found for: \(barcode)")
                    
                    // Auto-dismiss error after 3 seconds and return to scanning
                    return .run { send in
                        try await Task.sleep(for: .seconds(3))
                        await send(.errorDismissed)
                    }
                }
                return .none
                
            case .scanFailed(let error):
                state.scanState = .error(error.localizedDescription)
                
                // Auto-retry after 2 seconds
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.retryTapped)
                }
                
            case .resultsDismissed:
                // Return to scanning state, keep session active
                state.scanState = .scanning
                state.scannedProductCode = nil
                state.productName = nil
                state.productBrand = nil
                return .none
                
            case .errorDismissed:
                // Return to scanning state
                state.scanState = .scanning
                state.errorMessage = nil
                return .none
                
            case .retryTapped:
                // Restart scanning
                state.scanState = .scanning
                state.errorMessage = nil
                return .none
                
            case .pauseDetection:
                barcodeScanner.pauseDetection()
                return .none
                
            case .resumeDetection:
                barcodeScanner.resumeDetection()
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
    
    // MARK: - Computed Properties
    
    private var isShowingResults: Binding<Bool> {
        Binding(
            get: { store.showingResults },
            set: { _ in store.send(.resultsDismissed) }
        )
    }
    
    private var cameraPreviewView: some View {
        CameraPreviewView()
            .ignoresSafeArea()
    }
    
    private var barcodeFrameOverlay: some View {
        VStack {
            Spacer()
            
            // Barcode alignment frame
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Align barcode within frame")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 2)
                
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(Color.white, lineWidth: 3)
                    .frame(height: 120)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .scaleEffect(store.isScanning ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: store.isScanning)
            }
            
            Spacer()
            
            // Status indicator at bottom
            StatusIndicator(scanState: store.scanState)
                .padding(.bottom, DesignSystem.Spacing.xxxl)
        }
    }
    
    private var stateOverlays: some View {
        Group {
            if store.scanState == .requestingPermission {
                PermissionOverlay()
            } else if store.scanState == .preparing {
                PreparingOverlay()
            } else if case .error(let message) = store.scanState {
                ErrorToast(message: message) {
                    store.send(.errorDismissed)
                }
            }
        }
    }
    
    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { store.send(.helpButtonTapped) }) {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.white)
            }
        }
    }
    
    @ViewBuilder
    private func productDetailSheet() -> some View {
        if let productCode = store.scannedProductCode {
            ProductDetailView(
                store: Store(
                    initialState: ProductDetailFeatureDomain.State(
                        productCode: productCode,
                        productName: store.productName,
                        productBrand: store.productBrand
                    )
                ) {
                    ProductDetailFeatureDomain()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .onAppear {
                store.send(.pauseDetection)
            }
            .onDisappear {
                store.send(.resumeDetection)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    // Camera preview - always visible as background
                    cameraPreviewView
                    
                    // Persistent barcode framing overlay
                    barcodeFrameOverlay
                    
                    // Temporary overlays for specific states
                    stateOverlays
                }
                .customNavigationTitle("Scan Product")
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    navigationToolbar
                }
                .sheet(isPresented: isShowingResults) {
                    productDetailSheet()
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onDisappear {
            store.send(.onDisappear)
        }
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let scanState: ScannerFeatureDomain.State.ScanState
    
    var body: some View {
        switch scanState {
        case .scanning:
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "viewfinder")
                    .foregroundColor(.white)
                Text("Ready to scan")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(Color.black.opacity(0.6))
            .cornerRadius(DesignSystem.CornerRadius.md)
            
        case .processing(let barcode):
            HStack(spacing: DesignSystem.Spacing.sm) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                Text("Analyzing product...")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(Color.black.opacity(0.6))
            .cornerRadius(DesignSystem.CornerRadius.md)
            
        default:
            EmptyView()
        }
    }
}

// MARK: - Error Toast

struct ErrorToast: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                Text(message)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                Spacer()
                Button("Dismiss") {
                    onDismiss()
                }
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(.white)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.error)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .shadow(color: .black.opacity(0.3), radius: 4)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.md)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: message)
    }
}

#Preview {
    ScannerView(
        store: Store(
            initialState: ScannerFeatureDomain.State()
        ) {
            ScannerFeatureDomain()
        } withDependencies: {
            $0.barcodeScanner = .previewValue
        }
    )
}