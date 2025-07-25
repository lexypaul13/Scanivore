//
//  ScannedProductsClient.swift
//  Scanivore
//
//  TCA-compliant client for saving scanned products for offline use
//

import Foundation
import Dependencies
import ComposableArchitecture

// MARK: - Scanned Product Model
public struct SavedProduct: Codable, Equatable, Identifiable {
    public let id: String // barcode
    public let productName: String
    public let productBrand: String?
    public let scanDate: Date
    public let meatScan: MeatScan
    public let isFavorite: Bool
    
    public init(
        id: String,
        productName: String,
        productBrand: String?,
        scanDate: Date,
        meatScan: MeatScan,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.productName = productName
        self.productBrand = productBrand
        self.scanDate = scanDate
        self.meatScan = meatScan
        self.isFavorite = isFavorite
    }
}

// MARK: - Scanned Products Client
@DependencyClient
public struct ScannedProductsClient: Sendable {
    public var loadAll: @Sendable () async -> [SavedProduct] = { [] }
    public var loadFavorites: @Sendable () async -> [SavedProduct] = { [] }
    public var save: @Sendable (SavedProduct) async -> Void
    public var delete: @Sendable (String) async -> Void
    public var toggleFavorite: @Sendable (String) async -> Void
    public var clearAll: @Sendable () async -> Void
    public var getProduct: @Sendable (String) async -> SavedProduct? = { _ in nil }
}

// MARK: - Dependency Key Conformance
extension ScannedProductsClient: DependencyKey {
    public static let liveValue: Self = .init(
        loadAll: {
            @Dependency(\.fileStorage) var fileStorage
            
            guard let data = try? await fileStorage.load("scanned_products.json") else {
                return []
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode([SavedProduct].self, from: data)) ?? []
        },
        
        loadFavorites: {
            @Dependency(\.fileStorage) var fileStorage
            
            guard let data = try? await fileStorage.load("scanned_products.json") else {
                return []
            }
            
            let allProducts = (try? JSONDecoder().decode([SavedProduct].self, from: data)) ?? []
            return allProducts.filter { $0.isFavorite }
        },
        
        save: { product in
            @Dependency(\.fileStorage) var fileStorage
            
            do {
                // Load existing products
                var products = await Self.liveValue.loadAll()
                
                // Remove existing product with same ID if exists (avoid duplicates)
                products.removeAll { $0.id == product.id }
                
                // Add new product at the beginning (newest first)
                products.insert(product, at: 0)
                
                // Limit to last 100 scans for performance
                if products.count > 100 {
                    products = Array(products.prefix(100))
                }
                
                // Save with optimized encoding
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(products)
                try await fileStorage.save("scanned_products.json", data)
            } catch {
                // Silent failure - could add analytics here
            }
        },
        
        delete: { productId in
            @Dependency(\.fileStorage) var fileStorage
            
            var products = await Self.liveValue.loadAll()
            products.removeAll { $0.id == productId }
            
            let data = try? JSONEncoder().encode(products)
            try? await fileStorage.save("scanned_products.json", data ?? Data())
        },
        
        toggleFavorite: { productId in
            @Dependency(\.fileStorage) var fileStorage
            
            var products = await Self.liveValue.loadAll()
            
            if let index = products.firstIndex(where: { $0.id == productId }) {
                products[index] = SavedProduct(
                    id: products[index].id,
                    productName: products[index].productName,
                    productBrand: products[index].productBrand,
                    scanDate: products[index].scanDate,
                    meatScan: products[index].meatScan,
                    isFavorite: !products[index].isFavorite
                )
            }
            
            let data = try? JSONEncoder().encode(products)
            try? await fileStorage.save("scanned_products.json", data ?? Data())
        },
        
        clearAll: {
            @Dependency(\.fileStorage) var fileStorage
            try? await fileStorage.delete("scanned_products.json")
        },
        
        getProduct: { productId in
            let products = await Self.liveValue.loadAll()
            return products.first { $0.id == productId }
        }
    )
    
    public static let testValue = Self()
    
    public static let previewValue: Self = .init(
        loadAll: { [
            SavedProduct(
                id: "1234567890123",
                productName: "Organic Ground Beef",
                productBrand: "Organic Valley",
                scanDate: Date(),
                meatScan: .mock,
                isFavorite: true
            ),
            SavedProduct(
                id: "9876543210987",
                productName: "Free Range Chicken Breast",
                productBrand: "Perdue",
                scanDate: Date().addingTimeInterval(-86400),
                meatScan: .mock,
                isFavorite: false
            )
        ] },
        loadFavorites: { [
            SavedProduct(
                id: "1234567890123",
                productName: "Organic Ground Beef",
                productBrand: "Organic Valley",
                scanDate: Date(),
                meatScan: .mock,
                isFavorite: true
            )
        ] },
        save: { _ in },
        delete: { _ in },
        toggleFavorite: { _ in },
        clearAll: { },
        getProduct: { _ in
            SavedProduct(
                id: "1234567890123",
                productName: "Organic Ground Beef",
                productBrand: "Organic Valley",
                scanDate: Date(),
                meatScan: .mock,
                isFavorite: true
            )
        }
    )
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var scannedProducts: ScannedProductsClient {
        get { self[ScannedProductsClient.self] }
        set { self[ScannedProductsClient.self] = newValue }
    }
}

// MARK: - File Storage Client (if not already exists)
@DependencyClient
public struct FileStorageClient: Sendable {
    public var save: @Sendable (String, Data) async throws -> Void
    public var load: @Sendable (String) async throws -> Data?
    public var delete: @Sendable (String) async throws -> Void
}

extension FileStorageClient: DependencyKey {
    public static let liveValue: Self = .init(
        save: { filename, data in
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsPath.appendingPathComponent(filename)
            try data.write(to: fileURL)
        },
        load: { filename in
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsPath.appendingPathComponent(filename)
            return try? Data(contentsOf: fileURL)
        },
        delete: { filename in
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsPath.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: fileURL)
        }
    )
    
    public static let testValue = Self()
    
    public static let previewValue = Self()
}

extension DependencyValues {
    public var fileStorage: FileStorageClient {
        get { self[FileStorageClient.self] }
        set { self[FileStorageClient.self] = newValue }
    }
} 
