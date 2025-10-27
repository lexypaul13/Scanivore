
import Foundation
import Security
// MARK: - Token Manager
public final class TokenManager {
    public static let shared = TokenManager()
    
    private let service = "com.scanivore.api"
    private let account = "clear_meat_token"
    private var inMemoryToken: String?
    
    private init() {}
    
    // MARK: - Token Storage
    public func storeToken(_ token: String) async throws {
        guard let tokenData = token.data(using: .utf8) else {
            throw TokenManagerError.storageError("Failed to encode token as UTF-8")
        }

        inMemoryToken = token
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false  // Prevent syncing across devices
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw TokenManagerError.storageError("Failed to store token: \(status)")
        }
    }
    
    public func getToken() async throws -> String? {
        if let cached = inMemoryToken {
            return cached
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: false  // Match storage settings
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw TokenManagerError.retrievalError("Failed to retrieve token: \(status)")
        }
        
        guard let tokenData = item as? Data else {
            throw TokenManagerError.retrievalError("Token data is invalid")
        }
        
        let token = String(data: tokenData, encoding: .utf8)
        inMemoryToken = token
        return token
    }

    public func clearToken() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false  // Match storage settings
        ]
        
        inMemoryToken = nil
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenManagerError.deletionError("Failed to delete token: \(status)")
        }
    }
    
    public func hasToken() async -> Bool {
        do {
            let token = try await getToken()
            return token != nil
        } catch {
            return false
        }
    }
    
    public func isTokenValid() async -> Bool {
        guard let token = try? await getToken() else {
            return false
        }
        
        return validateJWTToken(token)
    }
    
    // MARK: - JWT Validation
    private func validateJWTToken(_ token: String) -> Bool {
        let components = token.components(separatedBy: ".")
        
        guard components.count == 3 else {
            return false
        }
        
        guard validateJWTHeader(components[0]) else {
            return false
        }
        
        guard validateJWTPayload(components[1]) else {
            return false
        }
        
        return true
    }
    
    private func validateJWTHeader(_ headerComponent: String) -> Bool {
        guard let headerData = decodeBase64URLComponent(headerComponent),
              let headerDict = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              let alg = headerDict["alg"] as? String,
              let typ = headerDict["typ"] as? String else {
            return false
        }
        
        guard alg == "HS256" && typ == "JWT" else {
            return false
        }
        
        return true
    }
    
    private func validateJWTPayload(_ payloadComponent: String) -> Bool {
        guard let payloadData = decodeBase64URLComponent(payloadComponent),
              let payloadDict = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return false
        }
        
        let currentTime = Date().timeIntervalSince1970
        
        if let exp = payloadDict["exp"] as? TimeInterval {
            guard exp > currentTime else {
                return false // Token expired
            }
        }
        
        if let nbf = payloadDict["nbf"] as? TimeInterval {
            guard nbf <= currentTime else {
                return false // Token not yet valid
            }
        }
        
        if let iat = payloadDict["iat"] as? TimeInterval {
            guard iat <= currentTime + 300 else { // Allow 5 minute clock skew
                return false // Token issued in future
            }
        }
        
        if let iss = payloadDict["iss"] as? String {
            guard iss == "clear-meat-api" else {
                return false // Invalid issuer
            }
        }
        
        return true
    }
    
    private func decodeBase64URLComponent(_ component: String) -> Data? {
        var base64 = component
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padding = 4 - (base64.count % 4)
        if padding != 4 {
            base64 += String(repeating: "=", count: padding)
        }
        
        return Data(base64Encoded: base64)
    }
}

// MARK: - Token Manager Errors
public enum TokenManagerError: Error, LocalizedError {
    case storageError(String)
    case retrievalError(String)
    case deletionError(String)
    
    public var errorDescription: String? {
        switch self {
        case .storageError(let message):
            return "Token storage error: \(message)"
        case .retrievalError(let message):
            return "Token retrieval error: \(message)"
        case .deletionError(let message):
            return "Token deletion error: \(message)"
        }
    }
}

// MARK: - Mock Token Manager for Testing
public final class MockTokenManager {
    public static let shared = MockTokenManager()
    
    private var mockToken: String?
    
    private init() {}
    
    public func storeToken(_ token: String) async throws {
        mockToken = token
    }
    
    public func getToken() async throws -> String? {
        return mockToken
    }
    
    public func clearToken() async throws {
        mockToken = nil
    }
    
    public func hasToken() async -> Bool {
        return mockToken != nil
    }
    
    public func isTokenValid() async -> Bool {
        return mockToken != nil
    }
}
