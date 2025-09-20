//
//  SecureLogger.swift
//  Scanivore
//
//  Secure logging framework that prevents sensitive data exposure
//

import Foundation

public struct SecureLogger {

    // MARK: - Authentication Logging
    public static func logAuth(_ message: String) {
        #if DEBUG
        print("🔐 [AUTH] \(message)")
        #endif
    }

    // MARK: - API Logging
    public static func logAPI(_ message: String, sanitized: Bool = true) {
        #if DEBUG
        if APIConfiguration.shouldLogAPIResponses {
            let finalMessage = sanitized ? sanitizeMessage(message) : message
            print("🌐 [API] \(finalMessage)")
        }
        #endif
    }

    // MARK: - Barcode Logging
    public static func logBarcode(_ message: String, barcode: String? = nil) {
        #if DEBUG
        if SecurityConfiguration.verboseBarcodeLoggingEnabled {
            if let barcode = barcode {
                print("📱 [BARCODE] \(message) - Code: \(barcode)")
            } else {
                print("📱 [BARCODE] \(message)")
            }
        }
        #endif
    }

    // MARK: - General Debug Logging
    public static func logDebug(_ message: String, category: String = "DEBUG") {
        #if DEBUG
        print("🔍 [\(category)] \(message)")
        #endif
    }

    // MARK: - Error Logging (Always enabled)
    public static func logError(_ message: String, error: Error? = nil) {
        print("❌ [ERROR] \(message)")
        if let error = error {
            print("❌ [ERROR] Details: \(error)")
        }
    }

    // MARK: - Warning Logging (Always enabled)
    public static func logWarning(_ message: String) {
        print("⚠️ [WARNING] \(message)")
    }

    // MARK: - Security Event Logging (Always enabled)
    public static func logSecurity(_ message: String) {
        print("🛡️ [SECURITY] \(message)")
    }

    // MARK: - Private Helper Methods
    private static func sanitizeMessage(_ message: String) -> String {
        var sanitized = message

        // Remove Bearer tokens
        sanitized = sanitized.replacingOccurrences(
            of: "Bearer [A-Za-z0-9._-]+",
            with: "Bearer [REDACTED]",
            options: .regularExpression
        )

        // Remove JSON token fields
        sanitized = sanitized.replacingOccurrences(
            of: "\"token\"\\s*:\\s*\"[^\"]+\"",
            with: "\"token\": \"[REDACTED]\"",
            options: .regularExpression
        )

        // Remove access_token fields
        sanitized = sanitized.replacingOccurrences(
            of: "\"access_token\"\\s*:\\s*\"[^\"]+\"",
            with: "\"access_token\": \"[REDACTED]\"",
            options: .regularExpression
        )

        // Remove Authorization headers
        sanitized = sanitized.replacingOccurrences(
            of: "Authorization[^\\n]*",
            with: "Authorization: [REDACTED]",
            options: .regularExpression
        )

        // Remove potential passwords
        sanitized = sanitized.replacingOccurrences(
            of: "\"password\"\\s*:\\s*\"[^\"]+\"",
            with: "\"password\": \"[REDACTED]\"",
            options: .regularExpression
        )

        return sanitized
    }
}