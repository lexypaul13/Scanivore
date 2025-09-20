//
//  HealthCacheClient.swift
//  Scanivore
//
//  TCA dependency wrapper around HealthAssessmentCache
//

import Foundation
import Dependencies

public struct HealthCacheClient: Sendable {
    public var get: @Sendable (_ barcode: String) async -> HealthAssessmentResponse?
    public var set: @Sendable (_ assessment: HealthAssessmentResponse, _ barcode: String) async -> Void
    public var clearAll: @Sendable () async -> Void
    public var clearExpired: @Sendable () -> Void
}

extension HealthCacheClient: DependencyKey {
    public static let liveValue: Self = .init(
        get: { barcode in
            await HealthAssessmentCache.shared.getCachedAssessment(for: barcode)?.assessment
        },
        set: { assessment, barcode in
            await HealthAssessmentCache.shared.cacheAssessment(assessment, for: barcode)
        },
        clearAll: {
            HealthAssessmentCache.shared.clearAllCache()
        },
        clearExpired: {
            HealthAssessmentCache.shared.clearExpiredCache()
        }
    )
    
    public static let testValue: Self = .init(
        get: { _ in nil },
        set: { _, _ in },
        clearAll: { },
        clearExpired: { }
    )

    public static let previewValue: Self = .init(
        get: { _ in nil },
        set: { _, _ in },
        clearAll: { },
        clearExpired: { }
    )
}

public extension DependencyValues {
    var healthCache: HealthCacheClient {
        get { self[HealthCacheClient.self] }
        set { self[HealthCacheClient.self] = newValue }
    }
}

