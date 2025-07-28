//
//  PrivacyFeature.swift
//  Scanivore
//
//  Privacy policy feature for data usage information
//

import Foundation
import ComposableArchitecture

@Reducer
public struct PrivacyFeature {
    @ObservableState
    public struct State: Equatable {
        public var lastUpdated: String = "June 28, 2025"
        
        public init() {}
    }
    
    public enum Action: Sendable {
        case onAppear
        
        // Internal actions
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case dismiss
        }
    }
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}