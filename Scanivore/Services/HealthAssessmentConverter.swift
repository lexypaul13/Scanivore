//
//  HealthAssessmentConverter.swift
//  Scanivore
//
//  Optimized utility for converting health assessment data to MeatScan format for automatic scan history
//

import Foundation
import SwiftUI

struct HealthAssessmentConverter {
    
    /// Converts a health assessment response to a MeatScan for scan history
    static func convertToMeatScan(
        assessment: HealthAssessmentResponse,
        productName: String?,
        productBrand: String?
    ) -> MeatScan {
        return MeatScan(
            date: Date(),
            image: "", // No image data from health assessment
            meatType: extractMeatType(from: productName, brand: productBrand),
            quality: extractQualityRating(from: assessment),
            freshness: extractFreshnessLevel(from: assessment),
            nutritionInfo: extractNutritionInfo(from: assessment),
            warnings: extractWarnings(from: assessment),
            recommendations: extractRecommendations(from: assessment)
        )
    }
    
    /// Converts a basic product with minimal data to MeatScan (fallback)
    static func convertBasicProductToMeatScan(
        productCode: String,
        productName: String?,
        productBrand: String?,
        originalRiskRating: String?
    ) -> MeatScan {
        return MeatScan(
            date: Date(),
            image: "",
            meatType: extractMeatType(from: productName, brand: productBrand),
            quality: extractQualityFromRiskRating(originalRiskRating),
            freshness: .good, // Default for basic products
            nutritionInfo: defaultNutritionInfo(),
            warnings: [],
            recommendations: ["Scan saved with limited data", "Try scanning again for full analysis"]
        )
    }
    
    // MARK: - Private Conversion Helpers
    
    private static func extractMeatType(from productName: String?, brand: String?) -> MeatType {
        let combined = [(productName ?? ""), (brand ?? "")].joined(separator: " ").lowercased()
        
        if combined.contains("chicken") || combined.contains("poultry") {
            return .chicken
        } else if combined.contains("beef") || combined.contains("steak") || combined.contains("ground beef") {
            return .beef
        } else if combined.contains("pork") || combined.contains("bacon") || combined.contains("ham") {
            return .pork
        } else if combined.contains("turkey") {
            return .turkey
        } else if combined.contains("lamb") {
            return .lamb
        } else if combined.contains("fish") || combined.contains("salmon") || combined.contains("tuna") {
            return .fish
        }
        
        return .unknown
    }
    
    private static func extractQualityRating(from assessment: HealthAssessmentResponse) -> QualityRating {
        // Try to get score from risk summary
        if let riskSummary = assessment.riskSummary,
           let score = riskSummary.score {
            return QualityRating(
                score: score,
                grade: scoreToGrade(score)
            )
        }
        
        // Fallback to grade analysis
        let grade = assessment.grade ?? "C"
        let score = gradeToScore(grade)
        
        return QualityRating(score: score, grade: grade)
    }
    
    private static func extractQualityFromRiskRating(_ riskRating: String?) -> QualityRating {
        guard let rating = riskRating?.lowercased() else {
            return QualityRating(score: 70.0, grade: "C")
        }
        
        switch rating {
        case "green":
            return QualityRating(score: 90.0, grade: "A")
        case "yellow":
            return QualityRating(score: 75.0, grade: "C")
        case "orange":
            return QualityRating(score: 60.0, grade: "D")
        case "red":
            return QualityRating(score: 40.0, grade: "F")
        default:
            return QualityRating(score: 70.0, grade: "C")
        }
    }
    
    private static func extractFreshnessLevel(from assessment: HealthAssessmentResponse) -> FreshnessLevel {
        let summary = assessment.summary.lowercased()
        
        if summary.contains("fresh") || summary.contains("excellent") {
            return .fresh
        } else if summary.contains("good") || summary.contains("quality") {
            return .good
        } else if summary.contains("moderate") || summary.contains("acceptable") {
            return .acceptable
        } else if summary.contains("caution") || summary.contains("warning") {
            return .caution
        } else if summary.contains("expired") || summary.contains("avoid") {
            return .expired
        }
        
        return .good // Default
    }
    
