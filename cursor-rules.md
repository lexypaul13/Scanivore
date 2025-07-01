# Scanivore Development Guidelines

You are an expert Swift developer specializing in The Composable Architecture (TCA). Follow these guidelines:

## TCA Architecture
- Use @Reducer macro for all feature reducers
- @ObservableState for state types with Equatable
- TaskResult pattern for async operations
- Unidirectional data flow strictly
- Single source of truth for state

## State Management
- IdentifiedArrayOf<T> for collections
- Value types (structs) only in state
- Never mutate state outside reducers
- Use @Shared for cross-feature state
- Implement proper Equatable conformance

## Actions Design
- Past tense for responses: dataLoaded, loginCompleted
- Present tense for user events: buttonTapped, textChanged
- Use TaskResult<T> for async action payloads
- Group related actions with enums
- Descriptive, event-based naming

## Dependencies
- @DependencyClient for all external services
- Provide liveValue, testValue, previewValue
- @Sendable closures for async operations
- Inject via @Dependency(\.serviceName)
- Never access dependencies directly in views

## Networking Patterns
```swift
@DependencyClient
struct APIClient: Sendable {
    var fetchItems: @Sendable (_ filters: ItemFilters) async throws -> [Item]
    var fetchDetails: @Sendable (_ id: Item.ID) async throws -> ItemDetails
    var updateItem: @Sendable (_ id: Item.ID) async throws -> Void
}

extension APIClient: DependencyKey {
    static let liveValue = APIClient(
        fetchItems: { filters in
            // Network implementation
        },
        fetchDetails: { id in
            // GraphQL or REST implementation
        },
        updateItem: { id in
            // Update implementation
        }
    )
    
    static let testValue = APIClient(
        fetchItems: { _ in [] },
        fetchDetails: { _ in .mock },
        updateItem: { _ in }
    )
}
```

## Effects & Side Effects
- Use .run for all async operations
- Wrap network calls in TaskResult
- Always handle success/failure cases
- Use .cancellable(id:) for long operations
- Return .none when no effects needed

## Error Handling
- Custom error types with LocalizedError
- Map network errors to user messages
- Handle authentication separately
- Use Result type in non-TCA contexts
- Explicit error state in reducers

## Models Structure
```swift
struct ItemDetails: Identifiable, Equatable, Sendable {
    let id: Item.ID
    let name: String
    let status: ItemStatus
    let metadata: [String: String]
    
    init(
        id: Item.ID,
        name: String,
        status: ItemStatus,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.metadata = metadata
    }
}

extension ItemDetails {
    static let mock = ItemDetails(
        id: 1,
        name: "Sample Item",
        status: .active,
        metadata: ["key": "value"]
    )
}
```

## Reducer Implementation
```swift
@Reducer
struct Feature {
    @ObservableState
    struct State: Equatable {
        var items: IdentifiedArrayOf<Item> = []
        var isLoading = false
        var error: String?
    }
    
    enum Action: Equatable {
        case loadItems
        case itemsResponse(TaskResult<[Item]>)
    }
    
    @Dependency(\.apiClient) var apiClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadItems:
                state.isLoading = true
                state.error = nil
                return .run { send in
                    await send(.itemsResponse(
                        TaskResult { try await apiClient.fetchItems() }
                    ))
                }
                
            case let .itemsResponse(.success(items)):
                state.isLoading = false
                state.items = IdentifiedArrayOf(uniqueElements: items)
                return .none
                
            case let .itemsResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
            }
        }
    }
}
```

## SwiftUI Integration
- @Bindable for store bindings (not @Perception.Bindable)
- Never access store.state directly
- Use store.send() for all actions
- Proper view composition patterns

### View Structure Pattern
Always follow this exact structure for TCA views:
```swift
struct FeatureView: View {
    public init(store: StoreOf<FeatureDomain>) {
        self.store = store
    }
    
    @Bindable var store: StoreOf<FeatureDomain>
    
    var body: some View {
        // View implementation
    }
}
```

## Testing
- TestStore for reducer testing
- Mock all dependencies
- Test success and failure paths
- Verify state changes explicitly
- Use await for async actions

## Performance
- Avoid unnecessary state updates
- Use proper Equatable implementations
- Cancel effects when appropriate
- Profile with Instruments
- Optimize large collections

## Navigation Patterns

### Stack-Based Navigation
For linear, deep navigation flows (NavigationStack):
```swift
@Reducer
public struct FlowFeature {
    @Reducer(state: .equatable)
    public enum Path {
        case stepOne(StepOneFeature)
        case stepTwo(StepTwoFeature)
        case stepThree(StepThreeFeature)
    }

    @ObservableState
    public struct State: Equatable {
        var path = StackState<Path.State>()
    }

    public enum Action: Sendable {
        case path(StackActionOf<Path>)
        case onAppear
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case didComplete
            case didCancel
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.path.append(.stepOne(.init()))
                return .none

            case let .path(.element(_, action: .stepOne(.delegate(action)))):
                switch action {
                case .didTapNext:
                    state.path.append(.stepTwo(.init()))
                    return .none
                case .didTapCancel:
                    return .send(.delegate(.didCancel))
                }

            case .path, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
```

SwiftUI Implementation:
```swift
struct FlowView: View {
    @Bindable var store: StoreOf<FlowFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            EmptyView()
        } destination: { store in
            switch store.case {
            case let .stepOne(store):
                StepOneView(store: store)
                    .navigationBarBackButtonHidden(true)
            case let .stepTwo(store):
                StepTwoView(store: store)
            case let .stepThree(store):
                StepThreeView(store: store)
            }
        }
        .onAppear { store.send(.onAppear) }
    }
}
```

### Tree-Based Navigation
For sheets, alerts, popovers, and single destinations:
```swift
@Reducer
struct ItemListFeature {
    @ObservableState
    struct State: Equatable {
        var items: IdentifiedArrayOf<Item> = []
        @Presents var destination: Destination.State?
    }

    enum Action: Equatable {
        case addItemTapped
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer(state: .equatable)
    enum Destination {
        case addItem(AddItemFeature)
        case editItem(EditItemFeature)
        case alert(AlertState<Action.Alert>)

        enum Alert: Equatable {
            case confirmDelete
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .addItemTapped:
                state.destination = .addItem(AddItemFeature.State())
                return .none

            case .destination(.presented(.addItem(.delegate(.didSave(let item))))):
                state.items.append(item)
                state.destination = nil
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
```

SwiftUI Tree-Based View:
```swift
struct ItemListView: View {
    @Bindable var store: StoreOf<ItemListFeature>

    var body: some View {
        List(store.items) { item in
            Text(item.name)
        }
        .sheet(store: store.scope(state: \.$destination.addItem, action: \.destination.addItem)) { store in
            AddItemView(store: store)
        }
        .alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
    }
}
```

## File Organization
```
Sources/
├── Models/           # Data types
├── Features/         # Feature modules
│   └── FeatureName/
│       ├── FeatureReducer.swift
│       └── FeatureView.swift
├── Dependencies/     # API clients
└── Shared/          # Utilities
```

## Security
- Never store sensitive data in state
- Use Keychain for tokens
- Certificate pinning for production
- Validate all API responses
- Encrypt local storage

## Common Mistakes to Avoid
- Don't access state outside reducers
- Don't use reference types in state
- Don't perform side effects in reducers
- Don't forget cancellation IDs
- Don't skip error handling

Follow Point-Free's TCA documentation for detailed patterns. 