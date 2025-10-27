
import Foundation
@preconcurrency import AVFoundation
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
            try? await Task.sleep(nanoseconds: 500_000_000)
            return .granted 
        },
        startScanning: { onBarcodeDetected, _ in
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
        
        self.onBarcodeDetected = onBarcodeDetected
        self.onError = onError
        self.isDetectionActive = true
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            throw ScannerError.cameraUnavailable
        }
        
        
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        if captureDevice.supportsSessionPreset(.high) {
            captureSession.sessionPreset = .high
        } else {
            captureSession.sessionPreset = .medium
        }
        
        do {
            try captureDevice.lockForConfiguration()
            
            if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
                captureDevice.focusMode = .continuousAutoFocus
            }
            
            if captureDevice.isExposureModeSupported(.continuousAutoExposure) {
                captureDevice.exposureMode = .continuousAutoExposure
            }
            
            captureDevice.unlockForConfiguration()
        } catch {
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                throw ScannerError.scanningFailed("Failed to add camera input")
            }
        } catch {
            throw ScannerError.scanningFailed("Failed to create camera input: \(error.localizedDescription)")
        }
        
        let captureMetadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(captureMetadataOutput) {
            captureSession.addOutput(captureMetadataOutput)
        } else {
            throw ScannerError.scanningFailed("Failed to add metadata output")
        }
        
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        captureMetadataOutput.metadataObjectTypes = [
            .ean13, .ean8, .upce, .code128, .code39, .qr, .pdf417, .itf14
        ]
        
        let centerRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
        captureMetadataOutput.rectOfInterest = centerRect
        
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
        
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self, weak captureSession] in
            captureSession?.startRunning()
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .scannerPreviewLayerReady,
                    object: previewLayer
                )
            }
        }
    }
    
    func stopScanning() {
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
    }
    
    func resumeDetection() {
        isDetectionActive = true
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
        guard isDetectionActive else { return }
        
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue,
              !stringValue.isEmpty else {
            return
        }
        
        
        if isValidBarcodeChecksum(stringValue) {
            
            var processedValue = stringValue
            
            if readableObject.type == .ean13 && stringValue.hasPrefix("0") && stringValue.count == 13 {
                processedValue = String(stringValue.dropFirst())
            } else {
            }
            
            let now = Date()
            if let lastBarcode = lastDetectedBarcode,
               let lastTime = lastDetectionTime,
               lastBarcode == processedValue,
               now.timeIntervalSince(lastTime) < 1.0 {
                return
            }
            
            lastDetectedBarcode = processedValue
            lastDetectionTime = now
            
            pauseDetection()
            
            
            onBarcodeDetected?(processedValue)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.resumeDetection()
            }
        } else {
        }
    }
    
    private func isValidBarcodeChecksum(_ barcode: String) -> Bool {
        guard barcode.allSatisfy({ $0.isNumber }) else { return false }
        
        let digits = barcode.compactMap { Int(String($0)) }
        guard digits.count >= 8 else { return false }
        
        if digits.count == 12 || digits.count == 13 {
            var sum = 0
            let dataDigits = digits.dropLast()
            
            for (index, digit) in dataDigits.enumerated() {
                if digits.count == 12 {
                    sum += digit * (index % 2 == 0 ? 1 : 3)
                } else {
                    sum += digit * (index % 2 == 0 ? 1 : 3)
                }
            }
            let checksum = (10 - (sum % 10)) % 10
            let isValid = checksum == digits.last
            
            if !isValid {
            }
            
            return isValid
        }
        
        return digits.count >= 8 && digits.count <= 20
    }
    
    private func isValidFoodBarcode(_ barcode: String) -> Bool {
        return isValidBarcodeChecksum(barcode)
    }
}