    private static func extractNutritionInfo(from assessment: HealthAssessmentResponse) -> NutritionInfo {
        // Extract nutrition from nutrition if available
        var calories = 0
        var protein = 0.0
        var fat = 0.0
        var saturatedFat = 0.0
        var cholesterol = 0
        var sodium = 0
        
        if let insights = assessment.nutrition {
            for insight in insights {
                let nutrient = insight.nutrient.lowercased()
                let amount = extractNumericValue(from: insight.amount)
                
                switch nutrient {
                case "energy", "calories":
                    calories = Int(amount)
                case "protein":
                    protein = amount
                case "fat", "total fat":
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
    
    private static func extractWarnings(from assessment: HealthAssessmentResponse) -> [String] {
        var warnings: [String] = []
        
        // Add high-risk ingredient warnings
        if let highRisk = assessment.high_risk, !highRisk.isEmpty {
            warnings.append("Contains \(highRisk.count) high-risk ingredient\(highRisk.count > 1 ? "s" : "")")
        }
        
        // Add specific warnings from moderate risk ingredients
        if let moderateRisk = assessment.moderate_risk, !moderateRisk.isEmpty {
            warnings.append("Contains \(moderateRisk.count) moderate-risk ingredient\(moderateRisk.count > 1 ? "s" : "")")
        }
        
        // Add warnings based on summary keywords
        let summary = assessment.summary.lowercased()
        if summary.contains("high sodium") || summary.contains("salt") {
            warnings.append("High sodium content")
        }
        if summary.contains("preservative") {
            warnings.append("Contains preservatives")
        }
        if summary.contains("additive") {
            warnings.append("Contains additives")
        }
        
        return warnings
    }
    
    private static func extractRecommendations(from assessment: HealthAssessmentResponse) -> [String] {
        var recommendations: [String] = []
        
        // Add grade-based recommendations
        let grade = assessment.grade ?? "C"
        switch grade.uppercased() {
        case "A", "A+":
            recommendations.append("Excellent choice for a healthy diet")
        case "B", "B+":
            recommendations.append("Good option with minor considerations")
        case "C", "C+":
            recommendations.append("Consume in moderation")
        case "D", "F":
            recommendations.append("Consider healthier alternatives")
        default:
            break
        }
        
        // Add specific recommendations based on ingredients
        if let lowRisk = assessment.low_risk, !lowRisk.isEmpty {
            recommendations.append("Good source of quality ingredients")
        }
        
        // Add cooking recommendations based on meat type
        let summary = assessment.summary.lowercased()
        if summary.contains("chicken") || summary.contains("poultry") {
            recommendations.append("Cook thoroughly to 165°F (74°C)")
        } else if summary.contains("beef") || summary.contains("pork") {
            recommendations.append("Cook to safe internal temperature")
        }
        
        return recommendations.isEmpty ? ["Product analyzed successfully"] : recommendations
    }
    
    // MARK: - Helper Functions
    
    private static func scoreToGrade(_ score: Double) -> String {
        switch score {
        case 90...100: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "F"
        }
    }
    
    private static func gradeToScore(_ grade: String) -> Double {
        switch grade.uppercased() {
        case "A", "A+": return 95.0
        case "B", "B+": return 85.0
        case "C", "C+": return 75.0
        case "D", "D+": return 65.0
        case "F": return 45.0
        default: return 70.0
        }
    }
    
    private static func extractNumericValue(from text: String) -> Double {
        // Optimized regex for extracting numbers from nutrition strings
        guard let regex = try? NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)"#),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return 0.0
        }
        
        return Double(text[range]) ?? 0.0
    }
    
    private static func defaultNutritionInfo() -> NutritionInfo {
        return NutritionInfo(
            calories: 0,
            protein: 0.0,
            fat: 0.0,
            saturatedFat: 0.0,
            cholesterol: 0,
            sodium: 0
        )
    }
}