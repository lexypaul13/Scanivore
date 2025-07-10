//
//  MeatScan.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import Foundation
import SwiftUI

public struct MeatScan: Identifiable, Equatable {
    public let id = UUID()
    let date: Date
    let image: String
    let meatType: MeatType
    let quality: QualityRating
    let freshness: FreshnessLevel
    let nutritionInfo: NutritionInfo
    let warnings: [String]
    let recommendations: [String]
}

public enum MeatType: String, CaseIterable, Equatable {
    case beef = "Beef"
    case pork = "Pork"
    case chicken = "Chicken"
    case lamb = "Lamb"
    case fish = "Fish"
    case turkey = "Turkey"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .beef: return "🥩"
        case .pork: return "🥓"
        case .chicken: return "🍗"
        case .lamb: return "🍖"
        case .fish: return "🐟"
        case .turkey: return "🦃"
        case .unknown: return "❓"
        }
    }
}

public struct QualityRating: Equatable {
    let score: Double // 0-100
    let grade: String // A+, A, B+, B, C
    
    var color: Color {
        switch score {
        case 90...100: return DesignSystem.Colors.success
        case 75..<90: return DesignSystem.Colors.primaryRed
        case 60..<75: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.error
        }
    }
}

public enum FreshnessLevel: String, CaseIterable, Equatable {
    case fresh = "Fresh"
    case good = "Good"
    case acceptable = "Acceptable"
    case caution = "Use Soon"
    case expired = "Expired"
    
    var color: Color {
        switch self {
        case .fresh: return DesignSystem.Colors.success
        case .good: return DesignSystem.Colors.primaryRed
        case .acceptable: return DesignSystem.Colors.warning
        case .caution: return DesignSystem.Colors.warning
        case .expired: return DesignSystem.Colors.error
        }
    }
}

public struct NutritionInfo: Equatable {
    let calories: Int
    let protein: Double
    let fat: Double
    let saturatedFat: Double
    let cholesterol: Int
    let sodium: Int
}

extension MeatScan {
    static let mockScans: [MeatScan] = [
        MeatScan(
            date: Date(),
            image: "scan1",
            meatType: .beef,
            quality: QualityRating(score: 92, grade: "A+"),
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
            recommendations: ["Perfect for grilling", "Best consumed within 3 days"]
        ),
        MeatScan(
            date: Date().addingTimeInterval(-86400),
            image: "scan2",
            meatType: .chicken,
            quality: QualityRating(score: 85, grade: "A"),
            freshness: .good,
            nutritionInfo: NutritionInfo(
                calories: 165,
                protein: 31.0,
                fat: 3.6,
                saturatedFat: 1.0,
                cholesterol: 85,
                sodium: 74
            ),
            warnings: ["Slightly elevated bacteria count"],
            recommendations: ["Cook thoroughly to 165°F", "Use within 24 hours"]
        )
    ]
}
