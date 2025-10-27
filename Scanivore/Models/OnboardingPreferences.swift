//
//  OnboardingPreferences.swift
//  Scanivore
//
//  Created for storing user onboarding preferences
//

import Foundation
import SwiftUI

public struct OnboardingPreferences: Codable, Equatable {
    public var avoidPreservatives: Bool?
    public var antibioticFree: Bool?
    public var preferOrganic: Bool?
    public var avoidSugars: Bool?
    public var avoidMSG: Bool?
    public var lowerSodium: Bool?
    public var preferredMeatTypes: Set<MeatType> = []
    
    public init(
        avoidPreservatives: Bool? = nil,
        antibioticFree: Bool? = nil,
        preferOrganic: Bool? = nil,
        avoidSugars: Bool? = nil,
        avoidMSG: Bool? = nil,
        lowerSodium: Bool? = nil,
        preferredMeatTypes: Set<MeatType> = []
    ) {
        self.avoidPreservatives = avoidPreservatives
        self.antibioticFree = antibioticFree
        self.preferOrganic = preferOrganic
        self.avoidSugars = avoidSugars
        self.avoidMSG = avoidMSG
        self.lowerSodium = lowerSodium
        self.preferredMeatTypes = preferredMeatTypes
    }
    
     public var isComplete: Bool {
         return avoidPreservatives != nil &&
               antibioticFree != nil &&
               preferOrganic != nil &&
               avoidSugars != nil &&
               avoidMSG != nil &&
               lowerSodium != nil &&
               !preferredMeatTypes.isEmpty
    }
}

 
