
import Foundation

// MARK: - Security Configuration

public struct SecurityConfiguration {
    
    // MARK: - Logging Controls
    
    public static let verboseBarcodeLoggingEnabled: Bool = {
        #if DEBUG && ENABLE_VERBOSE_BARCODE_LOGGING
        return true
        #else
        return false
        #endif
    }()
    
    public static let apiLoggingEnabled: Bool = {
        #if DEBUG
        return APIConfiguration.shouldLogAPIResponses
        #else
        return false
        #endif
    }()
    
    public static let authLoggingEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Security Validators
    
    public static func validateSecurityConfiguration() -> SecurityValidationResult {
        var issues: [SecurityIssue] = []
        
        #if !DEBUG
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
    
    public var description: String {
        switch self {
        case .verboseLoggingInProduction:
            return "Verbose barcode logging enabled in production"
        case .apiLoggingInProduction:
            return "API logging enabled in production"
        case .authLoggingInProduction:
            return "Authentication logging enabled in production"
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

