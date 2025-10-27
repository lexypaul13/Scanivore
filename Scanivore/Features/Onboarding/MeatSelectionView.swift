
import SwiftUI
import ComposableArchitecture
import Foundation
// MARK: - MeatSelection Feature
@Reducer
struct MeatSelectionFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var selectedTypes: Set<MeatType> = []
        
        var canContinue: Bool {
            !selectedTypes.isEmpty
        }
    }
    
    enum Action: Equatable {
        case meatTypeToggled(MeatType)
        case continueButtonTapped
        case delegate(Delegate)
        
        enum Delegate: Equatable {
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
extension MeatSelectionFeatureDomain {
    static let availableMeatTypes: [(type: MeatType, name: String)] = [
        (.chicken, "Chicken"),
        (.turkey, "Turkey"),
        (.beef, "Beef"),
        (.lamb, "Lamb"),
        (.pork, "Pork"),
        (.fish, "Fish")
    ]
} 
struct MeatSelectionView: View {
    let store: StoreOf<MeatSelectionFeatureDomain>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: DesignSystem.Spacing.xl)
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                     
                    Text("Primary meat types?")
                        .font(DesignSystem.Typography.heading1)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                    
                  
                    Text("Select the types of meat you purchase most often")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xxxl)
                }
                
                Spacer()
                    .frame(height: DesignSystem.Spacing.xxxl)
                
                 
                VStack(spacing: DesignSystem.Spacing.base) {
                    ForEach(MeatSelectionFeatureDomain.availableMeatTypes, id: \.type) { meatInfo in
                        MeatTypeRow(
                            type: meatInfo.type,
                            name: meatInfo.name,
                            isSelected: store.selectedTypes.contains(meatInfo.type),
                            onTap: {
                                store.send(.meatTypeToggled(meatInfo.type))
                            }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                
                Spacer()
                
                
                Button(action: { store.send(.continueButtonTapped) }) {
                    Text("Continue")
                        .font(DesignSystem.Typography.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignSystem.Components.Button.primaryHeight)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Components.Button.primaryCornerRadius)
                                .fill(store.canContinue ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.textSecondary)
                        )
                }
                .disabled(!store.canContinue)
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                .padding(.bottom, 60)
            }
        }
    }
}

struct MeatTypeRow: View {
    let type: MeatType
    let name: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.base) {
              
                Text(type.icon)
                    .font(DesignSystem.Typography.heading2)
                    .frame(width: 40)
                
                 
                Text(name)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
             
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(isSelected ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.border)
            }
            .padding(DesignSystem.Spacing.base)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isSelected ? DesignSystem.Colors.primaryRed.opacity(0.1) : DesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(isSelected ? DesignSystem.Colors.primaryRed : DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MeatSelectionView(
        store: Store(
            initialState: MeatSelectionFeatureDomain.State(
                selectedTypes: [.chicken, .beef]
            )
        ) {
            MeatSelectionFeatureDomain()
        }
    )
} 
