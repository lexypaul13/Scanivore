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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DesignSystem.Spacing.sm)
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