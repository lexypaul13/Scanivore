//
//  LottieAnimationView.swift
//  Scanivore
//
//  SwiftUI wrapper for Lottie animations
//

import SwiftUI
import Lottie

struct LottieAnimationView: View {
    let animationName: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    let contentMode: UIView.ContentMode
    
    @State private var isAnimating = false
    
    init(
        animationName: String,
        loopMode: LottieLoopMode = .playOnce,
        animationSpeed: CGFloat = 1.0,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
        self.contentMode = contentMode
    }
    
    var body: some View {
        LottieViewRepresentable(
            animationName: animationName,
            loopMode: loopMode,
            animationSpeed: animationSpeed,
            contentMode: contentMode,
            isAnimating: $isAnimating
        )
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

struct LottieViewRepresentable: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    let contentMode: UIView.ContentMode
    @Binding var isAnimating: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        // Create the Lottie animation view
        let animationView = Lottie.LottieAnimationView(name: animationName)
        
        // Check if animation loaded successfully
        guard animationView.animation != nil else {
            print("Warning: Lottie animation '\(animationName)' not found")
            return view
        }
        
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.contentMode = contentMode
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = uiView.subviews.first as? Lottie.LottieAnimationView else { return }
        
        // Safely handle animation playback
        DispatchQueue.main.async {
            if isAnimating && animationView.animation != nil {
                animationView.play()
            } else {
                animationView.stop()
            }
        }
    }
}

// Convenience view for common animation patterns
struct PulsingLottieView: View {
    let animationName: String
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        LottieAnimationView(
            animationName: animationName,
            loopMode: .loop,
            animationSpeed: 1.0
        )
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
        }
    }
}