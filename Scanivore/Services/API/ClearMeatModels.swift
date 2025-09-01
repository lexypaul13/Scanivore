//
//  ClearMeatModels.swift
//  Scanivore
//
//  API response models for Clear-Meat health assessment service
//

import Foundation

// MARK: - Authentication Models
public struct AuthRequest: Codable, Equatable {
    let email: String
    let password: String
    let fullName: String?
    
    enum CodingKeys: String, CodingKey {
        case email, password
        case fullName = "full_name"
    }
}

public struct AuthResponse: Codable, Equatable {
    let accessToken: String
    let tokenType: String
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case message
    }
}

// MARK: - Product Models
public struct Product: Codable, Equatable {
    let code: String?
    let name: String?
    let brand: String?
    let categories: [String]?
    let ingredients: [String]?
    let nutritionFacts: NutritionFacts?
    let image_url: String?
    let image_data: String?
    let risk_rating: String?
    
    // Additional fields from NLP search response
    let description: String?
    let ingredients_text: String?
    let calories: Double?
    let protein: Double?
    let fat: Double?
    let carbohydrates: Double?
    let salt: Double?
    let meat_type: String?
    let contains_nitrites: Bool?
    let contains_phosphates: Bool?
    let contains_preservatives: Bool?
    let antibiotic_free: Bool?
    let hormone_free: Bool?
    let pasture_raised: Bool?
    let last_updated: String?
    let created_at: String?
    let _relevance_score: Double?
    
    enum CodingKeys: String, CodingKey {
        case code, name, brand, categories, ingredients
        case nutritionFacts = "nutrition_facts"
        case image_url, image_data, risk_rating
        case description, ingredients_text, calories, protein, fat, carbohydrates, salt, meat_type
        case contains_nitrites, contains_phosphates, contains_preservatives
        case antibiotic_free, hormone_free, pasture_raised
        case last_updated, created_at, _relevance_score
    }
}

public struct NutritionFacts: Codable, Equatable {
    let servingSize: String?
    let calories: Double?
    let totalFat: Double?
    let saturatedFat: Double?
    let transFat: Double?
    let cholesterol: Double?
    let sodium: Double?
    let totalCarbs: Double?
    let fiber: Double?
    let sugars: Double?
    let protein: Double?
    
    enum CodingKeys: String, CodingKey {
        case servingSize = "serving_size"
        case calories
        case totalFat = "total_fat"
        case saturatedFat = "saturated_fat"
        case transFat = "trans_fat"
        case cholesterol, sodium
        case totalCarbs = "total_carbs"
        case fiber, sugars, protein
    }
}

// MARK: - Search Models
public struct SearchResponse: Codable, Equatable {
    let query: String
    let totalResults: Int
    let limit: Int
    let skip: Int
    let products: [Product]
    
    enum CodingKeys: String, CodingKey {
        case query
        case totalResults = "total_results"
        case limit, skip, products
    }
}


// MARK: - Product Info Model
public struct ProductInfo: Codable, Equatable {
    let name: String?
    let brand: String?
    let image_url: String?
    let code: String?
}

// MARK: - Health Assessment Models  
public struct HealthAssessmentResponse: Codable, Equatable {
    let summary: String
    let grade: String?
    let color: String?
    let ingredientsAssessment: IngredientsAssessment?
    let nutrition: [NutritionInsight]?
    let citations: [Citation]?
    let meta: ResponseMetadata?
    let product_info: ProductInfo?
    
    // Direct API fields to match actual response structure
    let high_risk: [IngredientRisk]?
    let moderate_risk: [IngredientRisk]?
    let low_risk: [IngredientRisk]?
    
    // Computed properties for backward compatibility
    var riskSummary: RiskSummary? {
        return RiskSummary(grade: grade, color: color, score: nil)
    }
    
    var highRisk: [IngredientRisk]? {
        return ingredientsAssessment?.highRisk
    }
    
    var moderateRisk: [IngredientRisk]? {
        return ingredientsAssessment?.moderateRisk
    }
    
    var lowRisk: [IngredientRisk]? {
        return ingredientsAssessment?.lowRisk
    }
    
    var nutritionInsights: [NutritionInsight]? {
        return nutrition
    }
    
    var lastUpdated: String? {
        return meta?.generated
    }
    
    enum CodingKeys: String, CodingKey {
        case summary
        case grade
        case color
        case ingredientsAssessment = "ingredients_assessment"
        case nutrition = "nutrition"
        case citations
        case meta = "metadata"
        case product_info = "product_info"
        
