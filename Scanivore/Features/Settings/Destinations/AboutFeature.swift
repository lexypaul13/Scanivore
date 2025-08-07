//
//  AboutFeature.swift
//  Scanivore
//
//  About feature for app information and credits
//

import Foundation
import ComposableArchitecture

@Reducer
public struct AboutFeature {
    @ObservableState
    public struct State: Equatable {
        public var appVersion: String = "1.0.0"
        public var buildNumber: String = "1"
        public var copyright: String = "© 2025 Scanivore Inc."
        
        public init() {
            // Get actual version info from bundle if available
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                self.appVersion = version
            }
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                self.buildNumber = build
            }
        }
    }
    
    public enum Action: Equatable {
        case onAppear
        case termsOfServiceTapped
        case privacyPolicyTapped
        case acknowledgmentsTapped
        
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
                
            case .termsOfServiceTapped:
                // External link - handled by Link view
                return .none
                
            case .privacyPolicyTapped:
                // External link - handled by Link view
                return .none
                
            case .acknowledgmentsTapped:
                // External link - handled by Link view
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}