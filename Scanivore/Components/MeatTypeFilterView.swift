//
//  MeatTypeFilterView.swift
//  Scanivore
//
//  Meat type filter component for the Explore feature
//

import SwiftUI
import ComposableArchitecture

struct MeatTypeFilterView: View {
    let store: StoreOf<ExploreFeatureDomain>
    @Environment(\.dismiss) private var dismiss
    
    private let availableMeatTypes: [MeatType] = [.beef, .pork, .chicken, .lamb, .turkey, .fish]
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    DesignSystem.Colors.backgroundSecondary
                        .ignoresSafeArea()
                    
                    Form {
                        Section("Filter by Meat Type") {
                            ForEach(availableMeatTypes, id: \.self) { meatType in
                                HStack {
                                    Text("\(meatType.icon) \(meatType.rawValue)")
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if store.selectedMeatTypes.contains(meatType) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(DesignSystem.Colors.primaryRed)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.meatTypeToggled(meatType))
                                }
                                .listRowBackground(DesignSystem.Colors.background)
                            }
                            
                            // Show All option
                            HStack {
                                Text("Show All")
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                if store.selectedMeatTypes.isEmpty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.send(.clearAllFilters)
                            }
                            .listRowBackground(DesignSystem.Colors.background)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("Filter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                }
            }
        }
    }
}