        // Direct API fields
        case high_risk = "high_risk"
        case moderate_risk = "moderate_risk" 
        case low_risk = "low_risk"
    }
}

public struct ResponseMetadata: Codable, Equatable {
    let product: String?
    let generated: String?
    
    enum CodingKeys: String, CodingKey {
        case product = "product_name"
        case generated = "generated_at"
    }
}

public struct RiskSummary: Codable, Equatable {
    let grade: String?
    let color: String?
    let score: Double?
}

public struct IngredientsAssessment: Codable, Equatable {
    let highRisk: [IngredientRisk]?
    let moderateRisk: [IngredientRisk]?
    let lowRisk: [IngredientRisk]?
    
    enum CodingKeys: String, CodingKey {
        case highRisk = "high_risk"
        case moderateRisk = "moderate_risk"
        case lowRisk = "low_risk"
    }
}

public struct IngredientRisk: Codable, Equatable {
    let name: String
    let risk: String?  // Made optional to handle missing field
    let overview: String?
    let riskLevel: String?
    let citations: [Citation]?  // Ingredient-specific citations
    
    // Computed property for backward compatibility with default value
    var microReport: String {
        return risk ?? "Generally recognized as safe for consumption"
    }
    
    // Computed property to always provide a risk description
    var riskDescription: String {
        return risk ?? overview ?? "Generally recognized as safe for consumption"
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case risk = "risk"
        case overview = "overview"
        case riskLevel = "risk_level"
        case citations = "citations"
    }
}

public struct NutritionInsight: Codable, Equatable {
    let nutrient: String
    let amount: String
    let eval: String
    let comment: String?
    let dailyValue: String?
    let recommendation: String?
    
    // Computed properties for backward compatibility
    var amountPerServing: String {
        return amount
    }
    
    var evaluation: String {
        return eval
    }
    
    enum CodingKeys: String, CodingKey {
        case nutrient
        case amount = "amount"
        case eval = "eval"
        case comment = "comment"
        case dailyValue = "daily_value"
        case recommendation
    }
}

public struct Citation: Codable, Equatable {
    let id: Int
    let title: String
    let source: String
    let year: String
    let url: String?  // Optional URL for clickable citations
}

// MARK: - Individual Ingredient Analysis Models
public struct IndividualIngredientAnalysisRequest: Codable, Equatable {
    let ingredientName: String
    let context: String?  // Optional context from product (e.g., "in ground turkey")
    
    enum CodingKeys: String, CodingKey {
        case ingredientName = "ingredient_name"
        case context
    }
}

public struct IndividualIngredientAnalysisResponse: Codable, Equatable {
    let ingredientName: String
    let analysisText: String
    let riskLevel: String
    let riskScore: Double
    let healthEffects: [HealthEffect]?
    let recommendedIntake: String?
    let alternatives: [String]?
    let citations: [Citation]
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case ingredientName = "ingredient_name"
        case analysisText = "analysis_text"
        case riskLevel = "risk_level"
        case riskScore = "risk_score"
        case healthEffects = "health_effects"
        case recommendedIntake = "recommended_intake"
        case alternatives
        case citations
        case lastUpdated = "last_updated"
    }
}

public struct HealthEffect: Codable, Equatable {
    let category: String
    let effect: String
    let severity: String
    let evidenceLevel: String
    
    enum CodingKeys: String, CodingKey {
        case category
        case effect
        case severity
        case evidenceLevel = "evidence_level"
    }
}

// MARK: - User Models
public struct User: Codable, Equatable {
    let id: String
    let email: String
    let fullName: String?
    let isActive: Bool
    let preferences: UserPreferences?
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case fullName = "full_name"
        case isActive = "is_active"
        case preferences
    }
}

public struct UserPreferences: Codable, Equatable {
    let nutritionFocus: String?
    let avoidPreservatives: Bool?
    let meatPreferences: [String]?
    
    // New onboarding fields (May 2024)
    let prefer_no_preservatives: Bool?
    let prefer_antibiotic_free: Bool?
    let prefer_organic_or_grass_fed: Bool?
    let prefer_no_added_sugars: Bool?
    let prefer_no_flavor_enhancers: Bool?
    let prefer_reduced_sodium: Bool?
    let preferred_meat_types: [String]?
    
