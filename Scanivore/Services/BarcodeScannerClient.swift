//
//  BarcodeScannerClient.swift
//  Scanivore
//
//  Barcode scanning client using native iOS Vision framework
//

import Foundation
import AVFoundation
import Vision
import ComposableArchitecture

// MARK: - Notification Names

extension Notification.Name {
    static let scannerPreviewLayerReady = Notification.Name("scannerPreviewLayerReady")
}

// MARK: - Barcode Scanner Client

@DependencyClient
struct BarcodeScannerClient: Sendable {
    var requestCameraPermission: @Sendable () async -> CameraPermissionStatus = { .notRequested }
    var startScanning: @Sendable (@escaping (String) -> Void, @escaping (ScannerError) -> Void) -> Void = { _, _ in }
    var stopScanning: @Sendable () -> Void = { }
}

// MARK: - Models

enum CameraPermissionStatus: Equatable, Sendable {
    case notRequested
    case granted
    case denied
    case restricted
}

enum ScannerError: Error, Equatable, Sendable {
    case cameraPermissionDenied
    case cameraUnavailable
    case scanningFailed(String)
    case invalidBarcode
    
    var localizedDescription: String {
        switch self {
        case .cameraPermissionDenied:
            return "Camera permission is required to scan barcodes"
        case .cameraUnavailable:
            return "Camera is not available on this device"
        case .scanningFailed(let message):
            return "Scanning failed: \(message)"
        case .invalidBarcode:
            return "Invalid or unrecognized barcode format"
        }
    }
}

// MARK: - Live Implementation

extension BarcodeScannerClient: DependencyKey {
    static let liveValue = BarcodeScannerClient(
        requestCameraPermission: {
            await withCheckedContinuation { continuation in
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                
                switch status {
                case .authorized:
                    continuation.resume(returning: .granted)
                case .denied, .restricted:
                    continuation.resume(returning: .denied)
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        continuation.resume(returning: granted ? .granted : .denied)
                    }
                @unknown default:
                    continuation.resume(returning: .denied)
                }
            }
        },
        
        startScanning: { onBarcodeDetected, onError in
            Task { @MainActor in
                do {
                    // Create and retain the scanner instance
                    if BarcodeScanner.shared == nil {
                        BarcodeScanner.shared = BarcodeScanner()
                    }
                    
                    try BarcodeScanner.shared?.startScanning(
                        onBarcodeDetected: onBarcodeDetected,
                        onError: onError
                    )
                } catch {
                    onError(.cameraUnavailable)
                }
            }
        },
        
        stopScanning: {
            Task { @MainActor in
                BarcodeScanner.shared?.stopScanning()
                BarcodeScanner.shared = nil
            }
        }
    )
}

// MARK: - Test Implementation

extension BarcodeScannerClient: TestDependencyKey {
    static let testValue = BarcodeScannerClient()
    
    static let previewValue = BarcodeScannerClient(
        requestCameraPermission: { 
            // Simulate permission request delay
            try? await Task.sleep(nanoseconds: 500_000_000)
            return .granted 
        },
        startScanning: { onBarcodeDetected, _ in
            // Simulate barcode detection after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onBarcodeDetected("0002000003197") // Mock barcode for testing
            }
        },
        stopScanning: { }
    )
}

// MARK: - Dependency Registration

extension DependencyValues {
    var barcodeScanner: BarcodeScannerClient {
        get { self[BarcodeScannerClient.self] }
        set { self[BarcodeScannerClient.self] = newValue }
    }
}

// MARK: - Barcode Scanner Implementation

@MainActor
class BarcodeScanner: NSObject, ObservableObject {
    static var shared: BarcodeScanner?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var onBarcodeDetected: ((String) -> Void)?
    private var onError: ((ScannerError) -> Void)?
    private var lastDetectedBarcode: String?
    private var lastDetectionTime: Date?
    
    override init() {
        super.init()
    }
    
    func startScanning(
        onBarcodeDetected: @escaping (String) -> Void,
        onError: @escaping (ScannerError) -> Void
    ) throws {
        print("📸 BarcodeScanner: Starting scanning session")
        
        self.onBarcodeDetected = onBarcodeDetected
        self.onError = onError
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("📸 BarcodeScanner: No camera device available")
            throw ScannerError.cameraUnavailable
        }
        
        print("📸 BarcodeScanner: Camera device found: \(captureDevice.localizedName)")
        
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        // Configure session preset for better barcode detection
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("📸 BarcodeScanner: Camera input added successfully")
            } else {
                throw ScannerError.scanningFailed("Failed to add camera input")
            }
        } catch {
            print("📸 BarcodeScanner: Failed to create camera input: \(error)")
            throw ScannerError.scanningFailed("Failed to create camera input: \(error.localizedDescription)")
        }
        
        let captureMetadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(captureMetadataOutput) {
            captureSession.addOutput(captureMetadataOutput)
            print("📸 BarcodeScanner: Metadata output added successfully")
        } else {
            throw ScannerError.scanningFailed("Failed to add metadata output")
        }
        
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        // Support multiple barcode formats commonly found on food products
        captureMetadataOutput.metadataObjectTypes = [
            .ean8, .ean13, .pdf417, .qr, .upce, .code128, .code39, .code93,
            .interleaved2of5, .itf14, .dataMatrix
        ]
        
        print("📸 BarcodeScanner: Supported barcode types configured")
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
        
        print("📸 BarcodeScanner: Preview layer created")
        
        // Start the capture session
        DispatchQueue.global(qos: .userInitiated).async { [weak captureSession] in
            captureSession?.startRunning()
            print("📸 BarcodeScanner: Capture session started running")
            
            // Notify that preview layer is ready
            DispatchQueue.main.async {
                print("📸 BarcodeScanner: Notifying preview layer is ready")
                NotificationCenter.default.post(
                    name: .scannerPreviewLayerReady,
                    object: previewLayer
                )
            }
        }
    }
    
    func stopScanning() {
        print("📸 BarcodeScanner: Stopping scanning session")
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        onBarcodeDetected = nil
        onError = nil
        lastDetectedBarcode = nil
        lastDetectionTime = nil
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        print("📸 BarcodeScanner: Detected barcode type: \(readableObject.type.rawValue), value: \(stringValue)")
        
        // Validate barcode format for food products
        if isValidFoodBarcode(stringValue) {
            // Debounce: Ignore if same barcode detected within 2 seconds
            let now = Date()
            if let lastBarcode = lastDetectedBarcode,
               let lastTime = lastDetectionTime,
               lastBarcode == stringValue,
               now.timeIntervalSince(lastTime) < 2.0 {
                print("📸 BarcodeScanner: Ignoring duplicate barcode (debounce)")
                return
            }
            
            lastDetectedBarcode = stringValue
            lastDetectionTime = now
            
            print("📸 BarcodeScanner: Valid barcode detected, calling handler")
            
            // Don't stop scanning here - let the reducer handle it
            // This prevents the preview from going black immediately
            onBarcodeDetected?(stringValue)
        } else {
            print("📸 BarcodeScanner: Invalid barcode format: \(stringValue)")
        }
    }
    
    private func isValidFoodBarcode(_ barcode: String) -> Bool {
        // Basic validation for common food product barcode formats
        let trimmed = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // EAN-13 (13 digits), UPC-A (12 digits), EAN-8 (8 digits)
        if trimmed.count == 13 || trimmed.count == 12 || trimmed.count == 8 {
            return trimmed.allSatisfy { $0.isNumber }
        }
        
        // Allow other formats for flexibility
        return trimmed.count >= 8 && trimmed.count <= 20
    }
}