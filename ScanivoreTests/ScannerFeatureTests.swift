//
//  ScannerFeatureTests.swift
//  ScanivoreTests
//
//  Unit tests for the barcode scanner feature
//

import XCTest
import ComposableArchitecture
@testable import Scanivore

@MainActor
final class ScannerFeatureTests: XCTestCase {
    
    func testScanButtonTapped_RequestsCameraPermission() async {
        let store = TestStore(initialState: ScannerFeatureDomain.State()) {
            ScannerFeatureDomain()
        } withDependencies: {
            $0.barcodeScanner = .testValue
        }
        
        await store.send(.scanButtonTapped) {
            $0.scanState = .requestingPermission
            $0.errorMessage = nil
        }
    }
    
    func testPermissionGranted_StartsScanningFlow() async {
        let store = TestStore(initialState: ScannerFeatureDomain.State()) {
            ScannerFeatureDomain()
        } withDependencies: {
            $0.barcodeScanner.startScanning = { _, _ in }
            $0.barcodeScanner = .testValue
        }
        
        await store.send(.permissionResponse(.granted)) {
            $0.cameraPermissionStatus = .granted
            $0.scanState = .preparing
        }
    }
    
    func testPermissionDenied_ShowsError() async {
        let store = TestStore(initialState: ScannerFeatureDomain.State()) {
            ScannerFeatureDomain()
        } withDependencies: {
            $0.barcodeScanner = .testValue
        }
        
        await store.send(.permissionResponse(.denied)) {
            $0.cameraPermissionStatus = .denied
            $0.scanState = .error("Camera permission is required to scan barcodes. Please enable camera access in Settings.")
        }
    }
    
    func testBarcodeDetected_CallsAPIAndProcesses() async {
        let mockMeatScan = MeatScan.mockMeatScan(barcode: "123456789012")
        
        let store = TestStore(initialState: ScannerFeatureDomain.State()) {
            ScannerFeatureDomain()
        } withDependencies: {
            $0.barcodeScanner.stopScanning = { }
            $0.productGateway.getMeatScanFromBarcode = { _ in mockMeatScan }
        }
        
        await store.send(.barcodeDetected("123456789012")) {
            $0.scanState = .processing(barcode: "123456789012")
        }
        
        await store.receive(.scanCompleted(mockMeatScan)) {
            $0.scanState = .completed(mockMeatScan)
            $0.scanResult = mockMeatScan
        }
    }
    
    func testBarcodeDetected_APIError_ShowsError() async {
        struct APIError: Error, LocalizedError {
            let errorDescription: String? = "Network error"
        }
        
        let store = TestStore(initialState: ScannerFeatureDomain.State()) {
            ScannerFeatureDomain()
        } withDependencies: {
            $0.barcodeScanner.stopScanning = { }
            $0.productGateway.getMeatScanFromBarcode = { _ in throw APIError() }
        }
        
        await store.send(.barcodeDetected("123456789012")) {
            $0.scanState = .processing(barcode: "123456789012")
        }
        
        await store.receive(.apiError(APIError())) {
            $0.scanState = .error("Failed to analyze product: Network error")
        }
    }
    
    func testScanFailed_ShowsError() async {
        let scannerError = ScannerError.cameraUnavailable
        
        let store = TestStore(initialState: ScannerFeatureDomain.State()) {
            ScannerFeatureDomain()
        } withDependencies: {
            $0.barcodeScanner.stopScanning = { }
        }
        
        await store.send(.scanFailed(scannerError)) {
            $0.scanState = .error(scannerError.localizedDescription)
        }
    }
    
    func testCancelScan_ResetsState() async {
        let store = TestStore(
            initialState: ScannerFeatureDomain.State(
                scanState: .scanning,
                scanResult: .mockMeatScan(barcode: "test")
            )
        ) {
            ScannerFeatureDomain()
        } withDependencies: {
            $0.barcodeScanner.stopScanning = { }
        }
        
        await store.send(.cancelScan) {
            $0.scanState = .idle
            $0.scanResult = nil
        }
    }
    
    func testResultsDismissed_ResetsState() async {
        let mockScan = MeatScan.mockMeatScan(barcode: "test")
        let store = TestStore(
            initialState: ScannerFeatureDomain.State(
                scanState: .completed(mockScan),
                scanResult: mockScan
            )
        ) {
            ScannerFeatureDomain()
        }
        
        await store.send(.resultsDismissed) {
            $0.scanState = .idle
            $0.scanResult = nil
        }
    }
    
    func testErrorDismissed_ResetsState() async {
        let store = TestStore(
            initialState: ScannerFeatureDomain.State(
                scanState: .error("Test error"),
                errorMessage: "Test error"
            )
        ) {
            ScannerFeatureDomain()
        }
        
        await store.send(.errorDismissed) {
            $0.scanState = .idle
            $0.errorMessage = nil
        }
    }
    
    func testScanStateComputedProperties() {
        var state = ScannerFeatureDomain.State()
        
        // Test idle state
        XCTAssertFalse(state.isScanning)
        XCTAssertFalse(state.showingResults)
        XCTAssertFalse(state.showingError)
        
        // Test scanning state
        state.scanState = .scanning
        XCTAssertTrue(state.isScanning)
        XCTAssertFalse(state.showingResults)
        XCTAssertFalse(state.showingError)
        
        // Test processing state
        state.scanState = .processing(barcode: "123")
        XCTAssertTrue(state.isScanning)
        XCTAssertFalse(state.showingResults)
        XCTAssertFalse(state.showingError)
        
        // Test completed state
        let mockScan = MeatScan.mockMeatScan(barcode: "test")
        state.scanState = .completed(mockScan)
        XCTAssertFalse(state.isScanning)
        XCTAssertTrue(state.showingResults)
        XCTAssertFalse(state.showingError)
        
        // Test error state
        state.scanState = .error("Test error")
        XCTAssertFalse(state.isScanning)
        XCTAssertFalse(state.showingResults)
        XCTAssertTrue(state.showingError)
    }
}

// MARK: - Test Helpers

extension ScannerError: Equatable {
    public static func == (lhs: ScannerError, rhs: ScannerError) -> Bool {
        switch (lhs, rhs) {
        case (.cameraPermissionDenied, .cameraPermissionDenied),
             (.cameraUnavailable, .cameraUnavailable),
             (.invalidBarcode, .invalidBarcode):
            return true
        case (.scanningFailed(let lhsMessage), .scanningFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Mock Extensions for Testing

extension MeatScan {
    static func mockMeatScan(barcode: String) -> MeatScan {
        MeatScan(
            date: Date(),
            image: barcode,
            meatType: .beef,
            quality: QualityRating(score: 85, grade: "B+"),
            freshness: .fresh,
            nutritionInfo: NutritionInfo(
                calories: 250,
                protein: 26.0,
                fat: 17.0,
                saturatedFat: 7.0,
                cholesterol: 80,
                sodium: 75
            ),
            warnings: [],
            recommendations: ["High-quality protein source"]
        )
    }
}