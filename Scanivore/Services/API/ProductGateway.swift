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

// MARK: - Alamofire Session Configuration
// Shared session with standard SSL validation
private let sharedOptimizedSession: Session = {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = APIConfiguration.timeout
    configuration.timeoutIntervalForResource = APIConfiguration.healthAssessmentTimeout
    return Session(configuration: configuration)
}()

private func createOptimizedSession() -> Session {
    // Return the shared session to prevent sessionDeinitialized errors
    return sharedOptimizedSession
}

// MARK: - Product Gateway
@DependencyClient
public struct ProductGateway: Sendable {
    public var getProduct: @Sendable (String) async throws -> Product
    public var getHealthAssessment: @Sendable (String) async throws -> HealthAssessmentResponse
    public var getMeatScanFromBarcode: @Sendable (String) async throws -> MeatScan
    // getAlternatives removed - feature disabled
    public var searchProducts: @Sendable (String) async throws -> SearchResponse
    public var getRecommendations: @Sendable (Int, Int) async throws -> ExploreResponse
    public var getExploreRecommendations: @Sendable (Int, Int) async throws -> ExploreResponse
}

// MARK: - Dependency Key Conformance
extension ProductGateway: DependencyKey {
    public static let liveValue: Self = .init(
        getProduct: { barcode in
            let headers = try await createAuthHeaders()
            let url = "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)"
            
            
            let response = try await sharedOptimizedSession.request(
                url,
                method: .get,
                headers: headers
            )
            .validate()
            .serializingData()
            .value
            
            
            // Decode JSON on background queue to avoid main thread blocking
            let product = try await Task.detached(priority: .userInitiated) {
                let decoder = JSONDecoder()
                return try decoder.decode(Product.self, from: response)
            }.value
            
            // Strip image_data to prevent massive memory usage (keep only image_url)
            return Product(
                code: product.code,
                name: product.name,
                brand: product.brand,
                categories: product.categories,
                ingredients: product.ingredients,
                nutritionFacts: product.nutritionFacts,
                image_url: product.image_url,
                image_data: nil,  // Remove massive base64 data
                risk_rating: product.risk_rating,
                description: product.description,
                ingredients_text: product.ingredients_text,
                calories: product.calories,
                protein: product.protein,
                fat: product.fat,
                carbohydrates: product.carbohydrates,
                salt: product.salt,
                meat_type: product.meat_type,
                contains_nitrites: product.contains_nitrites,
                contains_phosphates: product.contains_phosphates,
                contains_preservatives: product.contains_preservatives,
                antibiotic_free: product.antibiotic_free,
                hormone_free: product.hormone_free,
                pasture_raised: product.pasture_raised,
                last_updated: product.last_updated,
                created_at: product.created_at,
                _relevance_score: product._relevance_score
            )
        },
        
        getHealthAssessment: { barcode in
            // Check cache first with performance-aware feedback (async to avoid main thread blocking)
            if let cacheResult = await HealthAssessmentCache.shared.getCachedAssessment(for: barcode) {
                return cacheResult.assessment
            }
            
            // Cache miss - fetch from optimized backend (~5s)
            let headers = try await createAuthHeaders()
            let url = "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)/health-assessment-mcp?format=\(APIConfiguration.ResponseFormat.mobile)"
            
            
            let startTime = Date()
            var lastError: Error?
            let maxRetries = 2
            
            // Retry logic for timeout errors
            for attempt in 0...maxRetries {
                do {
                    if attempt > 0 {
                        // Exponential backoff: 1s, 2s
                        try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                    }
                    
                    let response = try await sharedOptimizedSession.request(
                        url,
                        method: .get,
                        headers: headers
                    )
                    .validate(statusCode: 200..<300)
                    .serializingData()
                    .value
                
                    
                    // Decode JSON on background queue to avoid main thread blocking
                    let decodedResponse = try await Task.detached(priority: .userInitiated) {
                        let decoder = JSONDecoder()
                        return try decoder.decode(HealthAssessmentResponse.self, from: response)
                    }.value
                    
                    
                    // Cache the response for future instant access (async to avoid main thread blocking)
                    await HealthAssessmentCache.shared.cacheAssessment(decodedResponse, for: barcode)
                    
                    return decodedResponse
                    
                } catch {
                    lastError = error
                    
                    // Check for timeout errors - handle both direct URLError and AFError wrapped cases
                    var isTimeoutError = false
                    
                    if let urlError = error as? URLError, urlError.code == .timedOut {
                        isTimeoutError = true
                    } else if let afError = error as? AFError,
                              case .sessionTaskFailed(let underlyingError) = afError,
                              let urlError = underlyingError as? URLError,
                              urlError.code == .timedOut {
                        isTimeoutError = true
                    }
                    
                    if isTimeoutError {
                        if attempt < maxRetries {
                            // Wait longer between retries for timeout issues
                            try await Task.sleep(nanoseconds: UInt64((attempt + 1) * 2) * 1_000_000_000) // 2s, 4s
                            continue // Try again
                        }
                    }
                    
                    // For non-timeout errors, don't retry
                    break
                }
            }
            
            // If we got here, all retries failed
            if let error = lastError {
                
                // Check for timeout error first - handle both direct URLError and AFError wrapped cases
                var isTimeoutError = false
                
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    isTimeoutError = true
                } else if let afError = error as? AFError,
                          case .sessionTaskFailed(let underlyingError) = afError,
                          let urlError = underlyingError as? URLError,
                          urlError.code == .timedOut {
                    isTimeoutError = true
                }
                
                if isTimeoutError {
                    throw APIError(
                        detail: "Health assessment is taking longer than usual. Please try again or check your network connection.",
                        statusCode: -1001
                    )
                }
                
                // If it's a validation error, try to get more specific error information
                if let afError = error as? AFError {
                    switch afError {
                    case .responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)):
                        
                        // For API failures, throw a descriptive error
                        if statusCode >= 500 {
                            throw APIError(
                                detail: "Health assessment service temporarily unavailable. Basic product grade available from barcode scan.",
                                statusCode: statusCode
                            )
                        } else if statusCode == 404 {
                            throw APIError(
                                detail: "Detailed health assessment not available for this product. Basic safety grade shown.",
                                statusCode: statusCode
                            )
                        } else {
                            throw APIError(
                                detail: "Health assessment temporarily unavailable. Basic product safety information shown.",
                                statusCode: statusCode
                            )
                        }
                    default:
                        break
                    }
                }
                
