//
//  HealthAssessmentCache.swift
//  Scanivore
//
//  Client-side caching for health assessment data
//

import Foundation

/// Cache manager for health assessment responses
public class HealthAssessmentCache {
    public static let shared = HealthAssessmentCache()
    
    private let cacheDirectory: URL
    private let cacheTTL: TimeInterval = 24 * 60 * 60 // 24 hours
    private let cacheQueue = DispatchQueue(label: "health-assessment-cache", qos: .userInitiated)
    
    private init() {
        // Create cache directory in Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("HealthAssessmentCache")
        
        // Ensure cache directory exists
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    /// Get cached health assessment for a product (async to avoid main thread blocking)
    /// Returns: (assessment, wasFromCache) tuple for UX optimization
    public func getCachedAssessment(for barcode: String) async -> (assessment: HealthAssessmentResponse, fromCache: Bool)? {
        return await withCheckedContinuation { continuation in
            cacheQueue.async {
                let cacheFile = self.cacheDirectory.appendingPathComponent("\(barcode).json")
                
                guard FileManager.default.fileExists(atPath: cacheFile.path) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let data = try Data(contentsOf: cacheFile)
                    let cacheEntry = try JSONDecoder().decode(CacheEntry.self, from: data)
                    
                    // Check if cache is still valid
                    if Date().timeIntervalSince(cacheEntry.timestamp) < self.cacheTTL {
                        let ageInHours = Date().timeIntervalSince(cacheEntry.timestamp) / 3600
                        print("📱 Cache HIT for product \(barcode) (cached \(String(format: "%.1f", ageInHours))h ago)")
                        continuation.resume(returning: (assessment: cacheEntry.assessment, fromCache: true))
                    } else {
                        // Cache expired, remove file
                        print("📱 Cache EXPIRED for product \(barcode)")
                        try? FileManager.default.removeItem(at: cacheFile)
                        continuation.resume(returning: nil)
                    }
                } catch {
                    print("📱 Cache READ error for \(barcode): \(error)")
                    // Remove corrupted cache file
                    try? FileManager.default.removeItem(at: cacheFile)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// Legacy method for backward compatibility
    @available(*, deprecated, message: "Use getCachedAssessment(for:) -> (assessment, fromCache) instead")
    public func getCachedAssessmentLegacy(for barcode: String) async -> HealthAssessmentResponse? {
        return await getCachedAssessment(for: barcode)?.assessment
    }
    
    /// Cache health assessment for a product (async to avoid main thread blocking)
    public func cacheAssessment(_ assessment: HealthAssessmentResponse, for barcode: String) async {
        await withCheckedContinuation { continuation in
            cacheQueue.async {
                let cacheFile = self.cacheDirectory.appendingPathComponent("\(barcode).json")
                
                let cacheEntry = CacheEntry(
                    assessment: assessment,
                    timestamp: Date()
                )
                
                do {
                    let data = try JSONEncoder().encode(cacheEntry)
                    try data.write(to: cacheFile)
                    print("📱 Cache STORED for product \(barcode)")
                } catch {
                    print("📱 Cache WRITE error for \(barcode): \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    /// Clear expired cache entries
    public func clearExpiredCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            for file in files {
                if let creationDate = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate {
                    if Date().timeIntervalSince(creationDate) > cacheTTL {
                        try? FileManager.default.removeItem(at: file)
                        print("📱 Removed expired cache file: \(file.lastPathComponent)")
                    }
                }
            }
        } catch {
            print("📱 Cache cleanup error: \(error)")
        }
    }
    
    /// Clear all cached assessments
    public func clearAllCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            print("📱 Cleared all cached assessments")
        } catch {
            print("📱 Error clearing cache: \(error)")
        }
    }
    
    /// Get cache statistics
    public func getCacheStats() -> (count: Int, totalSize: Int64) {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            
            var totalSize: Int64 = 0
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
            
            return (count: files.count, totalSize: totalSize)
        } catch {
            return (count: 0, totalSize: 0)
        }
    }
}

// MARK: - Cache Entry Model

private struct CacheEntry: Codable {
    let assessment: HealthAssessmentResponse
    let timestamp: Date
}
