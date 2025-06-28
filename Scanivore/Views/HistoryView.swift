//
//  HistoryView.swift
//  Scanivore
//
//  Created by Alex Paul on 6/28/25.
//

import SwiftUI

struct HistoryView: View {
    @State private var searchText = ""
    @State private var selectedFilter: MeatType? = nil
    @State private var sortOption: SortOption = .dateDescending
    @State private var showingFilters = false
    
    let mockScans = MeatScan.mockScans
    
    var filteredScans: [MeatScan] {
        var scans = mockScans
        
        if !searchText.isEmpty {
            scans = scans.filter { scan in
                scan.meatType.rawValue.localizedCaseInsensitiveContains(searchText) ||
                scan.quality.grade.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let filter = selectedFilter {
            scans = scans.filter { $0.meatType == filter }
        }
        
        switch sortOption {
        case .dateDescending:
            scans.sort { $0.date > $1.date }
        case .dateAscending:
            scans.sort { $0.date < $1.date }
        case .qualityDescending:
            scans.sort { $0.quality.score > $1.quality.score }
        case .qualityAscending:
            scans.sort { $0.quality.score < $1.quality.score }
        }
        
        return scans
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if filteredScans.isEmpty {
                        EmptyHistoryView()
                    } else {
                        List {
                            ForEach(groupedScans(), id: \.key) { section in
                                Section(header: Text(section.key)
                                    .font(DesignSystem.Typography.heading2)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                ) {
                                    ForEach(section.value) { scan in
                                        HistoryRowView(scan: scan)
                                            .listRowBackground(DesignSystem.Colors.background)
                                    }
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Scan History")
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search scans...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(
                    selectedFilter: $selectedFilter,
                    sortOption: $sortOption
                )
            }
        }
    }
    
    private func groupedScans() -> [(key: String, value: [MeatScan])] {
        let grouped = Dictionary(grouping: filteredScans) { scan in
            formatSectionDate(scan.date)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

struct HistoryRowView: View {
    let scan: MeatScan
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Text(scan.meatType.icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(scan.quality.color.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(scan.quality.color.opacity(0.3), lineWidth: 2)
                            )
                    )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(scan.meatType.rawValue)
                        .font(DesignSystem.Typography.heading2)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        Text("Grade: \(scan.quality.grade)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("•")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text(scan.freshness.rawValue)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(scan.freshness.color)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text(scan.date.formatted(date: .omitted, time: .shortened))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if !scan.warnings.isEmpty {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DesignSystem.Colors.warning)
                            .font(DesignSystem.Typography.caption)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ProductDetailView(scan: scan)
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("No Scans Yet")
                .font(DesignSystem.Typography.heading1)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Your scan history will appear here")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.backgroundSecondary)
    }
}

struct FilterView: View {
    @Binding var selectedFilter: MeatType?
    @Binding var sortOption: SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundSecondary
                    .ignoresSafeArea()
                
                Form {
                    Section("Filter by Meat Type") {
                        ForEach([nil] + MeatType.allCases.filter { $0 != .unknown }, id: \.self) { type in
                            HStack {
                                if let type = type {
                                    Text("\(type.icon) \(type.rawValue)")
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                } else {
                                    Text("All Types")
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                                
                                Spacer()
                                
                                if selectedFilter == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFilter = type
                            }
                            .listRowBackground(DesignSystem.Colors.background)
                        }
                    }
                    
                    Section("Sort By") {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            HStack {
                                Text(option.displayName)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                sortOption = option
                            }
                            .listRowBackground(DesignSystem.Colors.background)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filters")
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

enum SortOption: CaseIterable {
    case dateDescending
    case dateAscending
    case qualityDescending
    case qualityAscending
    
    var displayName: String {
        switch self {
        case .dateDescending: return "Newest First"
        case .dateAscending: return "Oldest First"
        case .qualityDescending: return "Highest Quality"
        case .qualityAscending: return "Lowest Quality"
        }
    }
}

#Preview {
    HistoryView()
}