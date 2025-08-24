//
//  PreferencesView.swift
//  Scanivore
//
//  Dietary preferences management view
//

import SwiftUI
import ComposableArchitecture

// MARK: - Dietary Preference Type
public enum DietaryPreferenceType: String, CaseIterable, Equatable {
    case preservatives = "Avoid Preservatives"
    case antibioticFree = "Prefer Antibiotic-Free"
    case organic = "Prefer Organic"
    case sugars = "Avoid Added Sugars"
    case msg = "Avoid MSG"
    case sodium = "Lower Sodium"
    
    var subtitle: String {
        switch self {
        case .preservatives:
            return "Exclude products with artificial preservatives"
        case .antibioticFree:
            return "Prioritize antibiotic-free meat products"
        case .organic:
            return "Show organic options when available"
        case .sugars:
            return "Minimize products with added sugars"
        case .msg:
            return "Avoid monosodium glutamate"
        case .sodium:
            return "Prefer products with less salt"
        }
    }
    
    var systemImage: String {
        switch self {
        case .preservatives: return "flask"
        case .antibioticFree: return "cross.circle"
        case .organic: return "leaf"
        case .sugars: return "cube.fill"
        case .msg: return "exclamationmark.triangle"
        case .sodium: return "drop.fill"
        }
    }
}

// MARK: - Preferences Feature
@Reducer
public struct PreferencesFeature {
    @ObservableState
    public struct State: Equatable {
        public var preferences: OnboardingPreferences = OnboardingPreferences()
        public var originalPreferences: OnboardingPreferences = OnboardingPreferences()
        public var isLoading = false
        public var isSaving = false
        public var errorMessage: String?
        public var showingUnsavedChangesAlert = false
        
        public var hasUnsavedChanges: Bool {
            preferences != originalPreferences
        }
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case preferencesLoaded(TaskResult<OnboardingPreferences?>)
        case toggleDietaryPreference(DietaryPreferenceType)
        case toggleMeatType(MeatType)
        case saveButtonTapped
        case saveResponse(TaskResult<Bool>)
        case syncToBackendResponse(TaskResult<Bool>)
        case dismissError
        case dismissTapped
        case confirmDismissWithoutSaving
        case cancelDismiss
        case delegate(Delegate)
        
        public enum Delegate: Equatable {
            case preferencesUpdated
        }
    }
    