                // Re-throw the original error for other cases
                throw error
            }
            
            // This should never be reached, but provide a fallback
            throw APIError(detail: "Unexpected error during health assessment", statusCode: -1)
        },
        
        getMeatScanFromBarcode: { barcode in
            let headers = try await createAuthHeaders()
            
            let healthAssessment = try await sharedOptimizedSession.request(
                "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)/health-assessment-mcp?format=\(APIConfiguration.ResponseFormat.mobile)",
                method: .get,
                headers: headers
            )
            .validate()
            .serializingDecodable(HealthAssessmentResponse.self)
            .value
            
            // Convert to MeatScan using existing extension
            return healthAssessment.toMeatScan(barcode: barcode)
        },
        
        // getAlternatives implementation removed to fix 404 errors
        
        searchProducts: { query in
            let headers = try await createAuthHeaders()
            
            let searchResponse = try await sharedOptimizedSession.request(
                "\(APIConfiguration.baseURL)/api/v1/products/search",
                method: .get,
                parameters: ["q": query],
                headers: headers
            )
            .validate()
            .serializingDecodable(SearchResponse.self)
            .value
            
            // Strip image_data from search results to prevent massive memory usage
            let optimizedProducts = searchResponse.products.map { product in
                Product(
                    code: product.code,
                    name: product.name,
                    brand: product.brand,
                    categories: product.categories,
                    ingredients: product.ingredients,
                    nutritionFacts: product.nutritionFacts,
                    image_url: product.image_url,
                    image_data: nil,  // Remove massive base64 data
                    risk_rating: product.risk_rating,
                    description: product.description,
                    ingredients_text: product.ingredients_text,
                    calories: product.calories,
                    protein: product.protein,
                    fat: product.fat,
                    carbohydrates: product.carbohydrates,
                    salt: product.salt,
                    meat_type: product.meat_type,
                    contains_nitrites: product.contains_nitrites,
                    contains_phosphates: product.contains_phosphates,
                    contains_preservatives: product.contains_preservatives,
                    antibiotic_free: product.antibiotic_free,
                    hormone_free: product.hormone_free,
                    pasture_raised: product.pasture_raised,
                    last_updated: product.last_updated,
                    created_at: product.created_at,
                    _relevance_score: product._relevance_score
                )
            }
            
            return SearchResponse(
                query: searchResponse.query,
                totalResults: searchResponse.totalResults,
                limit: searchResponse.limit,
                skip: searchResponse.skip,
                products: optimizedProducts
             )
        },
        
        getRecommendations: { offset, pageSize in
            let headers = try await createAuthHeaders()
            
            let exploreResponse = try await sharedOptimizedSession.request(
                "\(APIConfiguration.baseURL)/api/v1/products/recommendations",
                method: .get,
                parameters: ["offset": offset, "page_size": pageSize],
                headers: headers
            )
            .validate()
            .serializingDecodable(ExploreResponse.self)
            .value
            
            // Strip image_data from recommendations to prevent massive memory usage and debug logs
            let optimizedRecommendations = exploreResponse.recommendations.map { item in
                let optimizedProduct = Product(
                    code: item.product.code,
                    name: item.product.name,
                    brand: item.product.brand,
                    categories: item.product.categories,
                    ingredients: item.product.ingredients,
                    nutritionFacts: item.product.nutritionFacts,
                    image_url: item.product.image_url,
                    image_data: nil,  // Remove massive base64 data that causes debug spam
                    risk_rating: item.product.risk_rating,
                    description: item.product.description,
                    ingredients_text: item.product.ingredients_text,
                    calories: item.product.calories,
                    protein: item.product.protein,
                    fat: item.product.fat,
                    carbohydrates: item.product.carbohydrates,
                    salt: item.product.salt,
                    meat_type: item.product.meat_type,
                    contains_nitrites: item.product.contains_nitrites,
                    contains_phosphates: item.product.contains_phosphates,
                    contains_preservatives: item.product.contains_preservatives,
                    antibiotic_free: item.product.antibiotic_free,
                    hormone_free: item.product.hormone_free,
                    pasture_raised: item.product.pasture_raised,
                    last_updated: item.product.last_updated,
                    created_at: item.product.created_at,
                    _relevance_score: item.product._relevance_score
                )
                
                return RecommendationItem(
                    product: optimizedProduct,
                    matchDetails: item.matchDetails,
                    matchScore: item.matchScore
                )
            }
            return ExploreResponse(
                recommendations: optimizedRecommendations,
                totalMatches: exploreResponse.totalMatches,
                hasMore: nil,
                offset: nil,
                limit: nil
            )
        },
        
        getExploreRecommendations: { offset, limit in
            let headers = try await createAuthHeaders()
            
            
            do {
                let userExploreResponse = try await sharedOptimizedSession.request(
                    "\(APIConfiguration.baseURL)/api/v1/users/explore",
                    method: .get,
                    parameters: ["offset": offset, "limit": limit],
                    headers: headers
                )
                .validate()
                .serializingDecodable(UserExploreResponse.self)
                .value
                
                
                // Strip image_data from user explore results to prevent massive memory usage
                let optimizedProducts = userExploreResponse.recommendations.map { product in
                Product(
                    code: product.code,
                    name: product.name,
                    brand: product.brand,
                    categories: product.categories,
                    ingredients: product.ingredients,
                    nutritionFacts: product.nutritionFacts,
                    image_url: product.image_url,
                    image_data: nil,  // Remove massive base64 data
                    risk_rating: product.risk_rating,
                    description: product.description,
                    ingredients_text: product.ingredients_text,
                    calories: product.calories,
                    protein: product.protein,
                    fat: product.fat,
                    carbohydrates: product.carbohydrates,
                    salt: product.salt,
                    meat_type: product.meat_type,
                    contains_nitrites: product.contains_nitrites,
                    contains_phosphates: product.contains_phosphates,
                    contains_preservatives: product.contains_preservatives,
                    antibiotic_free: product.antibiotic_free,
                    hormone_free: product.hormone_free,
                    pasture_raised: product.pasture_raised,
                    last_updated: product.last_updated,
                    created_at: product.created_at,
                    _relevance_score: product._relevance_score
                )
            }
            
            // Convert Products to RecommendationItems for UI compatibility
            let recommendationItems = optimizedProducts.map { product in
                RecommendationItem(
                    product: product,
                    matchDetails: MatchDetails(matches: [], concerns: []),
                    matchScore: nil
                )
            }
            
                return ExploreResponse(
                    recommendations: recommendationItems,
                    totalMatches: userExploreResponse.totalMatches,
                    hasMore: userExploreResponse.hasMore,
                    offset: userExploreResponse.offset,
                    limit: userExploreResponse.limit
                )
            } catch {
                throw error
            }
        }
    )
    
    public static let testValue = Self()
    
    public static let previewValue: Self = .init(
        getProduct: { _ in .mock },
        getHealthAssessment: { _ in .mockHealthAssessment },
        getMeatScanFromBarcode: { barcode in .mockMeatScan(barcode: barcode) },
        // getAlternatives removed
        searchProducts: { _ in .mockSearchResponse },
        getRecommendations: { _, _ in .mockExploreResponse },
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
        risk_rating: "Green",
        // Additional NLP search fields
        description: "Premium grass-fed beef",
        ingredients_text: "Beef, salt, natural flavors",
        calories: 250,
        protein: 26.0,
        fat: 17.0,
        carbohydrates: 0.0,
        salt: 0.075,
        meat_type: "beef",
        contains_nitrites: false,
        contains_phosphates: false,
        contains_preservatives: false,
        antibiotic_free: true,
        hormone_free: true,
        pasture_raised: true,
        last_updated: "2024-01-15T10:30:00Z",
        created_at: "2023-12-01T08:00:00Z",
        _relevance_score: 0.95
    )
}

