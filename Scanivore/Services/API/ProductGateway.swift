
import Foundation
import Alamofire
import Dependencies
import ComposableArchitecture
import Network

// MARK: - Alamofire Session Configuration
private let sharedOptimizedSession: Session = {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 60.0  // Increased from 15s to prevent premature timeouts
    configuration.timeoutIntervalForResource = APIConfiguration.healthAssessmentTimeout
    configuration.waitsForConnectivity = true  // Wait for network connectivity
    
    configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
    configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
    configuration.urlCache = URLCache.shared
    configuration.requestCachePolicy = .useProtocolCachePolicy
    
    configuration.multipathServiceType = .none
    configuration.httpMaximumConnectionsPerHost = 6

    let serverTrustManager = ServerTrustManager(evaluators: [
        "clear-meat-api-production.up.railway.app": DefaultTrustEvaluator(
            validateHost: true
        )
    ])
    
    return Session(
        configuration: configuration,
        serverTrustManager: serverTrustManager
    )
}()

private func createOptimizedSession() -> Session {
    return sharedOptimizedSession
}

// MARK: - Product Gateway
@DependencyClient
public struct ProductGateway: Sendable {
    public var getProduct: @Sendable (String) async throws -> Product
    public var getHealthAssessment: @Sendable (String) async throws -> HealthAssessmentResponse
    public var getMeatScanFromBarcode: @Sendable (String) async throws -> MeatScan
    public var getIndividualIngredientAnalysis: @Sendable (String, String?) async throws -> IndividualIngredientAnalysisResponseWithName
    public var searchProducts: @Sendable (String, Int, Int) async throws -> SearchResponse
    public var getRecommendations: @Sendable (Int, Int) async throws -> ExploreResponse
    public var getExploreRecommendations: @Sendable (Int, Int) async throws -> ExploreResponse
}

// MARK: - Dependency Key Conformance
extension ProductGateway: DependencyKey {
    public static let liveValue: ProductGateway = ProductGateway(
        getProduct: { (barcode: String) async throws -> Product in
            let headers = try await createAuthHeaders()
            let url = "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)"
            
            
            let session = createOptimizedSession()
            let response = try await session.request(
                url,
                method: .get,
                headers: headers
            )
            .validate()
            .serializingData()
            .value

            let productResponse = try await Task.detached(priority: .userInitiated) {
                let decoder = JSONDecoder()
                return try decoder.decode(ProductResponse.self, from: response)
            }.value

            return productResponse.product.withoutImageData()
        },
        
        getHealthAssessment: { (barcode: String) async throws -> HealthAssessmentResponse in

            if let cacheResult = await HealthAssessmentCache.shared.getCachedAssessment(for: barcode) {
                return cacheResult.assessment
            }

            let headers = try await createAuthHeaders()
            let url = "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)/health-assessment-mcp?format=\(APIConfiguration.ResponseFormat.mobile)"

            for header in headers {
                if header.name.lowercased() == "authorization" {
                    let authValue = header.value
                    if authValue.hasPrefix("Bearer ") {
                        let token = String(authValue.dropFirst(7))
                    } else {
                    }
                } else {
                }
            }
            
            
            let startTime = Date()
            var lastError: Error?
            let maxRetries = 2
            for attempt in 0...maxRetries {
                do {
                    if attempt > 0 {
                        try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                    }


                    let session = createOptimizedSession()
                    let response = try await session.request(
                        url,
                        method: .get,
                        headers: headers
                    )
                    .validate(statusCode: 200..<300)
                    .serializingData()
                    .value

                    if let responseString = String(data: response, encoding: .utf8) {
                    }
                
                    
                    let decodedResponse = try await Task.detached(priority: .userInitiated) {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(HealthAssessmentResponse.self, from: response)
                        
                        
                        return result
                    }.value
                    
                    
                    await HealthAssessmentCache.shared.cacheAssessment(decodedResponse, for: barcode)
                    
                    return decodedResponse
                    
                } catch {
                    lastError = error


                    if let afError = error as? AFError {
                        switch afError {
                        case .responseValidationFailed(let reason):
                            if case .unacceptableStatusCode(let code) = reason {
                                if code == 400 {
                                }
                            }
                        case .responseSerializationFailed:
                            break
                        default:
                            break
                        }

                        switch afError {
                        case .responseValidationFailed(let reason):
                            if case .dataFileNil = reason {
                            }
                        default:
                            break
                        }
                    }
                    
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
                            try await Task.sleep(nanoseconds: UInt64((attempt + 1) * 2) * 1_000_000_000) // 2s, 4s
                            continue
                        }
                    }
                    break
                }
            }
            
