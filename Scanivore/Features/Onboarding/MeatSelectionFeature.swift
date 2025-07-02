//
//  MeatSelectionFeature.swift
//  Scanivore
//
//  TCA feature for meat type selection in onboarding
//

import Foundation
import ComposableArchitecture

// MARK: - MeatSelection Feature
@Reducer
struct MeatSelectionFeature {
    @ObservableState
    struct State: Equatable {
        var selectedTypes: Set<MeatType> = []
        
        var canContinue: Bool {
            !selectedTypes.isEmpty
        }
    }
    
    enum Action {
        case meatTypeToggled(MeatType)
        case continueButtonTapped
        case delegate(Delegate)
        
        enum Delegate {
            case meatSelectionCompleted(Set<MeatType>)
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .meatTypeToggled(meatType):
                if state.selectedTypes.contains(meatType) {
                    state.selectedTypes.remove(meatType)
                } else {
                    state.selectedTypes.insert(meatType)
                }
                return .none
                
            case .continueButtonTapped:
                guard state.canContinue else { return .none }
                return .run { [selectedTypes = state.selectedTypes] send in
                    await send(.delegate(.meatSelectionCompleted(selectedTypes)))
                }
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Available Meat Types for Selection
extension MeatSelectionFeature {
    static let availableMeatTypes: [(type: MeatType, name: String)] = [
        (.chicken, "Chicken"),
        (.turkey, "Turkey"),
        (.beef, "Beef"),
        (.lamb, "Lamb"),
        (.pork, "Pork"),
        (.fish, "Fish")
    ]
} 