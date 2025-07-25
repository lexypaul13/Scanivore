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
    var pauseDetection: @Sendable () -> Void = { }
    var resumeDetection: @Sendable () -> Void = { }
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
        },
        
        pauseDetection: {
            Task { @MainActor in
                BarcodeScanner.shared?.pauseDetection()
            }
        },
        
        resumeDetection: {
            Task { @MainActor in
                BarcodeScanner.shared?.resumeDetection()
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
        stopScanning: { },
        pauseDetection: { },
        resumeDetection: { }
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
    private var isDetectionActive: Bool = true
    
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
        self.isDetectionActive = true
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("📸 BarcodeScanner: No camera device available")
            throw ScannerError.cameraUnavailable
        }
        
        print("📸 BarcodeScanner: Camera device found: \(captureDevice.localizedName)")
        
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        // Configure session preset for optimal performance
        if captureDevice.supportsSessionPreset(.high) {
            captureSession.sessionPreset = .high
        } else {
            captureSession.sessionPreset = .medium
        }
        
        // Configure capture device for better barcode detection
        do {
            try captureDevice.lockForConfiguration()
            
            // Enable auto-focus if available
            if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice.focusMode = .continuousAutoFocus
            }
            
            // Enable auto-exposure if available
            if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                captureDevice.exposureMode = .continuousAutoExposure
            }
            
            captureDevice.unlockForConfiguration()
        } catch {
            print("📸 BarcodeScanner: Failed to configure capture device: \(error)")
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
        
        // Set up metadata detection on main queue for better performance
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        // Focus on most common barcode types for food products
        captureMetadataOutput.metadataObjectTypes = [
            .ean13, .ean8, .upce, .code128, .code39, .qr, .pdf417, .itf14
        ]
        
        // Expand detection area for better usability (80% width, 80% height, centered)
        let centerRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
        captureMetadataOutput.rectOfInterest = centerRect
        
        print("📸 BarcodeScanner: Detection area expanded to \(centerRect) with enhanced barcode types")
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
        
        print("📸 BarcodeScanner: Preview layer created")
        
        // Start the capture session on a background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self, weak captureSession] in
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
        isDetectionActive = false
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.captureSession?.stopRunning()
            
            DispatchQueue.main.async {
                self?.captureSession = nil
                self?.previewLayer = nil
                self?.onBarcodeDetected = nil
                self?.onError = nil
                self?.lastDetectedBarcode = nil
                self?.lastDetectionTime = nil
            }
        }
    }
    
    func pauseDetection() {
        isDetectionActive = false
        print("📸 BarcodeScanner: Detection paused")
    }
    
    func resumeDetection() {
        isDetectionActive = true
        print("📸 BarcodeScanner: Detection resumed")
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
        // Skip processing if detection is paused
        guard isDetectionActive else { return }
        
        // Process only the first detected barcode for better performance
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue,
              !stringValue.isEmpty else {
            return
        }
        
        print("🔍 BARCODE DETECTED: '\(stringValue)' (\(readableObject.type.rawValue))")
        print("🔍 BARCODE LENGTH: \(stringValue.count) digits")
        print("🔍 BARCODE TYPE: \(readableObject.type.rawValue)")
        
        // Validate checksum on original format
        if isValidBarcodeChecksum(stringValue) {
            print("✅ Valid checksum for \(stringValue)")
            
            // Process barcode based on actual type and length - NO AUTOMATIC CONVERSION
            var processedValue = stringValue
            
            // Only convert 13-digit EAN-13 codes starting with 0 to 12-digit UPC-A
            if readableObject.type == .ean13 && stringValue.hasPrefix("0") && stringValue.count == 13 {
                processedValue = String(stringValue.dropFirst())
                print("📸 EAN-13 to UPC-A conversion: \(stringValue) → \(processedValue)")
            } else {
                print("📸 Using barcode as-is: \(stringValue) (no conversion needed)")
            }
            
            // Debounce: Ignore if same barcode detected within 1 second (reduced from 1.5s)
            let now = Date()
            if let lastBarcode = lastDetectedBarcode,
               let lastTime = lastDetectionTime,
               lastBarcode == processedValue,
               now.timeIntervalSince(lastTime) < 1.0 {
                print("📸 BarcodeScanner: Ignoring duplicate barcode (debounce)")
                return
            }
            
            lastDetectedBarcode = processedValue
            lastDetectionTime = now
            
            // Pause detection temporarily to prevent multiple triggers
            pauseDetection()
            
            print("🎯 PRODUCT CODE FOR LOOKUP: '\(processedValue)'")
            
            // Call the handler
            onBarcodeDetected?(processedValue)
            
            // Resume detection after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.resumeDetection()
            }
        } else {
            print("📸 Invalid checksum, skipping: \(stringValue)")
        }
    }
    
    private func isValidBarcodeChecksum(_ barcode: String) -> Bool {
        guard barcode.allSatisfy({ $0.isNumber }) else { return false }
        
        let digits = barcode.compactMap { Int(String($0)) }
        guard digits.count >= 8 else { return false }
        
        // For UPC-A (12 digits) and EAN-13 (13 digits) checksum calculation
        if digits.count == 12 || digits.count == 13 {
            var sum = 0
            let dataDigits = digits.dropLast()
            
            for (index, digit) in dataDigits.enumerated() {
                // UPC-A/EAN-13: odd positions (1st, 3rd, 5th...) get weight 1, even positions get weight 3
                // But in 0-based indexing, this is reversed
                if digits.count == 12 {
                    // UPC-A: positions 0,2,4,6,8,10 get weight 1, positions 1,3,5,7,9 get weight 3
                    sum += digit * (index % 2 == 0 ? 1 : 3)
                } else {
                    // EAN-13: positions 0,2,4,6,8,10,12 get weight 1, positions 1,3,5,7,9,11 get weight 3
                    sum += digit * (index % 2 == 0 ? 1 : 3)
                }
            }
            let checksum = (10 - (sum % 10)) % 10
            let isValid = checksum == digits.last
            
            if !isValid {
                print("📸 Checksum debug for \(barcode): sum=\(sum), calculated=\(checksum), expected=\(digits.last ?? -1)")
            }
            
            return isValid
        }
        
        // For other formats, just validate it's numeric and reasonable length
        return digits.count >= 8 && digits.count <= 20
    }
    
    private func isValidFoodBarcode(_ barcode: String) -> Bool {
        // This method is now replaced by isValidBarcodeChecksum for better validation
        return isValidBarcodeChecksum(barcode)
    }
}
