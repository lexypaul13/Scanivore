//
//  SafariService.swift
//  Scanivore
//
//  TCA-compliant Safari navigation service
//

import Foundation
import SafariServices
import UIKit
import Dependencies
import ComposableArchitecture

// MARK: - Safari Service
@DependencyClient
public struct SafariService: Sendable {
    public var openURL: @Sendable (URL) async -> Bool = { _ in false }
    public var canOpenURL: @Sendable (URL) -> Bool = { _ in false }
}

// MARK: - Dependency Key Conformance
extension SafariService: DependencyKey {
    public static let liveValue: Self = .init(
        openURL: { url in
            await MainActor.run {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootViewController = windowScene.windows.first?.rootViewController else {
                    return false
                }
                
                let safariViewController = SFSafariViewController(url: url)
                safariViewController.preferredBarTintColor = UIColor.systemBackground
                safariViewController.preferredControlTintColor = UIColor.systemRed
                
                // Find the topmost view controller
                func findTopViewController(_ controller: UIViewController) -> UIViewController {
                    if let presented = controller.presentedViewController {
                        return findTopViewController(presented)
                    } else if let navigationController = controller as? UINavigationController,
                              let visible = navigationController.visibleViewController {
                        return findTopViewController(visible)
                    } else if let tabBarController = controller as? UITabBarController,
                              let selected = tabBarController.selectedViewController {
                        return findTopViewController(selected)
                    }
                    return controller
                }
                
                let topViewController = findTopViewController(rootViewController)
                topViewController.present(safariViewController, animated: true)
                
                return true
            }
        },
        canOpenURL: { url in
            UIApplication.shared.canOpenURL(url)
        }
    )
    
    public static let testValue: Self = .init(
        openURL: { _ in true },
        canOpenURL: { _ in true }
    )
    
    public static let previewValue: Self = .init(
        openURL: { _ in true },
        canOpenURL: { _ in true }
    )
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var safariService: SafariService {
        get { self[SafariService.self] }
        set { self[SafariService.self] = newValue }
    }
}