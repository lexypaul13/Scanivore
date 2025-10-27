
import SwiftUI
import AVFoundation

struct CameraPreviewView: View {
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreviewLayer(previewLayer: previewLayer)
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name.scannerPreviewLayerReady)) { notification in
                        if let layer = notification.object as? AVCaptureVideoPreviewLayer {
                            self.previewLayer = layer
                        }
                    }
                
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .stroke(DesignSystem.Colors.primaryRed.opacity(0.8), lineWidth: 3)
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                
            }
        }
    }
}

struct CameraPreviewLayer: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        #if targetEnvironment(simulator)
        if uiView.layer.sublayers?.isEmpty ?? true {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor(DesignSystem.Colors.textSecondary).cgColor,
                UIColor(DesignSystem.Colors.textPrimary).cgColor
            ]
            gradientLayer.frame = uiView.bounds
            uiView.layer.addSublayer(gradientLayer)
            
            let label = UILabel()
            label.text = "📱 Simulator Camera Preview"
            label.textColor = .white
            label.textAlignment = .center
            label.frame = uiView.bounds
            uiView.addSubview(label)
        }
        #else
        if let previewLayer = previewLayer {
            uiView.layer.sublayers?.forEach { sublayer in
                if sublayer is AVCaptureVideoPreviewLayer {
                    sublayer.removeFromSuperlayer()
                }
            }
            
            previewLayer.frame = uiView.bounds
            previewLayer.videoGravity = .resizeAspectFill
            uiView.layer.addSublayer(previewLayer)
        }
        #endif
    }
}