extension HealthAssessmentResponse {
    static let mockHealthAssessment = HealthAssessmentResponse(
        summary: "Ground Turkey contains high-risk preservatives requiring caution. Moderate consumption recommended.",
        grade: "C",
        color: "Yellow",
        ingredientsAssessment: IngredientsAssessment(
            highRisk: [
                IngredientRisk(name: "Preservatives", risk: "Contains high-risk preservatives requiring caution. May cause allergic reactions in sensitive individuals.", overview: "Preservatives are chemical compounds added to foods to prevent spoilage and extend shelf life. While they serve an important function in food safety, some preservatives have been linked to adverse health effects including allergic reactions, hyperactivity in children, and potential carcinogenic properties with long-term exposure.", riskLevel: "high")
            ],
            moderateRisk: [
                IngredientRisk(name: "Salt", risk: "Moderate sodium content. Consider portion control for heart health.", overview: "Salt (sodium chloride) is an essential mineral used for flavor enhancement and preservation. While necessary for bodily functions, excessive intake is linked to high blood pressure, heart disease, and stroke. The American Heart Association recommends limiting sodium intake to 2,300mg per day.", riskLevel: "moderate"),
                IngredientRisk(name: "Natural Flavors", risk: "Added flavoring that may contain allergens. Generally safe for most people.", overview: "Natural flavors are derived from plant or animal sources and used to enhance taste. While generally recognized as safe, they can contain undisclosed ingredients and may trigger allergic reactions in sensitive individuals. The exact composition is often proprietary.", riskLevel: "moderate")
            ],
            lowRisk: [
                IngredientRisk(name: "Turkey", risk: "High-quality lean protein source with essential amino acids.", overview: "", riskLevel: "low"),
                IngredientRisk(name: "Water", risk: "Used for processing. Safe and necessary for food preparation.", overview: "", riskLevel: "low")
            ]
        ),
        nutrition: [
            NutritionInsight(
                nutrient: "Protein",
                amount: "22g",
                eval: "excellent",
                comment: "Great source of lean protein",
                dailyValue: "44%",
                recommendation: "Great source of lean protein"
            ),
            NutritionInsight(
                nutrient: "Calories",
                amount: "120",
                eval: "good",
                comment: "Low calorie option for weight management",
                dailyValue: "6%",
                recommendation: "Low calorie option for weight management"
            ),
            NutritionInsight(
                nutrient: "Fat",
                amount: "8g",
                eval: "moderate",
                comment: "Moderate fat content",
                dailyValue: "12%",
                recommendation: "Moderate fat content"
            ),
            NutritionInsight(
                nutrient: "Sodium",
                amount: "380mg",
                eval: "high",
                comment: "Higher sodium content - monitor intake",
                dailyValue: "16%",
                recommendation: "Higher sodium content - monitor intake"
            )
        ],
        citations: [], // Only real citations from backend API - no mock data for App Store compliance
        meta: ResponseMetadata(
            product: "Mock Ground Turkey",
            generated: "2024-01-15T10:30:00Z"
        ), product_info: nil,
        // Direct API fields matching actual response structure
        high_risk: [
            IngredientRisk(name: "Preservatives", risk: "Contains high-risk preservatives requiring caution. May cause allergic reactions in sensitive individuals.", overview: nil, riskLevel: "high")
        ],
        moderate_risk: [
            IngredientRisk(name: "Salt", risk: "Moderate sodium content. Consider portion control for heart health.", overview: "", riskLevel: "moderate"),
            IngredientRisk(name: "Natural Flavors", risk: "Added flavoring that may contain allergens. Generally safe for most people.", overview: "", riskLevel: "moderate")
        ],
        low_risk: [
            IngredientRisk(name: "Turkey", risk: "High-quality lean protein source with essential amino acids.", overview: "", riskLevel: "low"),
            IngredientRisk(name: "Water", risk: "Used for processing. Safe and necessary for food preparation.", overview: "", riskLevel: "low")
        ]
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
        totalMatches: 25,
        hasMore: true,
        offset: 0,
        limit: 10
    )
}

extension SearchResponse {
    static let mockSearchResponse = SearchResponse(
        query: "healthy chicken",
        totalResults: 1,
        limit: 20,
        skip: 0,
        products: [.mock]
    )
}
