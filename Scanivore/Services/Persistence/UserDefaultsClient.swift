
import Foundation
import Dependencies
import ComposableArchitecture

// MARK: - UserDefaults Client
@DependencyClient
public struct UserDefaultsClient: Sendable {
    public var getBool: @Sendable (String) async -> Bool = { _ in false }
    public var setBool: @Sendable (String, Bool) async -> Void
    public var getString: @Sendable (String) async -> String? = { _ in nil }
    public var setString: @Sendable (String, String?) async -> Void
    public var getData: @Sendable (String) async -> Data? = { _ in nil }
    public var setData: @Sendable (String, Data?) async -> Void
    public var remove: @Sendable (String) async -> Void
    
    public var getObject: @Sendable (String, any Codable.Type) async -> (any Codable)? = { _, _ in nil }
    public var setObject: @Sendable (String, any Codable) async -> Void
}

// MARK: - Dependency Key Conformance
extension UserDefaultsClient: DependencyKey {
    public static let liveValue: Self = .init(
        getBool: { key in
            UserDefaults.standard.bool(forKey: key)
        },
        setBool: { key, value in
            UserDefaults.standard.set(value, forKey: key)
        },
        getString: { key in
            UserDefaults.standard.string(forKey: key)
        },
        setString: { key, value in
            UserDefaults.standard.set(value, forKey: key)
        },
        getData: { key in
            UserDefaults.standard.data(forKey: key)
        },
        setData: { key, value in
            UserDefaults.standard.set(value, forKey: key)
        },
        remove: { key in
            UserDefaults.standard.removeObject(forKey: key)
        },
        getObject: { key, type in
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(type, from: data)
        },
        setObject: { key, object in
            let data = try? JSONEncoder().encode(object)
            UserDefaults.standard.set(data, forKey: key)
        }
    )
    
    public static let testValue = Self()
    
    public static let previewValue = Self()
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var userDefaults: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}

// MARK: - Keys Reference