    @Dependency(\.onboarding) var onboardingClient
    @Dependency(\.userGateway) var userGateway
    @Dependency(\.authGateway) var authGateway
    @Dependency(\.dismiss) var dismiss
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    await send(.preferencesLoaded(
                        TaskResult { await onboardingClient.load() }
                    ))
                }
                
            case let .preferencesLoaded(.success(preferences)):
                state.isLoading = false
                if let preferences = preferences {
                    state.preferences = preferences
                    state.originalPreferences = preferences
                } else {
                    // Initialize with default preferences if none exist
                    let defaultPreferences = OnboardingPreferences(
                        avoidPreservatives: false,
                        antibioticFree: false,
                        preferOrganic: false,
                        avoidSugars: false,
                        avoidMSG: false,
                        lowerSodium: false,
                        preferredMeatTypes: [.beef, .pork, .chicken] // Default selection
                    )
                    state.preferences = defaultPreferences
                    state.originalPreferences = defaultPreferences
                }
                return .none
                
            case let .preferencesLoaded(.failure(error)):
                state.isLoading = false
                state.errorMessage = "Failed to load preferences: \(error.localizedDescription)"
                return .none
                
            case let .toggleDietaryPreference(type):
                switch type {
                case .preservatives:
                    state.preferences.avoidPreservatives?.toggle()
                case .antibioticFree:
                    state.preferences.antibioticFree?.toggle()
                case .organic:
                    state.preferences.preferOrganic?.toggle()
                case .sugars:
                    state.preferences.avoidSugars?.toggle()
                case .msg:
                    state.preferences.avoidMSG?.toggle()
                case .sodium:
                    state.preferences.lowerSodium?.toggle()
                }
                return .none
                
            case let .toggleMeatType(meatType):
                if state.preferences.preferredMeatTypes.contains(meatType) {
                    // Don't allow removing if it's the last one
                    if state.preferences.preferredMeatTypes.count > 1 {
                        state.preferences.preferredMeatTypes.remove(meatType)
                    }
                } else {
                    state.preferences.preferredMeatTypes.insert(meatType)
                }
                return .none
                
            case .saveButtonTapped:
                state.isSaving = true
                state.errorMessage = nil
                
                return .run { [preferences = state.preferences] send in
                    // Save locally first
                    await send(.saveResponse(
                        await TaskResult {
                            await onboardingClient.save(preferences)
                            return true
                        }
                    ))
                }
                
            case let .saveResponse(.success(success)):
                if success {
                    state.originalPreferences = state.preferences
                } else {
                    state.isSaving = false
                    state.errorMessage = "Failed to save preferences"
                    return .none
                }
                
                // Try to sync to backend if user is authenticated
                return .run { [preferences = state.preferences] send in
                    // Check if user is authenticated
                    if let currentUser = try? await authGateway.getCurrentUser(),
                       currentUser != nil {
                        // Convert OnboardingPreferences to UserPreferences for backend
                        let userPreferences = UserPreferences(
                            nutritionFocus: preferences.lowerSodium == true ? "sodium" : "protein",
                            avoidPreservatives: preferences.avoidPreservatives ?? false,
                            meatPreferences: Array(preferences.preferredMeatTypes.map { $0.rawValue.lowercased() }),
                            prefer_no_preservatives: preferences.avoidPreservatives ?? false,
                            prefer_antibiotic_free: preferences.antibioticFree ?? false,
                            prefer_organic_or_grass_fed: preferences.preferOrganic ?? false,
                            prefer_no_added_sugars: preferences.avoidSugars ?? false,
                            prefer_no_flavor_enhancers: preferences.avoidMSG ?? false,
                            prefer_reduced_sodium: preferences.lowerSodium ?? false,
                            preferred_meat_types: Array(preferences.preferredMeatTypes.map { $0.rawValue.lowercased() })
                        )
                        
                        await send(.syncToBackendResponse(
                            await TaskResult {
                                _ = try await userGateway.updatePreferences(userPreferences)
                                return true
                            }
                        ))
                    } else {
                        // Not authenticated, just complete the save
                        await send(.syncToBackendResponse(.success(true)))
                    }
                }
                
            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.errorMessage = "Failed to save preferences: \(error.localizedDescription)"
                return .none
                
            case let .syncToBackendResponse(.success(success)):
                state.isSaving = false
                if success {
                    // Notify the app that preferences have been updated
                    return .run { send in
                        await send(.delegate(.preferencesUpdated))
                        await dismiss()
                    }
                } else {
                    state.errorMessage = "Failed to sync preferences to backend"
                    return .none
                }
                
            case let .syncToBackendResponse(.failure(error)):
                state.isSaving = false
                // Backend sync failed, but local save succeeded
                // Still dismiss and notify since local save worked
                return .run { send in
                    await send(.delegate(.preferencesUpdated))
                    await dismiss()
                }
                
            case .dismissError:
                state.errorMessage = nil
                return .none
                
            case .dismissTapped:
                if state.hasUnsavedChanges {
                    state.showingUnsavedChangesAlert = true
                    return .none
                } else {
                    return .run { _ in
                        await dismiss()
                    }
                }
                
            case .confirmDismissWithoutSaving:
                state.showingUnsavedChangesAlert = false
                return .run { _ in
                    await dismiss()
                }
                
            case .cancelDismiss:
                state.showingUnsavedChangesAlert = false
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - Preferences View
struct PreferencesView: View {
    @Bindable var store: StoreOf<PreferencesFeature>
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                if store.isLoading {
                    ProgressView()
                        .tint(DesignSystem.Colors.primaryRed)
                } else {
                    Form {
                        dietaryRestrictionsSection
                        meatPreferencesSection
                        
                        Section {
                            Text("These preferences help us recommend products that match your dietary needs")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Dietary Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        store.send(.dismissTapped)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        store.send(.saveButtonTapped)
                    }
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .fontWeight(.medium)
                    .disabled(!store.hasUnsavedChanges || store.isSaving)
                }
            }
            .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
                Button("OK") {
                    store.send(.dismissError)
                }
            } message: {
                if let error = store.errorMessage {
                    Text(error)
                }
            }
            .alert("Unsaved Changes", isPresented: Binding(
                get: { store.showingUnsavedChangesAlert },
                set: { _ in }
            )) {
                Button("Discard Changes", role: .destructive) {
                    store.send(.confirmDismissWithoutSaving)
                }
                Button("Keep Editing", role: .cancel) {
                    store.send(.cancelDismiss)
                }
            } message: {
                Text("You have unsaved changes. Do you want to discard them?")
            }
            .disabled(store.isSaving)
            .overlay {
                if store.isSaving {
                    DesignSystem.Colors.textPrimary.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: DesignSystem.Spacing.base) {
                        ProgressView()
                            .tint(DesignSystem.Colors.background)
                        Text("Saving preferences...")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.background)
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.textPrimary.opacity(0.8))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
    
    private var dietaryRestrictionsSection: some View {
        Section("Dietary Restrictions") {
            ForEach(DietaryPreferenceType.allCases, id: \.self) { preference in
                PreferenceToggleRow(
                    title: preference.rawValue,
                    subtitle: preference.subtitle,
                    systemImage: preference.systemImage,
                    isOn: binding(for: preference),
                    action: {
                        store.send(.toggleDietaryPreference(preference))
                    }
                )
            }
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
    
    private var meatPreferencesSection: some View {
        Section("Preferred Meat Types") {
            ForEach([MeatType.beef, .pork, .chicken, .turkey, .lamb, .fish], id: \.self) { meatType in
                HStack {
                    Text("\(meatType.icon) \(meatType.rawValue)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if store.preferences.preferredMeatTypes.contains(meatType) {
                        Image(systemName: "checkmark")
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                            .font(DesignSystem.Typography.bodyMedium)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    store.send(.toggleMeatType(meatType))
                }
                .opacity(
                    store.preferences.preferredMeatTypes.count == 1 &&
                    store.preferences.preferredMeatTypes.contains(meatType) ? 0.6 : 1.0
                )
            }
            
            if store.preferences.preferredMeatTypes.isEmpty {
                Text("Select at least one meat type")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.error)
            }
        }
        .listRowBackground(DesignSystem.Colors.background)
    }
    
    private func binding(for preference: DietaryPreferenceType) -> Bool {
        switch preference {
        case .preservatives:
            return store.preferences.avoidPreservatives ?? false
        case .antibioticFree:
            return store.preferences.antibioticFree ?? false
        case .organic:
            return store.preferences.preferOrganic ?? false
        case .sugars:
            return store.preferences.avoidSugars ?? false
        case .msg:
            return store.preferences.avoidMSG ?? false
        case .sodium:
            return store.preferences.lowerSodium ?? false
        }
    }
}

// MARK: - Preference Toggle Row
private struct PreferenceToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isOn: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.base) {
            Image(systemName: systemImage)
                .foregroundColor(DesignSystem.Colors.primaryRed)
                .font(.system(size: DesignSystem.Typography.lg))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(isOn))
                .labelsHidden()
                .tint(DesignSystem.Colors.primaryRed)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

#Preview {
    PreferencesView(
        store: Store(initialState: PreferencesFeature.State()) {
            PreferencesFeature()
        }
    )
}

