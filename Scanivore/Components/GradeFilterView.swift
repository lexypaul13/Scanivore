//
//  GradeFilterView.swift
//  Scanivore
//
//  Grade filter component for the Explore feature
//

import SwiftUI
import ComposableArchitecture

struct GradeFilterView: View {
    let store: StoreOf<ExploreFeatureDomain>
    @Environment(\.dismiss) private var dismiss
    
    private let availableGrades: [SafetyGrade] = [.excellent, .fair, .bad]
    
    var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                ZStack {
                    DesignSystem.Colors.backgroundSecondary
                        .ignoresSafeArea()
                    
                    Form {
                        Section("Filter by Safety Grade") {
                            ForEach(availableGrades, id: \.self) { grade in
                                HStack {
                                    gradeIndicator(for: grade)
                                    Text(grade.rawValue)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    if store.selectedGrades.contains(grade) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(DesignSystem.Colors.primaryRed)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    store.send(.gradeToggled(grade))
                                }
                                .listRowBackground(DesignSystem.Colors.background)
                            }
                            
                            // Show All option
                            HStack {
                                Text("Show All")
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                if store.selectedGrades.isEmpty {
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
    
    @ViewBuilder
    private func gradeIndicator(for grade: SafetyGrade) -> some View {
        Circle()
            .fill(gradeColor(for: grade))
            .frame(width: 24, height: 24)
    }
    
    private func gradeColor(for grade: SafetyGrade) -> Color {
        switch grade {
        case .excellent:
            return Color(red: 0.0, green: 0.8, blue: 0.0) // Green
        case .fair:
            return Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow
        case .bad:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // Red
        }
    }
}
