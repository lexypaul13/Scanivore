//
//  ProductGateway.swift
//  Scanivore
//
//  TCA-compliant product gateway using Alamofire
//

import Foundation
import Alamofire
import Dependencies
import ComposableArchitecture
// MARK: - Product Gateway
@DependencyClient
public struct ProductGateway: Sendable {
    public var getProduct: @Sendable (String) async throws -> Product
    public var getHealthAssessment: @Sendable (String) async throws -> HealthAssessmentResponse
    public var getMeatScanFromBarcode: @Sendable (String) async throws -> MeatScan
    public var getAlternatives: @Sendable (String) async throws -> [Product]
    public var searchProducts: @Sendable (String) async throws -> [Product]
    public var getRecommendations: @Sendable () async throws -> ExploreResponse
    public var getExploreRecommendations: @Sendable (Int, Int) async throws -> ExploreResponse
}

// MARK: - Dependency Key Conformance
extension ProductGateway: DependencyKey {
    public static let liveValue: Self = .init(
        getProduct: { barcode in
            let headers = try await createAuthHeaders()
            
            return try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)",
                method: .get,
                headers: headers
            )
            .validate()
            .serializingDecodable(Product.self)
            .value
        },
        
        getHealthAssessment: { barcode in
            let headers = try await createAuthHeaders()
            
            return try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)/health-assessment-mcp",
                method: .get,
                parameters: ["format": "mobile"],
                headers: headers
            )
            .validate()
            .serializingDecodable(HealthAssessmentResponse.self)
            .value
        },
        
        getMeatScanFromBarcode: { barcode in
            let headers = try await createAuthHeaders()
            
            let healthAssessment = try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)/health-assessment-mcp",
                method: .get,
                parameters: ["format": "mobile"],
                headers: headers
            )
            .validate()
            .serializingDecodable(HealthAssessmentResponse.self)
            .value
            
            // Convert to MeatScan using existing extension
            return healthAssessment.toMeatScan(barcode: barcode)
        },
        
        getAlternatives: { barcode in
            let headers = try await createAuthHeaders()
            
            return try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)/alternatives",
                method: .get,
                headers: headers
            )
            .validate()
            .serializingDecodable([Product].self)
            .value
        },
        
        searchProducts: { query in
            let headers = try await createAuthHeaders()
            
            return try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/products/nlp-search",
                method: .get,
                parameters: ["q": query],
                headers: headers
            )
            .validate()
            .serializingDecodable([Product].self)
            .value
        },
        
        getRecommendations: {
            let headers = try await createAuthHeaders()
            
            return try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/products/recommendations",
                method: .get,
                headers: headers
            )
            .validate()
            .serializingDecodable(ExploreResponse.self)
            .value
        },
        
        getExploreRecommendations: { offset, limit in
            let headers = try await createAuthHeaders()
            
            return try await AF.request(
                "\(APIConfiguration.baseURL)/api/v1/users/explore",
                method: .get,
                parameters: ["offset": offset, "limit": limit],
                headers: headers
            )
            .validate()
            .serializingDecodable(ExploreResponse.self)
            .value
        }
    )
    
    public static let testValue = Self()
    
    public static let previewValue: Self = .init(
        getProduct: { _ in .mock },
        getHealthAssessment: { _ in .mockHealthAssessment },
        getMeatScanFromBarcode: { barcode in .mockMeatScan(barcode: barcode) },
        getAlternatives: { _ in [.mock] },
        searchProducts: { _ in [.mock] },
        getRecommendations: { .mockExploreResponse },
        getExploreRecommendations: { _, _ in .mockExploreResponse }
    )
}



// MARK: - Dependency Extension
extension DependencyValues {
    public var productGateway: ProductGateway {
        get { self[ProductGateway.self] }
        set { self[ProductGateway.self] = newValue }
    }
}

// MARK: - Helper Functions
@Sendable
private func createAuthHeaders() async throws -> HTTPHeaders {
    var headers = HTTPHeaders()
    headers.add(.contentType("application/json"))
    
    if let token = try await TokenManager.shared.getToken() {
        headers.add(.authorization(bearerToken: token))
    }
    
    return headers
}

// MARK: - Mock Data
extension Product {
    static let mock = Product(
        code: "mock_barcode_123",
        name: "Mock Beef Product",
        brand: "Mock Brand",
        categories: ["meat", "beef"],
        ingredients: ["beef", "salt", "natural flavors"],
        nutritionFacts: NutritionFacts(
            servingSize: "100g",
            calories: 250,
            totalFat: 17.0,
            saturatedFat: 7.0,
            transFat: 0.0,
            cholesterol: 80,
            sodium: 75,
            totalCarbs: 0.0,
            fiber: 0.0,
            sugars: 0.0,
            protein: 26.0
        ),
        image_url: "https://example.com/beef.jpg",
        image_data: nil,
        risk_rating: "Green"
    )
}

extension HealthAssessmentResponse {
    static let mockHealthAssessment = HealthAssessmentResponse(
        summary: "This is a high-quality beef product with excellent nutritional profile. Rich in protein and essential nutrients.",
        riskSummary: RiskSummary(grade: "A", color: "Green", score: 92),
        ingredientsAssessment: IngredientsAssessment(
            highRisk: [],
            moderateRisk: [
                IngredientRisk(name: "Salt", microReport: "Moderate sodium content. Consider portion control.", riskLevel: "moderate")
            ],
            lowRisk: [
                IngredientRisk(name: "Beef", microReport: "High-quality protein source", riskLevel: "low")
            ]
        ),
        nutritionInsights: [
            NutritionInsight(
                nutrient: "Protein",
                amountPerServing: "26g",
                evaluation: "excellent",
                dailyValue: "52%",
                recommendation: "Great source of complete protein"
            ),
            NutritionInsight(
                nutrient: "Sodium",
                amountPerServing: "75mg",
                evaluation: "low",
                dailyValue: "3%",
                recommendation: "Low sodium content supports heart health"
            )
        ],
        citations: [
            Citation(
                id: 1,
                title: "Nutritional Benefits of Lean Beef",
                authors: "Smith, J. et al.",
                journal: "Journal of Nutrition",
                year: 2023,
                doi: "10.1234/jn.2023.001",
                url: "https://example.com/citation1"
            )
        ],
        lastUpdated: "2024-01-15T10:30:00Z"
    )
}

extension MeatScan {
    static func mockMeatScan(barcode: String) -> MeatScan {
        MeatScan(
            date: Date(),
            image: barcode,
            meatType: .beef,
            quality: QualityRating(score: 92, grade: "A"),
            freshness: .fresh,
            nutritionInfo: NutritionInfo(
                calories: 250,
                protein: 26.0,
                fat: 17.0,
                saturatedFat: 7.0,
                cholesterol: 80,
                sodium: 75
            ),
            warnings: [],
            recommendations: ["High-quality protein source", "Low sodium content supports heart health"]
        )
    }
}

extension ExploreResponse {
    static let mockExploreResponse = ExploreResponse(
        recommendations: [
            RecommendationItem(
                product: .mock,
                matchDetails: MatchDetails(
                    matches: ["High protein content", "Grass-fed meat", "Low sodium"],
                    concerns: []
                ),
                matchScore: 0.95
            )
        ],
        totalMatches: 25
    )
}
