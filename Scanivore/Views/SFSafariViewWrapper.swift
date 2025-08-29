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
            // Enhanced error handling for medical authority URLs
            if !didLoadSuccessfully {
                // Log for debugging while maintaining user privacy
                print("Medical citation URL failed to load - checking network connectivity and URL validity")
                
                // Add haptic feedback for failed loads
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.warning)
            } else {
                // Success feedback for medical citations
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        
        func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
            // Track successful redirects from Google grounding to actual medical sources
            print("Successfully redirected to medical authority: \(URL.host ?? "unknown")")
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
    @State private var showingErrorAlert = false
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                if let url = url {
                    // Validate URL before presenting Safari
                    if isValidMedicalURL(url) {
                        SFSafariViewWrapper(url: url)
                            .ignoresSafeArea()
                    } else {
                        // Show error state for invalid URLs
                        NavigationStack {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                
                                Text("Unable to Load Citation")
                                    .font(.headline)
                                
                                Text("This medical citation link appears to be invalid or temporarily unavailable. Please try again later.")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                
                                Button("Close") {
                                    isPresented = false
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .navigationTitle("Citation Error")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                }
            }
    }
    
    private func isValidMedicalURL(_ url: URL) -> Bool {
        // Enhanced validation for medical URLs
        guard let scheme = url.scheme, (scheme == "http" || scheme == "https") else {
            return false
        }
        
        guard let host = url.host, !host.isEmpty else {
            return false
        }
        
        // Additional check for obviously malformed URLs
        let urlString = url.absoluteString
        return !urlString.contains("javascript:") && !urlString.contains("data:")
    }
}

extension View {
    func safariView(isPresented: Binding<Bool>, url: URL?) -> some View {
        modifier(SafariView(isPresented: isPresented, url: url))
    }
    
    // Additional convenience method for medical citations with enhanced error handling
    func medicalCitationView(isPresented: Binding<Bool>, citation: String, url: URL?) -> some View {
        modifier(SafariView(isPresented: isPresented, url: url))
    }
}