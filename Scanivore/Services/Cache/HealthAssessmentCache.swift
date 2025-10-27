
import Foundation

public class HealthAssessmentCache {
    public static let shared = HealthAssessmentCache()
    
    private let cacheDirectory: URL
    private let cacheTTL: TimeInterval = 24 * 60 * 60 // 24 hours
    private let cacheQueue = DispatchQueue(label: "health-assessment-cache", qos: .userInitiated)
    private let memoryCache = NSCache<NSString, CacheEntryBox>()
    
    private init() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("HealthAssessmentCache")
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            return
        }
        
        cacheDirectory = documentsPath.appendingPathComponent("HealthAssessmentCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    public func getCachedAssessment(for barcode: String) async -> (assessment: HealthAssessmentResponse, fromCache: Bool)? {
        let cacheKey = barcode as NSString
        if let box = memoryCache.object(forKey: cacheKey) {
            if isEntryValid(box.entry) {
                return (box.entry.assessment, true)
            } else {
                memoryCache.removeObject(forKey: cacheKey)
            }
        }

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
                    
                    if self.isEntryValid(cacheEntry) {
                        let box = CacheEntryBox(entry: cacheEntry)
                        self.memoryCache.setObject(box, forKey: cacheKey)
                        continuation.resume(returning: (assessment: cacheEntry.assessment, fromCache: true))
                    } else {
                        try? FileManager.default.removeItem(at: cacheFile)
                        continuation.resume(returning: nil)
                    }
                } catch {
                    try? FileManager.default.removeItem(at: cacheFile)
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    @available(*, deprecated, message: "Use getCachedAssessment(for:) -> (assessment, fromCache) instead")
    public func getCachedAssessmentLegacy(for barcode: String) async -> HealthAssessmentResponse? {
        return await getCachedAssessment(for: barcode)?.assessment
    }
    
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
                    let box = CacheEntryBox(entry: cacheEntry)
                    self.memoryCache.setObject(box, forKey: barcode as NSString)
                } catch {
                }
                
                continuation.resume()
            }
        }
    }
    
    public func clearExpiredCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.creationDateKey])
            
            for file in files {
                if let creationDate = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate {
                    if Date().timeIntervalSince(creationDate) > cacheTTL {
                        try? FileManager.default.removeItem(at: file)
                        let key = file.deletingPathExtension().lastPathComponent as NSString
                        memoryCache.removeObject(forKey: key)
                    }
                }
            }
        } catch {
        }
    }
    
    public func clearAllCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
                let key = file.deletingPathExtension().lastPathComponent as NSString
                memoryCache.removeObject(forKey: key)
            }
            memoryCache.removeAllObjects()
        } catch {
        }
    }
    
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

private final class CacheEntryBox: NSObject {
    let entry: CacheEntry
    init(entry: CacheEntry) {
        self.entry = entry
    }
}

private extension HealthAssessmentCache {
    func isEntryValid(_ entry: CacheEntry) -> Bool {
        Date().timeIntervalSince(entry.timestamp) < cacheTTL
    }
}

// MARK: - Cache Entry Model

private struct CacheEntry: Codable {
    let assessment: HealthAssessmentResponse
    let timestamp: Date
}