            if let error = lastError {
                
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
                    let networkMonitor = await NetworkMonitor.shared
                    let elapsed = Date().timeIntervalSince(startTime)
                    
                    if elapsed < 60 {
                        if await !networkMonitor.isConnected {
                            throw APIError(
                                detail: "No internet connection. Please check your network settings and try again.",
                                statusCode: -1001
                            )
                        } else if await networkMonitor.isConnectedViaCellular {
                            throw APIError(
                                detail: "Slow cellular connection. Try switching to WiFi or move to an area with better signal.",
                                statusCode: -1001
                            )
                        } else {
                            throw APIError(
                                detail: "Network connection issue. Please check your internet connection and try again.",
                                statusCode: -1001
                            )
                        }
                    } else {
                        throw APIError(
                            detail: "Health assessment is taking longer than usual. Our AI is analyzing complex ingredient interactions and gathering medical citations. Please wait or try again.",
                            statusCode: -1001
                        )
                    }
                }
                
                if let afError = error as? AFError {
                    switch afError {
                    case .responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)):
                        
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
                
                throw error
            }
            
            throw APIError(detail: "Unexpected error during health assessment", statusCode: -1)
        },
        
        getMeatScanFromBarcode: { (barcode: String) async throws -> MeatScan in
            let headers = try await createAuthHeaders()
            
            let session = createOptimizedSession()
            let healthAssessment = try await session.request(
                "\(APIConfiguration.baseURL)/api/v1/products/\(barcode)/health-assessment-mcp?format=\(APIConfiguration.ResponseFormat.mobile)",
                method: .get,
                headers: headers
            )
            .validate()
            .serializingDecodable(HealthAssessmentResponse.self)
            .value
            
            return healthAssessment.toMeatScan(barcode: barcode)
        },
        
        getIndividualIngredientAnalysis: { (ingredientName: String, context: String?) async throws -> IndividualIngredientAnalysisResponseWithName in
            let headers = try await createAuthHeaders()
            
            let sanitizedIngredient = ingredientName
                .replacingOccurrences(of: "/", with: " ")
                .replacingOccurrences(of: "\\", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let encodedIngredientName = sanitizedIngredient.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? sanitizedIngredient
            let url = "\(APIConfiguration.baseURL)/api/v1/ingredients/\(encodedIngredientName)/analysis"
            
            #if DEBUG
            #endif
            
            var parameters: [String: String] = [:]
            if let context = context {
                parameters["context"] = context
            }
            
            #if DEBUG
            if APIConfiguration.shouldLogAPIResponses {
            }
            #endif
            
            let session = createOptimizedSession()
            
            #if DEBUG
            #endif
            
            do {
                let response = try await session.request(
                    url,
                    method: .get,
                    parameters: parameters.isEmpty ? nil : parameters,
                    headers: headers
                )
                .validate()
                .serializingData()
                .value
                
                #if DEBUG
                #endif
                

                if let responseString = String(data: response, encoding: .utf8) {
                } else {
                }
                
                let decoder = JSONDecoder()
                var result: IndividualIngredientAnalysisResponse
                
                do {
                    result = try decoder.decode(IndividualIngredientAnalysisResponse.self, from: response)
                    #if DEBUG
                    if APIConfiguration.shouldLogAPIResponses {
                    }
                    #endif
                } catch {
                    #if DEBUG
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .dataCorrupted:
                            break
                        case .keyNotFound:
                            break
                        case .typeMismatch:
                            break
                        case .valueNotFound(let type, let context):
                            print("🔍 [Individual Ingredient Analysis] Value not found: \(type), context: \(context)")
                        @unknown default:
                            break
                        }
                    }
                    #endif
                    throw error
                }
                
                let responseWithName = IndividualIngredientAnalysisResponseWithName(
                    ingredientName: ingredientName,
                    analysisText: result.analysisText,
                    riskLevel: result.riskLevel,
                    riskScore: result.riskScore,
                    healthEffects: result.healthEffects,
                    recommendedIntake: result.recommendedIntake,
                    alternatives: result.alternatives,
                    citations: result.citations,
                    metadata: result.metadata
                )
                
                return responseWithName
                
            } catch {
                #if DEBUG
                if let afError = error as? AFError {
                    switch afError {
                    case .responseValidationFailed:
                        break
                    case .sessionTaskFailed:
                        break
                    default:
                        break
                    }
                }
                #endif
                throw error
            }
        },
        
        searchProducts: { (query: String, offset: Int, limit: Int) async throws -> SearchResponse in
            let headers = try await createAuthHeaders()

            let session = createOptimizedSession()
            let searchResponse = try await session.request(
                "\(APIConfiguration.baseURL)/api/v1/products/search",
                method: .get,
                parameters: ["q": query, "skip": offset, "limit": limit],
                headers: headers
            )
            .validate()
            .serializingDecodable(SearchResponse.self)
            .value
            let optimizedProducts = searchResponse.products.map { $0.withoutImageData() }
            
            return SearchResponse(
                query: searchResponse.query,
                totalResults: searchResponse.totalResults,
                limit: searchResponse.limit,
                skip: searchResponse.skip,
                products: optimizedProducts
             )
        },
        
        getRecommendations: { (offset: Int, pageSize: Int) async throws -> ExploreResponse in
            let headers = try await createAuthHeaders()
            
            let session = createOptimizedSession()
            let exploreResponse = try await session.request(
                "\(APIConfiguration.baseURL)/api/v1/products/recommendations",
                method: .get,
                parameters: ["offset": offset, "page_size": pageSize],
                headers: headers
            )
            .validate()
            .serializingDecodable(ExploreResponse.self)
            .value
            
            let optimizedRecommendations = exploreResponse.recommendations.map { item in
                item.withoutImageData()
            }
            return ExploreResponse(
                recommendations: optimizedRecommendations,
                totalMatches: exploreResponse.totalMatches,
                hasMore: nil,
                offset: nil,
                limit: nil
            )
        },
        
        getExploreRecommendations: { (offset: Int, limit: Int) async throws -> ExploreResponse in

            let headers = try await createAuthHeaders()

            let exploreURL: String
            let isAuthenticated = (try? await TokenManager.shared.getToken()) != nil

            if isAuthenticated {
                exploreURL = "\(APIConfiguration.baseURL)\(APIConfiguration.Endpoints.explore)"
            } else {
                exploreURL = "\(APIConfiguration.baseURL)\(APIConfiguration.Endpoints.publicExplore)"
            }

            
            do {
                let session = createOptimizedSession()
                let userExploreResponse = try await session.request(
                    exploreURL,
                    method: .get,
                    parameters: ["offset": offset, "limit": limit],
                    headers: headers
                )
                .validate()
                .serializingData()
                .value
                
                
                let decodedResponse = try JSONDecoder().decode(UserExploreResponse.self, from: userExploreResponse)

                let optimizedRecommendations = decodedResponse.recommendations.map { item in
                    item.withoutImageData()
                }

                return ExploreResponse(
                    recommendations: optimizedRecommendations,
                    totalMatches: decodedResponse.totalMatches,
                    hasMore: decodedResponse.hasMore,
                    offset: decodedResponse.offset,
                    limit: decodedResponse.limit
                )
            } catch {

                if let afError = error as? AFError {
                    switch afError {
                    case .responseValidationFailed(let reason):
                        if case .unacceptableStatusCode(let code) = reason {
                            if code == 400 {
                            } else if code == 401 && isAuthenticated {
                            }
                        }
                    default:
                        break
                    }

                    switch afError {
                    case .responseValidationFailed(let reason):
                        if case .dataFileNil = reason {
                        }
                    default:
                        break
                    }
                }

                throw error
            }
        }
    )
    
    public static let previewValue: ProductGateway = ProductGateway(
        getProduct: { (_: String) async throws -> Product in .mock },
        getHealthAssessment: { (_: String) async throws -> HealthAssessmentResponse in .mockHealthAssessment },
        getMeatScanFromBarcode: { (barcode: String) async throws -> MeatScan in .mockMeatScan(barcode: barcode) },
        getIndividualIngredientAnalysis: { (ingredientName: String, _: String?) async throws -> IndividualIngredientAnalysisResponseWithName in .mockIndividualAnalysis(for: ingredientName) },
        searchProducts: { (_: String, _: Int, _: Int) async throws -> SearchResponse in .mockSearchResponse },
        getRecommendations: { (_: Int, _: Int) async throws -> ExploreResponse in .mockExploreResponse },
        getExploreRecommendations: { (_: Int, _: Int) async throws -> ExploreResponse in .mockExploreResponse }
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
    } else {
    }


    return headers
}

