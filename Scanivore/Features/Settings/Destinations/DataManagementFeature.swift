//
//  DataManagementFeature.swift
//  Scanivore
//
//  Data management feature for scan history and storage
//

import Foundation
import ComposableArchitecture

@Reducer
public struct DataManagementFeature {
    @ObservableState
    public struct State: Equatable {
        public var totalScans: Int = 0
        public var storageUsed: String = "0 MB"
        public var recentScans: [ScanRecord] = []
        public var isLoading: Bool = false
        public var showingDeleteConfirmation: Bool = false
        public var errorMessage: String?
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case deleteAllDataTapped
        case confirmDeleteAllData
        case cancelDeleteAllData
        case dismissError
        case setDeleteConfirmation(Bool)
        case recentScansLoaded([ScanRecord])
        
        // Async responses
        case storageInfoLoaded(TaskResult<StorageInfo>)
        case deleteAllDataResponse(TaskResult<Bool>)
        
        // Internal actions
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case dataDeleted
        }
    }
    
    public struct StorageInfo: Equatable {
        public let totalScans: Int
        public let storageUsed: String
        
        public init(totalScans: Int, storageUsed: String) {
            self.totalScans = totalScans
            self.storageUsed = storageUsed
        }
    }
    
    @Dependency(\.scanHistoryClient) var scanHistoryClient
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    await send(.storageInfoLoaded(
                        TaskResult {
                            let scans = try await scanHistoryClient.getAllScans()
                            let totalScans = scans.count
                            let storageUsed = calculateStorageUsed(for: scans)
                            return StorageInfo(
                                totalScans: totalScans,
                                storageUsed: storageUsed
                            )
                        }
                    ))
                }
                
            case let .storageInfoLoaded(.success(info)):
                state.isLoading = false
                state.totalScans = info.totalScans
                state.storageUsed = info.storageUsed
                return .run { send in
                    let scans = try await scanHistoryClient.getAllScans()
                    await send(.recentScansLoaded(scans))
                }
                
            case let .storageInfoLoaded(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to load storage info: \(error.localizedDescription)"
                return .none
                
            case .deleteAllDataTapped:
                state.showingDeleteConfirmation = true
                return .none
                
            case .confirmDeleteAllData:
                state.showingDeleteConfirmation = false
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { send in
                    await send(.deleteAllDataResponse(
                        await TaskResult {
                            try await scanHistoryClient.deleteAllScans()
                            return true
                        }
                    ))
                }
                
            case .cancelDeleteAllData:
                state.showingDeleteConfirmation = false
                return .none
                
            case let .deleteAllDataResponse(.success(success)):
                state.isLoading = false
                if success {
                    state.totalScans = 0
                    state.storageUsed = "0 MB"
                    state.recentScans = []
                    return .send(.delegate(.dataDeleted))
                } else {
                    state.errorMessage = "Failed to delete data"
                    return .none
                }
                
            case let .deleteAllDataResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to delete data: \(error.localizedDescription)"
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            case let .setDeleteConfirmation(isPresented):
                state.showingDeleteConfirmation = isPresented
                return .none
                
            case let .recentScansLoaded(scans):
                state.recentScans = scans
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Helper Functions
private func calculateStorageUsed(for scans: [ScanRecord]) -> String {
    let totalBytes = scans.reduce(0) { total, scan in
        total + (scan.estimatedSize ?? 0)
    }
    
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useKB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(totalBytes))
}

private func estimateProductSize(_ product: SavedProduct) -> Int {
    var totalSize = 0
    
    // Basic fields (id, dates, version, etc) ~150 bytes
    totalSize += 150
    
    // Product name and brand
    totalSize += (product.productName.utf8.count)
    totalSize += (product.productBrand?.utf8.count ?? 0)
    
    // Image URL
    totalSize += (product.productImageUrl?.utf8.count ?? 0)
    
    // MeatScan data (simplified assessment ~1KB)
    totalSize += 1024
    
    // Full HealthAssessmentResponse if present (v2 products)
    if product.healthAssessment != nil {
        // Health assessment includes:
        // - Summary text (~500 bytes)
        // - Ingredients assessment (~2KB)
        // - Nutrition data (~1KB)
        // - Citations (~1KB)
        // - Product info (~500 bytes)
        totalSize += 5120 // ~5KB for full assessment
    }
    
    // Add overhead for JSON structure and encoding
    totalSize = Int(Double(totalSize) * 1.3)
    
    return totalSize
}

// MARK: - Mock Data Types
public struct ScanRecord: Equatable, Identifiable {
    public let id: String
    public let productName: String
    public let scanDate: Date
    public let estimatedSize: Int?
    
    public init(id: String, productName: String, scanDate: Date, estimatedSize: Int? = nil) {
        self.id = id
        self.productName = productName
        self.scanDate = scanDate
        self.estimatedSize = estimatedSize
    }
}

// MARK: - Scan History Client Dependency
@DependencyClient
public struct ScanHistoryClient: Sendable {
    public var getAllScans: @Sendable () async throws -> [ScanRecord] = { [] }
    public var deleteAllScans: @Sendable () async throws -> Void
}

extension ScanHistoryClient: DependencyKey {
    public static let liveValue = ScanHistoryClient(
        getAllScans: {
            @Dependency(\.scannedProducts) var scannedProducts
            
            let savedProducts = await scannedProducts.loadAll()
            
            return savedProducts.map { product in
                let estimatedSize = estimateProductSize(product)
                
                return ScanRecord(
                    id: product.id,
                    productName: product.productName,
                    scanDate: product.scanDate,
                    estimatedSize: estimatedSize
                )
            }
        },
        deleteAllScans: {
            @Dependency(\.scannedProducts) var scannedProducts
            await scannedProducts.clearAll()
        }
    )
    
    public static let testValue = ScanHistoryClient()
    public static let previewValue = ScanHistoryClient(
        getAllScans: {
            [
                ScanRecord(id: "1", productName: "Ground Beef", scanDate: Date(), estimatedSize: 256000),
                ScanRecord(id: "2", productName: "Chicken Breast", scanDate: Date(), estimatedSize: 184000),
                ScanRecord(id: "3", productName: "Pork Chops", scanDate: Date(), estimatedSize: 312000),
            ]
        },
        deleteAllScans: {}
    )
}

extension DependencyValues {
    public var scanHistoryClient: ScanHistoryClient {
        get { self[ScanHistoryClient.self] }
        set { self[ScanHistoryClient.self] = newValue }
    }
}