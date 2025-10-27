
import Foundation
import ComposableArchitecture

@Reducer
public struct PrivacyFeature {
    @ObservableState
    public struct State: Equatable {
        public var lastUpdated: String = "June 28, 2025"
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        
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
