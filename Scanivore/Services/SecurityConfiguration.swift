//
//  SecurityConfiguration.swift
//  Scanivore
//
//  Security configuration and compile-time flags for production builds
//

import Foundation

// MARK: - Security Configuration

/// Security configuration for controlling debug logging and sensitive data exposure
public struct SecurityConfiguration {
    
    // MARK: - Logging Controls
    
    /// Controls whether verbose barcode logging is enabled
    /// SECURITY: This should only be enabled for specific debugging sessions
    /// Set via build configuration: -DENABLE_VERBOSE_BARCODE_LOGGING
    public static let verboseBarcodeLoggingEnabled: Bool = {
        #if DEBUG && ENABLE_VERBOSE_BARCODE_LOGGING
        return true
        #else
        return false
        #endif
    }()
    
    /// Controls whether API request/response logging is enabled
    /// SECURITY: Controlled by APIConfiguration.shouldLogAPIResponses
    public static let apiLoggingEnabled: Bool = {
        #if DEBUG
        return APIConfiguration.shouldLogAPIResponses
        #else
        return false
        #endif
    }()
    
    /// Controls whether authentication flow logging is enabled
    /// SECURITY: Should be disabled in production to prevent credential leakage
    public static let authLoggingEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Security Validators
    
    /// Validates that sensitive logging is disabled in release builds
    /// Call this during app initialization to verify security configuration
    public static func validateSecurityConfiguration() -> SecurityValidationResult {
        var issues: [SecurityIssue] = []
        
        #if !DEBUG
        // In release builds, ensure no verbose logging is enabled
        if verboseBarcodeLoggingEnabled {
            issues.append(.verboseLoggingInProduction)
        }
        
        if apiLoggingEnabled {
            issues.append(.apiLoggingInProduction)
        }
        
        if authLoggingEnabled {
            issues.append(.authLoggingInProduction)
        }
        #endif
        
        // Check for hardcoded secrets
        if APIConfiguration.jwtSecret == "REPLACE_WITH_ACTUAL_SERVER_SECRET_IN_PRODUCTION" {
            issues.append(.defaultSecretInProduction)
        }
        
        return SecurityValidationResult(issues: issues)
    }
}

// MARK: - Security Validation Models

public struct SecurityValidationResult {
    public let issues: [SecurityIssue]
    
    public var isSecure: Bool {
        return issues.isEmpty
    }
    
    public var description: String {
        if isSecure {
            return "✅ Security configuration validated - no issues found"
        } else {
            return "⚠️ Security issues found: \(issues.map(\.description).joined(separator: ", "))"
        }
    }
}

public enum SecurityIssue: CaseIterable {
    case verboseLoggingInProduction
    case apiLoggingInProduction  
    case authLoggingInProduction
    case defaultSecretInProduction
    
    public var description: String {
        switch self {
        case .verboseLoggingInProduction:
            return "Verbose barcode logging enabled in production"
        case .apiLoggingInProduction:
            return "API logging enabled in production"
        case .authLoggingInProduction:
            return "Authentication logging enabled in production"
        case .defaultSecretInProduction:
            return "Default JWT secret found in production"
        }
    }
    
    public var severity: SecuritySeverity {
        switch self {
        case .verboseLoggingInProduction:
            return .high
        case .apiLoggingInProduction:
            return .medium
        case .authLoggingInProduction:
            return .high
        case .defaultSecretInProduction:
            return .critical
        }
    }
}

public enum SecuritySeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium" 
    case high = "High"
    case critical = "Critical"
}

// MARK: - Secure Logging Helpers

/// Secure logging utility that respects security configuration
public struct SecureLogger {
    
    /// Log barcode-related information with automatic redaction
    public static func logBarcode(_ message: String, barcode: String? = nil) {
        #if DEBUG
        if SecurityConfiguration.verboseBarcodeLoggingEnabled, let barcode = barcode {
            // Barcode logging removed for production
        } else {
            // Barcode logging removed for production
        }
        #endif
    }
    
    /// Log authentication events with automatic sanitization
    public static func logAuth(_ message: String) {
        #if DEBUG
        if SecurityConfiguration.authLoggingEnabled {
            // Auth logging removed for production
        }
        #endif
    }
    
    /// Log API events with automatic sanitization
    public static func logAPI(_ message: String) {
        #if DEBUG
        if SecurityConfiguration.apiLoggingEnabled {
            // API logging removed for production
        }
        #endif
    }
}