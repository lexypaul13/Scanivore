//
//  DebugAuthView.swift
//  Scanivore
//
//  Debug view to verify authentication status
//

import SwiftUI
import ComposableArchitecture

struct DebugAuthView: View {
    @Dependency(\.authGateway) var authGateway
    @State private var authStatus = "Checking..."
    @State private var userInfo = ""
    @State private var token = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("🔐 Authentication Debug")
                .font(DesignSystem.Typography.heading1)
                .padding(.bottom)
            
            // Auth Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Status:")
                    .font(DesignSystem.Typography.heading3)
                Text(authStatus)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
            }
            
            // User Info
            if !userInfo.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("User Info:")
                        .font(DesignSystem.Typography.heading3)
                    Text(userInfo)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue)
                }
            }
            
            // Token Preview
            if !token.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Token (first 50 chars):")
                        .font(DesignSystem.Typography.heading3)
                    Text(token)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("Check Status") {
                    Task {
                        await checkAuthStatus()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Get User Info") {
                    Task {
                        await fetchUserInfo()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                await checkAuthStatus()
            }
        }
    }
    
    private func checkAuthStatus() async {
        let isLoggedIn = await authGateway.isLoggedIn()
        authStatus = isLoggedIn ? "✅ Logged In" : "❌ Not Logged In"
        
        if isLoggedIn {
            Task {
                if let storedToken = try? await TokenManager.shared.getToken() {
                    token = String(storedToken.prefix(50)) + "..."
                }
            }
        }
    }
    
    private func fetchUserInfo() async {
        do {
            if let user = try await authGateway.getCurrentUser() {
                userInfo = """
                Email: \(user.email)
                ID: \(user.id)
                Full Name: \(user.fullName ?? "N/A")
                Active: \(user.isActive)
                """
            } else {
                userInfo = "No user found"
            }
        } catch {
            userInfo = "Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    DebugAuthView()
}
