//
//  APIConfiguration.swift
//  Scanivore
//
//  Configuration for Clear-Meat API integration
//

import Foundation

// MARK: - API Configuration
public struct APIConfiguration {
    public static let baseURL = "https://clear-meat-api-production.up.railway.app"
    public static let apiVersion = "v1"
    
    // ⚡ PERFORMANCE OPTIMIZATIONS (2025-08-07)
    // Backend optimized: 94% faster health assessments (5s vs 83s baseline)
    // Mobile format: 49.9% JSON payload reduction (2.3KB → 1.2KB) + citation webview support
    // Client-side caching: 24h TTL provides instant responses for repeated scans
    public static let timeout: TimeInterval = 15.0  // Reduced from 30s for 94% faster backend
    public static let healthAssessmentTimeout: TimeInterval = 90.0  // Increased to 90s for mobile networks + AI generation with auto-retry
    
    public static let jwtSecret = "REPLACE_WITH_ACTUAL_SERVER_SECRET_IN_PRODUCTION"
    
    // API Endpoints
    public enum Endpoints {
        public static let register = "/api/v1/auth/register"
        public static let login = "/api/v1/auth/login"
        public static let userProfile = "/api/v1/users/me"
        public static let products = "/api/v1/products"
        public static let healthAssessment = "/api/v1/products/{barcode}/health-assessment-mcp"
        public static let ingredientAnalysis = "/api/v1/ingredients/{ingredient}/analysis"
        public static let alternatives = "/api/v1/products/{barcode}/alternatives"
        public static let recommendations = "/api/v1/products/recommendations"
        public static let search = "/api/v1/products/search"
        public static let favorites = "/api/v1/users/favorites"
        public static let history = "/api/v1/users/history"
        public static let explore = "/api/v1/users/explore"
    }
    
    // Response Format Options
    public enum ResponseFormat {
        public static let mobile = "mobile"
        public static let full = "full"
    }
    
    // Request Headers
    public enum Headers {
        public static let contentType = "Content-Type"
        public static let authorization = "Authorization"
        public static let userAgent = "User-Agent"
        
        public static let applicationJSON = "application/json"
        public static let formURLEncoded = "application/x-www-form-urlencoded"
    }
}

// MARK: - Environment Configuration
public enum APIEnvironment {
    case development
    case production
    
    public var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:8000"
        case .production:
            return "https://clear-meat-api-production.up.railway.app"
        }
    }
    
    public var isDebugMode: Bool {
        #if DEBUG
        switch self {
        case .development:
            return true
        case .production:
            return false
        }
        #else
        return false
        #endif
    }
}

// MARK: - Current Environment
public extension APIConfiguration {
    static var currentEnvironment: APIEnvironment {
        // Always use production for physical devices
        // localhost won't work on real devices
        return .production
    }
    
    static var currentBaseURL: String {
        return baseURL // Always use production URL
    }
    
    static var isDebugMode: Bool {
        #if DEBUG
        return currentEnvironment.isDebugMode
        #else
        return false
        #endif
    }
    
    // MARK: - Secure Configuration
    static var shouldLogAPIResponses: Bool {
        #if DEBUG
        return isDebugMode
        #else
        return false
        #endif
    }
    
    static var shouldLogNetworkRequests: Bool {
        #if DEBUG
        return isDebugMode
        #else
        return false
        #endif
    }
}