
import Foundation
import UIKit
import Dependencies
import ComposableArchitecture

// MARK: - Haptic Feedback Service
@DependencyClient
public struct HapticFeedbackService: Sendable {
    public var impact: @Sendable (UIImpactFeedbackGenerator.FeedbackStyle) async -> Void = { _ in }
    public var notification: @Sendable (UINotificationFeedbackGenerator.FeedbackType) async -> Void = { _ in }
    public var selection: @Sendable () async -> Void = {}
}

// MARK: - Dependency Key Conformance
extension HapticFeedbackService: DependencyKey {
    public static let liveValue: Self = .init(
        impact: { style in
            await MainActor.run {
                let impactFeedback = UIImpactFeedbackGenerator(style: style)
                impactFeedback.impactOccurred()
            }
        },
        notification: { type in
            await MainActor.run {
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(type)
            }
        },
        selection: {
            await MainActor.run {
                let selectionFeedback = UISelectionFeedbackGenerator()
                selectionFeedback.selectionChanged()
            }
        }
    )
    
    public static let testValue: Self = .init()
    
    public static let previewValue: Self = .init()
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var hapticFeedback: HapticFeedbackService {
        get { self[HapticFeedbackService.self] }
        set { self[HapticFeedbackService.self] = newValue }
    }
}
