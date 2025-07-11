//
//  ClearMeatModels.swift
//  Scanivore
//
//  API response models for Clear-Meat health assessment service
//

import Foundation

// MARK: - Authentication Models
public struct AuthRequest: Codable {
    let email: String
    let password: String
    let fullName: String?
    
    enum CodingKeys: String, CodingKey {
        case email, password
        case fullName = "full_name"
    }
}

public struct AuthResponse: Codable {
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
public struct Product: Codable {
    let code: String
    let name: String?
    let brand: String?
    let categories: [String]?
    let ingredients: [String]?
    let nutritionFacts: NutritionFacts?
    let image_url: String?
    let image_data: String?
    let risk_rating: String?
    
    enum CodingKeys: String, CodingKey {
        case code, name, brand, categories, ingredients
        case nutritionFacts = "nutrition_facts"
        case image_url, image_data, risk_rating
    }
}

public struct NutritionFacts: Codable {
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

// MARK: - Health Assessment Models
public struct HealthAssessmentResponse: Codable {
    let summary: String
    let riskSummary: RiskSummary
    let ingredientsAssessment: IngredientsAssessment
    let nutritionInsights: [NutritionInsight]
    let citations: [Citation]
    let lastUpdated: String?
    
    enum CodingKeys: String, CodingKey {
        case summary
        case riskSummary = "risk_summary"
        case ingredientsAssessment = "ingredients_assessment"
        case nutritionInsights = "nutrition_insights"
        case citations
        case lastUpdated = "last_updated"
    }
}

public struct RiskSummary: Codable {
    let grade: String
    let color: String
    let score: Double?
}

public struct IngredientsAssessment: Codable {
    let highRisk: [IngredientRisk]
    let moderateRisk: [IngredientRisk]
    let lowRisk: [IngredientRisk]?
    
    enum CodingKeys: String, CodingKey {
        case highRisk = "high_risk"
        case moderateRisk = "moderate_risk"
        case lowRisk = "low_risk"
    }
}

public struct IngredientRisk: Codable {
    let name: String
    let microReport: String
    let riskLevel: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case microReport = "micro_report"
        case riskLevel = "risk_level"
    }
}

public struct NutritionInsight: Codable {
    let nutrient: String
    let amountPerServing: String
    let evaluation: String
    let dailyValue: String?
    let recommendation: String?
    
    enum CodingKeys: String, CodingKey {
        case nutrient
        case amountPerServing = "amount_per_serving"
        case evaluation
        case dailyValue = "daily_value"
        case recommendation
    }
}

public struct Citation: Codable {
    let id: Int
    let title: String
    let authors: String?
    let journal: String?
    let year: Int?
    let doi: String?
    let url: String?
}

// MARK: - User Models
public struct User: Codable {
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

public struct UserPreferences: Codable {
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
public struct APIError: Codable, Error {
    let detail: String
    let statusCode: Int?
    
    public init(detail: String, statusCode: Int? = nil) {
        self.detail = detail
        self.statusCode = statusCode
    }
}

// MARK: - Explore/Recommendations Models
public struct ExploreResponse: Codable {
    let recommendations: [RecommendationItem]
    let totalMatches: Int
    
    enum CodingKeys: String, CodingKey {
        case recommendations
        case totalMatches = "total_matches"
    }
}

public struct RecommendationItem: Codable {
    let product: Product
    let matchDetails: MatchDetails
    let matchScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case product
        case matchDetails = "match_details"
        case matchScore = "match_score"
    }
}

public struct MatchDetails: Codable {
    let matches: [String]
    let concerns: [String]
}

// MARK: - Model Extensions for App Integration
public extension HealthAssessmentResponse {
    /// Convert API response to app's MeatScan model
    func toMeatScan(barcode: String) -> MeatScan {
        let meatType = determineMeatType(from: summary)
        let quality = QualityRating(
            score: riskSummary.score ?? gradeToScore(riskSummary.grade),
            grade: riskSummary.grade
        )
        let freshness = determineFreshness(from: riskSummary.grade)
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
        
        for insight in nutritionInsights {
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
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            let range = Range(match.range(at: 1), in: text)!
            return Double(text[range]) ?? 0.0
        }
        return 0.0
    }
    
    private func extractWarnings() -> [String] {
        var warnings: [String] = []
        
        // Add warnings from high-risk ingredients
        for ingredient in ingredientsAssessment.highRisk {
            warnings.append("⚠️ \(ingredient.name): \(ingredient.microReport)")
        }
        
        // Add warnings from moderate-risk ingredients if there are many
        if ingredientsAssessment.moderateRisk.count > 3 {
            warnings.append("⚠️ Contains multiple ingredients requiring attention")
        }
        
        return warnings
    }
    
    private func extractRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Add recommendation from summary
        recommendations.append(summary)
        
        // Add specific nutrition recommendations
        for insight in nutritionInsights.prefix(2) {
            if let recommendation = insight.recommendation {
                recommendations.append("💡 \(recommendation)")
            }
        }
        
        return recommendations
    }
}