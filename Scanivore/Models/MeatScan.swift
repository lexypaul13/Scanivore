//
//  MeatScan.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import Foundation
import SwiftUI

struct MeatScan: Identifiable {
    let id = UUID()
    let date: Date
    let image: String
    let meatType: MeatType
    let quality: QualityRating
    let freshness: FreshnessLevel
    let nutritionInfo: NutritionInfo
    let warnings: [String]
    let recommendations: [String]
}

enum MeatType: String, CaseIterable {
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

struct QualityRating {
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

enum FreshnessLevel: String, CaseIterable {
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

struct NutritionInfo {
    let calories: Int
    let protein: Double
    let fat: Double
    let saturatedFat: Double
    let cholesterol: Int
    let sodium: Int
}

extension MeatScan {
    static let mockScans: [MeatScan] = []
}