    enum CodingKeys: String, CodingKey {
        case nutritionFocus = "nutrition_focus"
        case avoidPreservatives = "avoid_preservatives"
        case meatPreferences = "meat_preferences"
        case prefer_no_preservatives
        case prefer_antibiotic_free
        case prefer_organic_or_grass_fed
        case prefer_no_added_sugars
        case prefer_no_flavor_enhancers
        case prefer_reduced_sodium
        case preferred_meat_types
    }
    
    public init(
        nutritionFocus: String? = nil,
        avoidPreservatives: Bool? = nil,
        meatPreferences: [String]? = nil,
        prefer_no_preservatives: Bool? = nil,
        prefer_antibiotic_free: Bool? = nil,
        prefer_organic_or_grass_fed: Bool? = nil,
        prefer_no_added_sugars: Bool? = nil,
        prefer_no_flavor_enhancers: Bool? = nil,
        prefer_reduced_sodium: Bool? = nil,
        preferred_meat_types: [String]? = nil
    ) {
        self.nutritionFocus = nutritionFocus
        self.avoidPreservatives = avoidPreservatives
        self.meatPreferences = meatPreferences
        self.prefer_no_preservatives = prefer_no_preservatives
        self.prefer_antibiotic_free = prefer_antibiotic_free
        self.prefer_organic_or_grass_fed = prefer_organic_or_grass_fed
        self.prefer_no_added_sugars = prefer_no_added_sugars
        self.prefer_no_flavor_enhancers = prefer_no_flavor_enhancers
        self.prefer_reduced_sodium = prefer_reduced_sodium
        self.preferred_meat_types = preferred_meat_types
    }
}

// MARK: - API Error Models
public struct APIError: Codable, Equatable, Error {
    let detail: String
    let statusCode: Int?
    
    public init(detail: String, statusCode: Int? = nil) {
        self.detail = detail
        self.statusCode = statusCode
    }
}

// MARK: - Explore/Recommendations Models

// Backend response format (products directly)
public struct UserExploreResponse: Codable, Equatable {
    let recommendations: [Product]
    let totalMatches: Int
    let hasMore: Bool?
    let offset: Int?
    let limit: Int?
    
    enum CodingKeys: String, CodingKey {
        case recommendations
        case totalMatches = "totalMatches"
        case hasMore
        case offset
        case limit
    }
}

// App internal format (with RecommendationItems)
public struct ExploreResponse: Codable, Equatable {
    let recommendations: [RecommendationItem]
    let totalMatches: Int
    let hasMore: Bool?
    let offset: Int?
    let limit: Int?
    
    enum CodingKeys: String, CodingKey {
        case recommendations
        case totalMatches = "totalMatches"
        case hasMore
        case offset
        case limit
    }
}

public struct RecommendationItem: Codable, Equatable {
    let product: Product
    let matchDetails: MatchDetails
    let matchScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case product
        case matchDetails = "match_details"
        case matchScore = "match_score"
    }
}

public struct MatchDetails: Codable, Equatable {
    let matches: [String]
    let concerns: [String]
}

// MARK: - Model Extensions for App Integration
public extension HealthAssessmentResponse {
    /// Convert API response to app's MeatScan model
    func toMeatScan(barcode: String) -> MeatScan {
        let meatType = determineMeatType(from: summary)
        let grade = riskSummary?.grade ?? "C"
        let quality = QualityRating(
            score: riskSummary?.score ?? gradeToScore(grade),
            grade: grade
        )
        let freshness = determineFreshness(from: grade)
        let nutrition = extractNutritionInfo()
        let warnings = extractWarnings()
        let recommendations = extractRecommendations()
        
        return MeatScan(
            date: Date(),
            image: barcode, // Using barcode as image identifier
            meatType: meatType,
            quality: quality,
            freshness: freshness,
            nutritionInfo: nutrition,
            warnings: warnings,
            recommendations: recommendations
        )
    }
    
    private func determineMeatType(from summary: String) -> MeatType {
        let lowercased = summary.lowercased()
        if lowercased.contains("beef") || lowercased.contains("steak") {
            return .beef
        } else if lowercased.contains("pork") || lowercased.contains("bacon") {
            return .pork
        } else if lowercased.contains("chicken") || lowercased.contains("poultry") {
            return .chicken
        } else if lowercased.contains("lamb") {
            return .lamb
        } else if lowercased.contains("fish") || lowercased.contains("salmon") {
            return .fish
        } else if lowercased.contains("turkey") {
            return .turkey
        }
        return .unknown
    }
    
