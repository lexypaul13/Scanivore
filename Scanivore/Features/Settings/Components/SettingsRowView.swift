//
//  SettingsRowView.swift
//  Scanivore
//
//  Reusable settings row component
//

import SwiftUI

struct SettingsRowView: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: systemImage)
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    Form {
        SettingsRowView(
            title: "Manage Scan Data",
            systemImage: "folder",
            color: DesignSystem.Colors.textPrimary,
            action: {}
        )
        
        SettingsRowView(
            title: "Privacy Policy",
            systemImage: "hand.raised",
            color: DesignSystem.Colors.textPrimary,
            action: {}
        )
        
        SettingsRowView(
            title: "About Scanivore",
            systemImage: "info.circle",
            color: DesignSystem.Colors.primaryRed,
            action: {}
        )
    }
}