//
//  SFSafariViewWrapper.swift
//  Scanivore
//
//  SwiftUI wrapper for SFSafariViewController to provide in-app web browsing
//

import SwiftUI
import SafariServices

struct SFSafariViewWrapper: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true // Better for academic papers
        
        // Enhanced configuration for Google grounding redirect URLs
        config.barCollapsingEnabled = true
        
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredBarTintColor = UIColor(DesignSystem.Colors.background)
        safariVC.preferredControlTintColor = UIColor(DesignSystem.Colors.primaryRed)
        
        // Set delegate for better error handling of redirect URLs
        safariVC.delegate = context.coordinator
        
        return safariVC
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            // Handle cases where Google grounding redirect URLs fail to load
            if !didLoadSuccessfully {
                // Could add analytics or error reporting here if needed
                print("Citation URL failed to load - this may be a Google grounding redirect timeout")
            }
        }
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Safari View Presentation Modifier
struct SafariView: ViewModifier {
    @Binding var isPresented: Bool
    let url: URL?
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                if let url = url {
                    SFSafariViewWrapper(url: url)
                        .ignoresSafeArea()
                }
            }
    }
}

extension View {
    func safariView(isPresented: Binding<Bool>, url: URL?) -> some View {
        modifier(SafariView(isPresented: isPresented, url: url))
    }
}