    private func gradeToScore(_ grade: String) -> Double {
        switch grade.uppercased() {
        case "A+", "A": return 90
        case "B+", "B": return 75
        case "C+", "C": return 60
        case "D+", "D": return 45
        default: return 30
        }
    }
    
    private func determineFreshness(from grade: String) -> FreshnessLevel {
        switch grade.uppercased() {
        case "A+", "A": return .fresh
        case "B+", "B": return .good
        case "C+", "C": return .acceptable
        case "D+", "D": return .caution
        default: return .expired
        }
    }
    
    private func extractNutritionInfo() -> NutritionInfo {
        var calories = 0
        var protein = 0.0
        var fat = 0.0
        var saturatedFat = 0.0
        var cholesterol = 0
        var sodium = 0
        
        if let insights = nutritionInsights {
            for insight in insights {
                let amount = extractNumericValue(from: insight.amountPerServing)
                
                switch insight.nutrient.lowercased() {
                case "calories", "energy":
                    calories = Int(amount)
                case "protein":
                    protein = amount
                case "total fat", "fat":
                    fat = amount
                case "saturated fat":
                    saturatedFat = amount
                case "cholesterol":
                    cholesterol = Int(amount)
                case "sodium", "salt":
                    sodium = Int(amount)
                default:
                    break
                }
            }
        }
        
        return NutritionInfo(
            calories: calories,
            protein: protein,
            fat: fat,
            saturatedFat: saturatedFat,
            cholesterol: cholesterol,
            sodium: sodium
        )
    }
    
    private func extractNumericValue(from text: String) -> Double {
        let pattern = #"(\d+(?:\.\d+)?)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return Double(text[range]) ?? 0.0
        }
        return 0.0
    }
    
    private func extractWarnings() -> [String] {
        var warnings: [String] = []
        
        if let ingredientsAssessment = ingredientsAssessment {
            // Add warnings from high-risk ingredients
            if let highRisk = ingredientsAssessment.highRisk {
                for ingredient in highRisk {
                    warnings.append("⚠️ \(ingredient.name): \(ingredient.microReport)")
                }
            }
            
            // Add warnings from moderate-risk ingredients if there are many
            if let moderateRisk = ingredientsAssessment.moderateRisk, moderateRisk.count > 3 {
                warnings.append("⚠️ Contains multiple ingredients requiring attention")
            }
        }
        
        return warnings
    }
    
    private func extractRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Add recommendation from summary
        recommendations.append(summary)
        
        // Add specific nutrition recommendations
        if let insights = nutritionInsights {
            for insight in insights.prefix(2) {
                if let recommendation = insight.recommendation {
                    recommendations.append("💡 \(recommendation)")
                }
            }
        }
        
        return recommendations
    }
    
    /// Convert HealthAssessmentResponse to SavedProduct for history persistence
    func toSavedProduct(barcode: String) -> SavedProduct {
        let productName = product_info?.name ?? "Unknown Product"
        let productBrand = product_info?.brand
        let productImageUrl = product_info?.image_url
        let meatScan = toMeatScan(barcode: barcode)
        
        return SavedProduct(
            id: barcode,
            productName: productName,
            productBrand: productBrand,
            productImageUrl: productImageUrl,
            scanDate: Date(),
            meatScan: meatScan,
            healthAssessment: self, // Store full assessment for offline viewing
            version: 2
        )
    }
}

// MARK: - Individual Ingredient Analysis Mock Extensions
extension IndividualIngredientAnalysisResponse {
    static func mockIndividualAnalysis(for ingredientName: String) -> IndividualIngredientAnalysisResponse {
        return IndividualIngredientAnalysisResponse(
            ingredientName: ingredientName,
            analysisText: "Mock analysis for \(ingredientName). This ingredient is commonly used in food processing and may have various health implications depending on the amount consumed.",
            riskLevel: "MODERATE",
            riskScore: 0.5,
            healthEffects: [
                HealthEffect(
                    category: "Digestive",
                    effect: "Potential sensitivity",
                    severity: "LOW",
                    evidenceLevel: "LIMITED"
                )
            ],
            recommendedIntake: "Moderate consumption recommended",
            alternatives: ["Natural \(ingredientName) alternative"],
            citations: [
                Citation(
                    id: 1, title: "Mock Research Study on \(ingredientName)", source: "PubMed",
                    year: "2023", url: "https://example.com/mock-study"
                )
            ],
            lastUpdated: "2024-01-01T00:00:00Z"
        )
    }
}
