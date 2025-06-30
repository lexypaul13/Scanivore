//
//  OnboardingPreferences.swift
//  Scanivore
//
//  Created for storing user onboarding preferences
//

import Foundation
import SwiftUI

struct OnboardingPreferences: Codable {
    var avoidPreservatives: Bool?
    var antibioticFree: Bool?
    var preferOrganic: Bool?
    var avoidSugars: Bool?
    var avoidMSG: Bool?
    var lowerSodium: Bool?
    var preferredMeatTypes: Set<MeatType> = []
    
    // Check if onboarding is complete
    var isComplete: Bool {
        // All questions must be answered
        return avoidPreservatives != nil &&
               antibioticFree != nil &&
               preferOrganic != nil &&
               avoidSugars != nil &&
               avoidMSG != nil &&
               lowerSodium != nil &&
               !preferredMeatTypes.isEmpty
    }
}

// Extension to make MeatType conform to Codable for storage
extension MeatType: Codable {}