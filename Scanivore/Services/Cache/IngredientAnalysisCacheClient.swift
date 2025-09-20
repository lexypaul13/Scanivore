//
//  IngredientAnalysisCacheClient.swift
//  Scanivore
//
//  In-memory per-session cache for individual ingredient analysis
//

import Foundation
import Dependencies

// Internal actor-backed store for thread-safe access
actor IngredientAnalysisMemoryStore {
    private var store: [String: (value: IndividualIngredientAnalysisResponseWithName, timestamp: Date)] = [:]
    private let ttl: TimeInterval
    
    init(ttl: TimeInterval = 24 * 60 * 60) { // 24h default
        self.ttl = ttl
    }
    
    func get(_ key: String) -> IndividualIngredientAnalysisResponseWithName? {
        if let entry = store[key] {
            if Date().timeIntervalSince(entry.timestamp) < ttl {
                return entry.value
            } else {
                store.removeValue(forKey: key)
            }
        }
        return nil
    }
    
    func set(_ key: String, _ value: IndividualIngredientAnalysisResponseWithName) {
        store[key] = (value, Date())
    }
    
    func clear() {
        store.removeAll()
    }
}

public struct IngredientAnalysisCacheClient: Sendable {
    public var get: @Sendable (_ key: String) async -> IndividualIngredientAnalysisResponseWithName?
    public var set: @Sendable (_ key: String, _ value: IndividualIngredientAnalysisResponseWithName) async -> Void
    public var clear: @Sendable () async -> Void
}

extension IngredientAnalysisCacheClient: DependencyKey {
    public static let liveValue: Self = {
        let store = IngredientAnalysisMemoryStore()
        return .init(
            get: { key in await store.get(key) },
            set: { key, value in await store.set(key, value) },
            clear: { await store.clear() }
        )
    }()
    
    public static let testValue: Self = .init(
        get: { _ in nil },
        set: { _, _ in },
        clear: { }
    )

    public static let previewValue: Self = .init(
        get: { _ in nil },
        set: { _, _ in },
        clear: { }
    )
}

public extension DependencyValues {
    var ingredientAnalysisCache: IngredientAnalysisCacheClient {
        get { self[IngredientAnalysisCacheClient.self] }
        set { self[IngredientAnalysisCacheClient.self] = newValue }
    }
}

