//
//  AuthGateway.swift
//  Scanivore
//
//  TCA-compliant authentication gateway using Alamofire
//

import Foundation
import Alamofire
import Dependencies
import ComposableArchitecture
// MARK: - Auth Gateway
@DependencyClient
public struct AuthGateway: Sendable {
    public var register: @Sendable (String, String, String?) async throws -> AuthResponse
    public var login: @Sendable (String, String) async throws -> AuthResponse
    public var logout: @Sendable () async throws -> Void = { }
    public var getCurrentUser: @Sendable () async throws -> User?
    public var isLoggedIn: @Sendable () async -> Bool = { false }
}

// MARK: - Dependency Key Conformance
extension AuthGateway: DependencyKey {
    public static let liveValue: Self = .init(
        register: { email, password, fullName in
            let request = AuthRequest(email: email, password: password, fullName: fullName)
            
            let response = try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/auth/register",
                method: .post,
                parameters: request,
                encoder: JSONParameterEncoder.default,
                headers: ["Content-Type": "application/json"]
            )
            .validate()
            .serializingDecodable(AuthResponse.self)
            .value
            
            // Store token securely
            try await TokenManager.shared.storeToken(response.accessToken)
            
            return response
        },
        
        login: { email, password in
            // OAuth2 form data format as required by the API
            let parameters = [
                "username": email,  // API expects "username" field for email
                "password": password
            ]
            
            let response = try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/auth/login",
                method: .post,
                parameters: parameters,
                encoder: URLEncodedFormParameterEncoder.default,
                headers: ["Content-Type": "application/x-www-form-urlencoded"]
            )
            .validate()
            .serializingDecodable(AuthResponse.self)
            .value
            
            // Store token securely
            try await TokenManager.shared.storeToken(response.accessToken)
            
            
            return response
        },
        
        logout: {
            try await TokenManager.shared.clearToken()
        },
        
        getCurrentUser: {
            // Check if we have a valid token
            guard let token = try await TokenManager.shared.getToken() else {
                return nil
            }
            
            return try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/users/me",
                method: .get,
                headers: [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer \(token)"
                ]
            )
            .validate()
            .serializingDecodable(User.self)
            .value
        },
        
        isLoggedIn: {
            // Synchronous check - just verify if we have a stored token
            // For actual validation, use getCurrentUser instead
            do {
                let token = try await TokenManager.shared.getToken()
                return token != nil
            } catch {
                return false
            }
        }
    )
    
    public static let testValue = Self()
    
    public static let previewValue: Self = .init(
        register: { _, _, _ in .mockSuccess },
        login: { _, _ in .mockSuccess },
        logout: { },
        getCurrentUser: { .mock },
        isLoggedIn: { true }
    )
}



// MARK: - Dependency Extension
extension DependencyValues {
    public var authGateway: AuthGateway {
        get { self[AuthGateway.self] }
        set { self[AuthGateway.self] = newValue }
    }
}

// MARK: - Mock Data
extension AuthResponse {
    static let mockSuccess = AuthResponse(
        accessToken: "mock_token_123456",
        tokenType: "bearer",
        message: "Mock authentication successful"
    )
}

extension User {
    static let mock = User(
        id: "mock_user_123",
        email: "test@example.com",
        fullName: "Test User",
        isActive: true,
        preferences: UserPreferences(
            nutritionFocus: "protein",
            avoidPreservatives: true,
            meatPreferences: ["beef", "chicken"],
            prefer_no_preservatives: true,
            prefer_antibiotic_free: true,
            prefer_organic_or_grass_fed: true,
            prefer_no_added_sugars: true,
            prefer_no_flavor_enhancers: true,
            prefer_reduced_sodium: false,
            preferred_meat_types: ["beef", "chicken"]
        )
    )
}