// MARK: - Mock Data
extension Product {
    static let mock = Product(
        id: "mock_product_id_123",
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
        risk_summary: RiskSummary(grade: "C", color: "Yellow", score: nil),
        ingredients_assessment: IngredientsAssessment(
            highRisk: [
                IngredientRisk(name: "Preservatives", risk: "Contains high-risk preservatives requiring caution. May cause allergic reactions in sensitive individuals.", overview: "Preservatives are chemical compounds added to foods to prevent spoilage and extend shelf life. While they serve an important function in food safety, some preservatives have been linked to adverse health effects including allergic reactions, hyperactivity in children, and potential carcinogenic properties with long-term exposure.", riskLevel: "high", citationIds: [])
            ],
            moderateRisk: [
                IngredientRisk(name: "Salt", risk: "Moderate sodium content. Consider portion control for heart health.", overview: "Salt (sodium chloride) is an essential mineral used for flavor enhancement and preservation. While necessary for bodily functions, excessive intake is linked to high blood pressure, heart disease, and stroke. The American Heart Association recommends limiting sodium intake to 2,300mg per day.", riskLevel: "moderate", citationIds: []),
                IngredientRisk(name: "Natural Flavors", risk: "Added flavoring that may contain allergens. Generally safe for most people.", overview: "Natural flavors are derived from plant or animal sources and used to enhance taste. While generally recognized as safe, they can contain undisclosed ingredients and may trigger allergic reactions in sensitive individuals. The exact composition is often proprietary.", riskLevel: "moderate", citationIds: [])
            ],
            lowRisk: [
                IngredientRisk(name: "Turkey", risk: "High-quality lean protein source with essential amino acids.", overview: "", riskLevel: "low", citationIds: []),
                IngredientRisk(name: "Water", risk: "Used for processing. Safe and necessary for food preparation.", overview: "", riskLevel: "low", citationIds: [])
            ]
        ),
        nutrition_insights: [
            NutritionInsight(
                nutrient: "Protein",
                amount: "22g",
                eval: "excellent",
                comment: "Great source of lean protein",
                dailyValue: "44%",
                recommendation: "Great source of lean protein",
                aiCommentary: "Excellent protein source providing essential amino acids"
            ),
            NutritionInsight(
                nutrient: "Calories",
                amount: "120",
                eval: "good",
                comment: "Low calorie option for weight management",
                dailyValue: "6%",
                recommendation: "Low calorie option for weight management",
                aiCommentary: "Low calorie content supports weight management goals"
            ),
            NutritionInsight(
                nutrient: "Fat",
                amount: "8g",
                eval: "moderate",
                comment: "Moderate fat content",
                dailyValue: "12%",
                recommendation: "Moderate fat content",
                aiCommentary: "Moderate fat levels within healthy dietary guidelines"
            ),
            NutritionInsight(
                nutrient: "Sodium",
                amount: "380mg",
                eval: "high",
                comment: "Higher sodium content - monitor intake",
                dailyValue: "16%",
                recommendation: "Higher sodium content - monitor intake",
                aiCommentary: "Higher sodium content requires moderation for heart health"
            )
        ],
        citations: [], // Only real citations from backend API - no mock data for App Store compliance
        metadata: ResponseMetadata(
            product: "Mock Ground Turkey",
            generated: "2024-01-15T10:30:00Z"
        ),
        grade: "C",
        color: "Yellow",
        nutrition: nil,
        product_info: nil,
        high_risk: [
            IngredientRisk(name: "Preservatives", risk: "Contains high-risk preservatives requiring caution. May cause allergic reactions in sensitive individuals.", overview: nil, riskLevel: "high", citationIds: [])
        ],
        moderate_risk: [
            IngredientRisk(name: "Salt", risk: "Moderate sodium content. Consider portion control for heart health.", overview: "", riskLevel: "moderate", citationIds: []),
            IngredientRisk(name: "Natural Flavors", risk: "Added flavoring that may contain allergens. Generally safe for most people.", overview: "", riskLevel: "moderate", citationIds: [])
        ],
        low_risk: [
            IngredientRisk(name: "Turkey", risk: "High-quality lean protein source with essential amino acids.", overview: "", riskLevel: "low", citationIds: []),
            IngredientRisk(name: "Water", risk: "Used for processing. Safe and necessary for food preparation.", overview: "", riskLevel: "low", citationIds: [])
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
