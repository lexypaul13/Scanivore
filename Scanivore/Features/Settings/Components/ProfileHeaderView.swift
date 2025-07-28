//
//  ProfileHeaderView.swift
//  Scanivore
//
//  Profile header component for Settings
//

import SwiftUI

struct ProfileHeaderView: View {
    let userName: String
    let userEmail: String?
    let isSignedIn: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.base) {
            ProfileIcon()
            
            UserInfo(userName: userName, userEmail: userEmail)
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

// MARK: - Profile Icon
private struct ProfileIcon: View {
    var body: some View {
        Image(systemName: "person.crop.circle.fill")
            .font(DesignSystem.Typography.hero)
            .foregroundColor(DesignSystem.Colors.textSecondary)
    }
}

// MARK: - User Info
private struct UserInfo: View {
    let userName: String
    let userEmail: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(userName)
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let email = userEmail {
                Text(email)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}


#Preview {
    VStack(spacing: 20) {
        ProfileHeaderView(
            userName: "John Doe",
            userEmail: "john@example.com",
            isSignedIn: true
        )
        .padding()
        .background(DesignSystem.Colors.background)
        
        ProfileHeaderView(
            userName: "Guest User",
            userEmail: nil,
            isSignedIn: false
        )
        .padding()
        .background(DesignSystem.Colors.background)
    }
}