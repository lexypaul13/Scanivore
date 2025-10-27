
import Foundation
import ComposableArchitecture

@Reducer
public struct DisclaimerFeature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case contactEmailTapped
        
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
                
            case .contactEmailTapped:
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
