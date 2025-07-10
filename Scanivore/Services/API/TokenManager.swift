//
//  TokenManager.swift
//  Scanivore
//
//  Secure token storage using iOS Keychain
//

import Foundation
import Security

// MARK: - Token Manager
public final class TokenManager {
    public static let shared = TokenManager()
    
    private let service = "com.scanivore.api"
    private let account = "clear_meat_token"
    
    private init() {}
    
    // MARK: - Token Storage
    public func storeToken(_ token: String) async throws {
        let tokenData = token.data(using: .utf8)!
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: tokenData
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw TokenManagerError.storageError("Failed to store token: \(status)")
        }
    }
    
    public func getToken() async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
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
        
        return String(data: tokenData, encoding: .utf8)
    }
    
    public func clearToken() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
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
        
        // Basic JWT validation - check if token is not expired
        return validateJWTToken(token)
    }
    
    // MARK: - JWT Validation
    private func validateJWTToken(_ token: String) -> Bool {
        let components = token.components(separatedBy: ".")
        
        guard components.count == 3 else {
            return false
        }
        
        // Decode the payload (second component)
        let payload = components[1]
        
        // Add padding if needed
        let paddedPayload = payload.padding(toLength: ((payload.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        
        guard let data = Data(base64Encoded: paddedPayload) else {
            return false
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let dict = json as? [String: Any],
                  let exp = dict["exp"] as? TimeInterval else {
                return false
            }
            
            // Check if token is expired
            let expirationDate = Date(timeIntervalSince1970: exp)
            return expirationDate > Date()
        } catch {
            return false
        }
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