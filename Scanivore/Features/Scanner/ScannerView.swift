
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
        var cameraPermissionStatus: CameraPermissionStatus = .notRequested
        var errorMessage: String?
        var isSessionActive: Bool = false
        @Presents var destination: Destination.State?
        
        enum ScanState: Equatable {
            case idle
            case requestingPermission
            case preparing
            case scanning
            case processing(barcode: String)
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
    
    @Reducer(state: .equatable, action: .equatable)
    enum Destination {
        case productDetail(ProductDetailFeatureDomain)
    }
    
    enum Action: Equatable {
        case onAppear
        case onDisappear
        case permissionReceived(CameraPermissionStatus)
        case sessionStarted
        case barcodeDetected(String)
        case scanFailed(ScannerError)
        case destination(PresentationAction<Destination.Action>)
        case errorDismissed
        case retryTapped
        case pauseDetection
        case resumeDetection
        case helpButtonTapped
    }
    
    @Dependency(\.barcodeScanner) var barcodeScanner
    @Dependency(\.productGateway) var productGateway
    @Dependency(\.scannedProducts) var scannedProducts
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.scanState == .idle else { return .none }
                
                state.scanState = .requestingPermission
                
                return .run { send in
                    let permissionStatus = await barcodeScanner.requestCameraPermission()
                    await send(.permissionReceived(permissionStatus))
                }
                
            case .onDisappear:
                barcodeScanner.stopScanning()
                state.isSessionActive = false
                state.scanState = .idle
                return .cancel(id: "scanner_session")
                
            case .permissionReceived(let status):
                state.cameraPermissionStatus = status
                
                switch status {
                case .granted:
                    state.scanState = .preparing
                    
                    return .run { send in
                        try await Task.sleep(for: .milliseconds(300))
                        await send(.sessionStarted)
                        
                        for await event in AsyncStream<ScannerEvent> { continuation in
                            barcodeScanner.startScanning(
                                { barcode in
                                    continuation.yield(.barcodeDetected(barcode))
                                },
                                { error in
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
                    return .none
                    
                case .notRequested:
                    state.scanState = .idle
                    return .none
                }
                
            case .sessionStarted:
                state.scanState = .scanning
                state.isSessionActive = true
                return .none
                
            case .barcodeDetected(let barcode):
                state.scanState = .processing(barcode: barcode)
                
                state.destination = .productDetail(
                    ProductDetailFeatureDomain.State(
                        productCode: barcode,
                        context: .scanned
                    )
                )
                state.scanState = .scanning
                return .none
                
            case .scanFailed(let error):
                state.scanState = .error(error.localizedDescription)
                
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.retryTapped)
                }
                
            case .destination:
                return .none
                
            case .errorDismissed:
                state.scanState = .scanning
                state.errorMessage = nil
                return .none
                
            case .retryTapped:
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
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}


struct ScannerView: View {
    let store: StoreOf<ScannerFeatureDomain>
    
    private var cameraPreviewView: some View {
        CameraPreviewView()
            .ignoresSafeArea()
    }
    
    private var barcodeFrameOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Align barcode within frame")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.background)
                    .shadow(color: DesignSystem.Shadow.heavy, radius: DesignSystem.Shadow.radiusLight)
                
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.background, lineWidth: 3)
                    .frame(height: 120)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .scaleEffect(store.isScanning ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: store.isScanning)
            }
            
            Spacer()
            
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
    
    // MARK: - Body
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    cameraPreviewView
                    
                    barcodeFrameOverlay
                    
                    stateOverlays
                }
                .customNavigationTitle("Scan Product")
                .toolbarBackground(DesignSystem.Colors.textPrimary, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .sheet(
                    store: store.scope(
                        state: \.$destination.productDetail,
                        action: \.destination.productDetail
                    )
                ) { store in
                    ProductDetailView(store: store)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .interactiveDismissDisabled(false)
                        .onAppear {
                            self.store.send(.pauseDetection)
                        }
                        .onDisappear {
                            self.store.send(.resumeDetection)
                        }
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
            .background(DesignSystem.Colors.textPrimary.opacity(0.6))
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
            .background(DesignSystem.Colors.textPrimary.opacity(0.6))
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
