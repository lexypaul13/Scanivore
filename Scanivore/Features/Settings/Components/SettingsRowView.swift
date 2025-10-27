
import SwiftUI

struct SettingsRowView: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
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
