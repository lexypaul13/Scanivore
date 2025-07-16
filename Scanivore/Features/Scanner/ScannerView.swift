//
//  ScannerView.swift
//  Scanivore
//
//  TCA-powered scanner view for meat analysis
//

import SwiftUI
import ComposableArchitecture
import AVFoundation

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
        
        enum ScanState: Equatable {
            case idle
            case requestingPermission
            case preparing
            case scanning
            case processing(barcode: String)
            case presentingDetail(productCode: String)
            case productNotFound(barcode: String)
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
    }
    
    enum Action {
        case scanButtonTapped
        case permissionResponse(CameraPermissionStatus)
        case scanningStarted
        case barcodeDetected(String)
        case checkProductAvailability(String)
        case productAvailabilityResponse(String, TaskResult<Void>)
        case productDetailReady
        case productNotFound(String)
        case scanFailed(ScannerError)
        case cancelScan
        case resultsDismissed
        case productNotFoundDismissed
        case errorDismissed
        case helpButtonTapped
    }
    
    @Dependency(\.barcodeScanner) var barcodeScanner
    @Dependency(\.productGateway) var productGateway
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .scanButtonTapped:
                state.scanState = .requestingPermission
                state.errorMessage = nil
                
                print("🔍 Scanner: Scan button tapped")
                
                return .run { send in
                    let permissionStatus = await barcodeScanner.requestCameraPermission()
                    print("🔍 Scanner: Permission status: \(permissionStatus)")
                    await send(.permissionResponse(permissionStatus))
                }
                
            case .permissionResponse(let status):
                state.cameraPermissionStatus = status
                
                switch status {
                case .granted:
                    state.scanState = .preparing
                    print("🔍 Scanner: Permission granted, preparing scanner")
                    
                    return .run { send in
                        // Start barcode scanning
                        await withTaskGroup(of: Void.self) { group in
                            group.addTask {
                                barcodeScanner.startScanning(
                                    { barcode in
                                        print("🔍 Scanner: Barcode detected: \(barcode)")
                                        Task {
                                            await send(.barcodeDetected(barcode))
                                        }
                                    },
                                    { error in
                                        print("🔍 Scanner: Error occurred: \(error)")
                                        Task {
                                            await send(.scanFailed(error))
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Small delay to show preparing state
                        try await Task.sleep(for: .milliseconds(500))
                        await send(.scanningStarted)
                    }
                    
                case .denied, .restricted:
                    state.scanState = .error("Camera permission is required to scan barcodes. Please enable camera access in Settings.")
                    print("🔍 Scanner: Permission denied or restricted")
                    return .none
                    
                case .notRequested:
                    state.scanState = .idle
                    print("🔍 Scanner: Permission not requested")
                    return .none
                }
                
            case .scanningStarted:
                state.scanState = .scanning
                print("🔍 Scanner: Scanning started")
                return .none
                
            case .barcodeDetected(let barcode):
                state.scanState = .processing(barcode: barcode)
                print("🔍 Scanner: Processing barcode: \(barcode)")
                
                return .run { send in
                    // Stop scanning first
                    barcodeScanner.stopScanning()
                    
                    // Brief delay to show processing state
                    try await Task.sleep(for: .milliseconds(800))
                    
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
                    // Check if it's a 404 error
                    if let apiError = error as? APIError, apiError.statusCode == 404 {
                        // Product not found, show ProductNotFoundView
                        state.scanState = .productNotFound(barcode: barcode)
                        print("🔍 Scanner: Product not found (404) for: \(barcode)")
                    } else {
                        // Other error, still try to show detail view (may show graceful fallback)
                        state.scannedProductCode = barcode
                        state.scanState = .presentingDetail(productCode: barcode)
                        print("🔍 Scanner: Product check failed with non-404 error, showing detail anyway for: \(barcode)")
                    }
                }
                return .none
            
            case .productDetailReady:
                // This action is now handled by productAvailabilityResponse
                return .none
                
            case .scanFailed(let error):
                barcodeScanner.stopScanning()
                state.scanState = .error(error.localizedDescription)
                return .none
                
            case .cancelScan:
                barcodeScanner.stopScanning()
                state.scanState = .idle
                state.scannedProductCode = nil
                state.productName = nil
                state.productBrand = nil
                return .none
                
            case .resultsDismissed:
                state.scanState = .idle
                state.scannedProductCode = nil
                state.productName = nil
                state.productBrand = nil
                return .none
                
            case .productNotFound(let barcode):
                state.scanState = .productNotFound(barcode: barcode)
                return .none
                
            case .productNotFoundDismissed:
                state.scanState = .idle
                state.scannedProductCode = nil
                state.productName = nil
                state.productBrand = nil
                return .none
                
            case .errorDismissed:
                state.scanState = .idle
                state.errorMessage = nil
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
                        
                        // Show different overlays based on scan state
                        switch store.scanState {
                        case .requestingPermission:
                            PermissionOverlay()
                        case .preparing:
                            PreparingOverlay()
                        case .scanning:
                            ScanningActiveOverlay()
                        case .processing(let barcode):
                            ProcessingOverlay(barcode: barcode)
                        case .error(let message):
                            ErrorOverlay(message: message) {
                                store.send(.errorDismissed)
                            }
                        case .productNotFound(let barcode):
                            ProductNotFoundOverlay(barcode: barcode) {
                                store.send(.productNotFoundDismissed)
                            }
                        case .idle, .presentingDetail:
                            EmptyView()
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
                    }
                }
            }
        }
        .onDisappear {
            store.send(.cancelScan)
        }
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