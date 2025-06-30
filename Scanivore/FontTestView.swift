//
//  FontTestView.swift
//  Scanivore
//
//  Font loading test
//

import SwiftUI

struct FontTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Airbnb Cereal Font Test")
                .font(DesignSystem.Typography.hero)
                .padding()
            
            Text("Hero Text (Medium)")
                .font(DesignSystem.Typography.hero)
            
            Text("Heading 1 (Medium)")
                .font(DesignSystem.Typography.heading1)
            
            Text("Body Text (Book/Regular)")
                .font(DesignSystem.Typography.body)
            
            Text("Body Medium")
                .font(DesignSystem.Typography.bodyMedium)
            
            Text("Body Semibold")
                .font(DesignSystem.Typography.bodySemibold)
            
            Text("Caption Text")
                .font(DesignSystem.Typography.caption)
            
            // Test if fonts are loaded
            Text("Available Fonts:")
                .font(.headline)
                .padding(.top)
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(UIFont.familyNames.sorted(), id: \.self) { family in
                        if family.contains("Cereal") || family.contains("Airbnb") {
                            Text(family)
                                .font(.caption)
                                .foregroundColor(.green)
                            ForEach(UIFont.fontNames(forFamilyName: family), id: \.self) { font in
                                Text("  - \(font)")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // Show if no custom fonts found
                    if !UIFont.familyNames.contains(where: { $0.contains("Cereal") || $0.contains("Airbnb") }) {
                        Text("❌ No Airbnb Cereal fonts found")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("Using system fonts instead")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding()
    }
}

#Preview {
    FontTestView()
} 