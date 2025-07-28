//
//  SafetyGrade.swift
//  Scanivore
//
//  Safety grade enum for product filtering and display
//

import Foundation

public enum SafetyGrade: String, CaseIterable, Equatable {
    case excellent = "Excellent"
    case fair = "Fair"
    case bad = "Bad"
}