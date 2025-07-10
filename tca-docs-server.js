#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

// TCA Documentation
const tcaDocs = {
  reducer: `
# TCA Reducer Pattern

A reducer in TCA is the core of your feature. It defines how state changes in response to actions.

## Basic Structure
\`\`\`swift
@Reducer
struct FeatureReducer {
  @ObservableState
  struct State: Equatable {
    // Your state properties
  }
  
  enum Action {
    // Your actions
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .someAction:
        // Update state
        return .none // or some effect
      }
    }
  }
}
\`\`\`

## Best Practices
- Use the @Reducer macro for all reducers
- Keep state immutable and Equatable
- Return .none when no effects are needed
- Group related functionality with Scope and Reduce
`,

  state: `
# TCA State Management

State in TCA is the single source of truth for your feature.

## State Definition
\`\`\`swift
@ObservableState
struct State: Equatable {
  var items: IdentifiedArrayOf<Item> = []
  var isLoading = false
  var selectedID: Item.ID?
  @Presents var destination: Destination.State?
}
\`\`\`

## Best Practices
- Use @ObservableState for all state types
- Implement Equatable for performance
- Use value types only (structs)
- Use IdentifiedArrayOf for collections
- Use @Presents for optional child states
`,

  action: `
# TCA Actions

Actions represent all the events that can occur in your feature.

## Action Definition
\`\`\`swift
enum Action: Equatable {
  // User events (present tense)
  case buttonTapped
  case textChanged(String)
  
  // Effects responses (past tense)
  case dataLoaded(TaskResult<[Item]>)
  
  // Child feature actions
  case destination(PresentationAction<Destination.Action>)
  case path(StackAction<Path.State, Path.Action>)
  
  // Delegation
  case delegate(Delegate)
  
  enum Delegate: Equatable {
    case didComplete
    case didSelectItem(Item.ID)
  }
}
\`\`\`

## Best Practices
- Use present tense for user events
- Use past tense for effect responses
- Use TaskResult for async operations
- Group related actions with enums
`,

  effect: `
# TCA Effects

Effects in TCA handle side effects like network requests, timers, and other async operations.

## Basic Effect
\`\`\`swift
// In reducer
case .loadData:
  state.isLoading = true
  return .run { send in
    await send(.dataLoaded(
      TaskResult { try await apiClient.fetchData() }
    ))
  }

case let .dataLoaded(.success(data)):
  state.isLoading = false
  state.data = data
  return .none
  
case let .dataLoaded(.failure(error)):
  state.isLoading = false
  state.error = error.localizedDescription
  return .none
\`\`\`

## Cancellation
\`\`\`swift
case .startTimer:
  return .run { send in
    for await _ in self.clock.timer(interval: .seconds(1)) {
      await send(.timerTicked)
    }
  }
  .cancellable(id: TimerID.self)

case .stopTimer:
  return .cancel(id: TimerID.self)
\`\`\`
`,

  dependencies: `
# TCA Dependencies

Dependencies in TCA provide a way to inject services and manage side effects.

## Defining a Client
\`\`\`swift
@DependencyClient
struct APIClient: Sendable {
  var fetchItems: @Sendable () async throws -> [Item]
}

extension APIClient: DependencyKey {
  static let liveValue = Self(
    fetchItems: {
      let (data, _) = try await URLSession.shared.data(from: URL(string: "https://api.example.com/items")!)
      return try JSONDecoder().decode([Item].self, from: data)
    }
  )
  
  static let testValue = Self(
    fetchItems: { [] }
  )
}

extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}
\`\`\`

## Using Dependencies
\`\`\`swift
@Dependency(\.apiClient) var apiClient

// In reducer
case .loadItems:
  return .run { send in
    await send(.itemsResponse(
      TaskResult { try await apiClient.fetchItems() }
    ))
  }
\`\`\`
`,

  navigation: `
# TCA Navigation

TCA supports two main navigation patterns: stack-based and tree-based.

## Stack Navigation
\`\`\`swift
@Reducer
struct FlowFeature {
  @Reducer(state: .equatable)
  enum Path {
    case detail(DetailFeature)
    case settings(SettingsFeature)
  }

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    var items: IdentifiedArrayOf<Item> = []
  }

  enum Action {
    case path(StackActionOf<Path>)
    case itemTapped(Item.ID)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .itemTapped(id):
        guard let item = state.items[id: id] else { return .none }
        state.path.append(.detail(.init(item: item)))
        return .none
        
      case .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}
\`\`\`

## Tree Navigation (Sheets, Popovers)
\`\`\`swift
@ObservableState
struct State: Equatable {
  @Presents var destination: Destination.State?
}

@Reducer(state: .equatable)
enum Destination {
  case detail(DetailFeature)
  case alert(AlertState<Action.Alert>)
}

// In view
.sheet(store: store.scope(state: \.$destination.detail, action: \.destination.detail)) { store in
  DetailView(store: store)
}
.alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
\`\`\`
`,

  testing: `
# TCA Testing

TCA provides a powerful TestStore for testing reducers.

## Basic Test
\`\`\`swift
@MainActor
func testCounter() async {
  let store = TestStore(initialState: Counter.State()) {
    Counter()
  }
  
  await store.send(.incrementButtonTapped) {
    $0.count = 1
  }
  
  await store.send(.decrementButtonTapped) {
    $0.count = 0
  }
}
\`\`\`

## Testing Effects
\`\`\`swift
@MainActor
func testLoadItems() async {
  let store = TestStore(initialState: Feature.State()) {
    Feature()
  } withDependencies: {
    $0.apiClient.fetchItems = { [item1, item2] }
  }
  
  await store.send(.loadItems) {
    $0.isLoading = true
  }
  
  await store.receive(\.itemsResponse.success) {
    $0.isLoading = false
    $0.items = [item1, item2]
  }
}
\`\`\`
`,

  binding: `
# TCA Bindings

Bindings allow for two-way communication between views and state.

## Using Bindings
\`\`\`swift
@ObservableState
struct State: Equatable {
  var text = ""
  var isToggled = false
}

enum Action {
  case textChanged(String)
  case toggleChanged(Bool)
}

// In view
TextField("Enter text", text: viewStore.binding(
  get: \.text,
  send: { Action.textChanged($0) }
))

Toggle("Option", isOn: viewStore.binding(
  get: \.isToggled,
  send: { Action.toggleChanged($0) }
))
\`\`\`

## With @Bindable
\`\`\`swift
@ObservableState
struct State: Equatable {
  @BindableState var text = ""
  @BindableState var isToggled = false
}

enum Action: BindableAction {
  case binding(BindingAction<State>)
  case submitTapped
}

// In reducer
Reduce { state, action in
  switch action {
  case .binding:
    return .none
  case .submitTapped:
    // Handle submission
    return .none
  }
}
.binding()

// In view with @Bindable
@Bindable var store: StoreOf<Feature>

TextField("Enter text", text: $store.text)
Toggle("Option", isOn: $store.isToggled)
\`\`\`
`,

  observablestate: `
# @ObservableState in TCA

The @ObservableState macro enables SwiftUI to track state changes efficiently.

## Usage
\`\`\`swift
@Reducer
struct Feature {
  @ObservableState
  struct State: Equatable {
    var count = 0
    var text = ""
    var items: IdentifiedArrayOf<Item> = []
  }
  
  // Actions, reducer, etc.
}
\`\`\`

## In Views
\`\`\`swift
struct FeatureView: View {
  @Bindable var store: StoreOf<Feature>
  
  var body: some View {
    VStack {
      Text("Count: \(store.count)")
      TextField("Text", text: $store.text)
      
      ForEach(store.items) { item in
        Text(item.name)
      }
      
      Button("Increment") {
        store.send(.incrementTapped)
      }
    }
  }
}
\`\`\`

## Best Practices
- Always make State conform to Equatable
- Use @Bindable for store bindings
- Never access store.state directly
- Use store.send() for all actions
`,

  presents: `
# @Presents in TCA

The @Presents property wrapper manages optional child states for navigation.

## Usage
\`\`\`swift
@ObservableState
struct State: Equatable {
  var items: IdentifiedArrayOf<Item> = []
  @Presents var destination: Destination.State?
}

@Reducer(state: .equatable)
enum Destination {
  case detail(DetailFeature)
  case settings(SettingsFeature)
  case alert(AlertState<Action.Alert>)
}

enum Action {
  case destination(PresentationAction<Destination.Action>)
  case showDetail(Item.ID)
  case showSettings
  case showAlert(String)
}

var body: some ReducerOf<Self> {
  Reduce { state, action in
    switch action {
    case let .showDetail(id):
      guard let item = state.items[id: id] else { return .none }
      state.destination = .detail(.init(item: item))
      return .none
      
    case .showSettings:
      state.destination = .settings(.init())
      return .none
      
    case let .showAlert(message):
      state.destination = .alert(.init { 
        TextState(message)
      })
      return .none
      
    case .destination:
      return .none
    }
  }
  .ifLet(\.$destination, action: \.destination)
}
\`\`\`

## In Views
\`\`\`swift
.sheet(store: store.scope(state: \.$destination.detail, action: \.destination.detail)) { store in
  DetailView(store: store)
}
.sheet(store: store.scope(state: \.$destination.settings, action: \.destination.settings)) { store in
  SettingsView(store: store)
}
.alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
\`\`\`
`,

  shared: `
# @Shared in TCA

The @Shared property wrapper allows sharing state across multiple features.

## Definition
\`\`\`swift
// Define a shared state key
enum UserSessionKey: DependencyKey {
  static let liveValue = CurrentValueSubject<User?, Never>(nil)
}

// Register in dependency values
extension DependencyValues {
  var userSession: CurrentValueSubject<User?, Never> {
    get { self[UserSessionKey.self] }
    set { self[UserSessionKey.self] = newValue }
  }
}
\`\`\`

## Usage in Reducers
\`\`\`swift
@Reducer
struct Feature {
  @ObservableState
  struct State: Equatable {
    var localState = ""
  }
  
  enum Action {
    case onAppear
    case userSessionChanged(User?)
  }
  
  @Dependency(\.userSession) var userSession
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          for await user in userSession.values {
            await send(.userSessionChanged(user))
          }
        }
        
      case let .userSessionChanged(user):
        // Update local state based on shared user
        return .none
      }
    }
  }
}
\`\`\`

## With @Shared Macro
\`\`\`swift
// In a reducer
@Shared(.userProfile) var profile

// Update shared state
profile = newProfile

// Access shared state
let currentProfile = profile
\`\`\`
`,

  identifiedarray: `
# IdentifiedArray in TCA

IdentifiedArray is a collection that provides efficient lookup by ID.

## Basic Usage
\`\`\`swift
@ObservableState
struct State: Equatable {
  var items: IdentifiedArrayOf<Item> = []
}

// Adding items
state.items.append(item)
state.items.append(contentsOf: newItems)

// Accessing by ID
if let item = state.items[id: itemID] {
  // Use item
}

// Updating by ID
state.items[id: itemID]?.name = "New Name"

// Removing
state.items.remove(id: itemID)
\`\`\`

## With ForEach in SwiftUI
\`\`\`swift
ForEach(store.items) { item in
  Text(item.name)
    .onTapGesture {
      store.send(.itemTapped(item.id))
    }
}
\`\`\`

## Benefits
- O(1) lookup by ID
- Maintains stable identity
- Prevents duplicates
- Works well with SwiftUI's ForEach
`
};

// Define the TCA documentation tools
const tcaTools = [
  {
    name: 'tca_docs',
    description: 'Get documentation about TCA (The Composable Architecture) concepts',
    inputSchema: {
      type: 'object',
      properties: {
        concept: {
          type: 'string',
          description: 'The TCA concept to get documentation for',
          enum: Object.keys(tcaDocs),
        },
      },
      required: ['concept'],
    },
  },
];

// Create the server
const server = new Server(
  {
    name: 'tca-docs',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List tools handler
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: tcaTools,
  };
});

// Tool call handler
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === 'tca_docs') {
    const concept = request.params.arguments.concept;
    if (tcaDocs[concept]) {
      return {
        content: [
          {
            type: 'text',
            text: tcaDocs[concept],
          },
        ],
      };
    } else {
      return {
        content: [
          {
            type: 'text',
            text: `Documentation for concept "${concept}" not found. Available concepts: ${Object.keys(tcaDocs).join(', ')}`,
          },
        ],
      };
    }
  }
  throw new Error(`Unknown tool: ${request.params.name}`);
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('TCA Documentation MCP Server started successfully');
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
}); 