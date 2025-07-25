//
//  ProductRecommendation.swift
//  Scanivore
//
//  Model for product recommendations in the Explore feature
//

import Foundation

struct ProductRecommendation: Identifiable, Equatable {
    let id: String
    let name: String
    let brand: String
    let imageUrl: String?
    let imageData: String?
    let meatType: MeatType
    let qualityRating: QualityLevel
    let originalRiskRating: String // Store original OpenFoodFacts risk rating
    let isRecommended: Bool
    let matchReasons: [String]
    let concerns: [String]
    
    // Convert from API model
    static func fromRecommendationItem(_ item: RecommendationItem) -> ProductRecommendation {
        let riskRating = item.product.risk_rating ?? "Green"
        
        return ProductRecommendation(
            id: item.product.code ?? "unknown",
            name: item.product.name ?? "Unknown Product",
            brand: item.product.brand ?? "Unknown Brand",
            imageUrl: item.product.image_url,
            imageData: item.product.image_data,
            meatType: determineMeatType(from: item.product),
            qualityRating: mapRiskRatingToQuality(riskRating),
            originalRiskRating: riskRating, // Store the original risk rating
            isRecommended: item.matchDetails.concerns.isEmpty,
            matchReasons: item.matchDetails.matches,
            concerns: item.matchDetails.concerns
        )
    }
    
    static func determineMeatType(from product: Product) -> MeatType {
        // First check meat_type if available (from backend classification)
        if let meatType = product.meat_type?.lowercased() {
            switch meatType {
            case "chicken": return .chicken
            case "beef": return .beef
            case "pork": return .pork
            case "turkey": return .turkey
            case "lamb": return .lamb
            case "fish": return .fish
            default: break
            }
        }
        
        // Fallback to name/category analysis for backward compatibility
        let name = (product.name ?? "").lowercased()
        let categories = product.categories?.joined(separator: " ").lowercased() ?? ""
        let combined = name + " " + categories
        
        if combined.contains("chicken") { return .chicken }
        if combined.contains("beef") || combined.contains("steak") { return .beef }
        if combined.contains("pork") || combined.contains("bacon") { return .pork }
        if combined.contains("turkey") { return .turkey }
        if combined.contains("lamb") { return .lamb }
        if combined.contains("fish") || combined.contains("salmon") { return .fish }
        
        return .beef // Default
    }
    
    static func mapRiskRatingToQuality(_ rating: String) -> QualityLevel {
        switch rating.lowercased() {
        case "green": return .excellent
        case "yellow": return .good
        case "orange": return .poor
        case "red": return .bad
        default: return .good
        }
    }
    
    // Convert from Product (for search results)
    static func fromProduct(_ product: Product) -> ProductRecommendation {
        let riskRating = product.risk_rating ?? "Green"
        
        // Generate match reasons based on available data
        var matchReasons: [String] = []
        
        // Simple search result
        matchReasons.append("Search result")
        
        // Add nutrition-based reasons
        if let protein = product.protein, protein > 20 {
            matchReasons.append("High protein content")
        }
        
        if let salt = product.salt, salt < 0.5 {
            matchReasons.append("Low sodium")
        }
        
        // Add quality-based reasons from ingredient flags
        if product.antibiotic_free == true {
            matchReasons.append("Antibiotic-free")
        }
        
        if product.contains_preservatives == false {
            matchReasons.append("No preservatives")
        }
        
        return ProductRecommendation(
            id: product.code ?? "unknown",
            name: product.name ?? "Unknown Product",
            brand: product.brand ?? "Unknown Brand",
            imageUrl: product.image_url,
            imageData: product.image_data,
            meatType: determineMeatType(from: product),
            qualityRating: mapRiskRatingToQuality(riskRating),
            originalRiskRating: riskRating,
            isRecommended: true,
            matchReasons: matchReasons,
            concerns: []
        )
    }
}

enum QualityLevel: Equatable {
    case excellent
    case good
    case poor
    case bad
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Fair"
        case .poor: return "Fair"
        case .bad: return "Bad"
        }
    }
    
    var sortValue: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .poor: return 2
        case .bad: return 1
        }
    }
}