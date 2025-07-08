//
//  LoginView.swift
//  Scanivore
//
//  Login view with Create Account and Sign In options
//

import SwiftUI
import ComposableArchitecture

struct LoginView: View {
    let store: StoreOf<LoginFeatureDomain>
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 50
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                // Background gradient similar to onboarding
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.backgroundSecondary,
                        DesignSystem.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo and app name section
                    VStack(spacing: 10) {
                        // App logo with animation - using 3x image
                        Image(uiImage: UIImage(named: "Scanivore_Logo") ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .background(Color.clear)
                            .scaleEffect(logoScale)
          
                        
                        // App name and tagline
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("Scanivore")
                                .font(DesignSystem.Typography.hero)
                                .foregroundColor(DesignSystem.Colors.primaryRed)
                            
                            Text("Know what you're eating")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .opacity(contentOpacity)
                    .padding(.bottom, DesignSystem.Spacing.xxxxxl)
                    
                    Spacer()
                    
                    // Authentication buttons section
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Create Account button (Primary)
                        Button {
                            store.send(.createAccountTapped)
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 20, weight: .medium))
                                
                                Text("Create Account")
                                    .font(DesignSystem.Typography.buttonText)
                            }
                            .foregroundColor(DesignSystem.Colors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignSystem.Components.Button.primaryHeight)
                            .background(DesignSystem.Colors.primaryRed)
                            .cornerRadius(DesignSystem.Components.Button.primaryCornerRadius)
                            .shadow(
                                color: DesignSystem.Colors.primaryRed.opacity(0.3),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Sign In button (Secondary)
                        Button {
                            store.send(.signInTapped)
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 20, weight: .medium))
                                
                                Text("Sign In")
                                    .font(DesignSystem.Typography.buttonText)
                            }
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignSystem.Components.Button.secondaryHeight)
                            .background(DesignSystem.Colors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Components.Button.secondaryCornerRadius)
                                    .stroke(DesignSystem.Colors.primaryRed, lineWidth: 2)
                            )
                            .cornerRadius(DesignSystem.Components.Button.secondaryCornerRadius)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Terms and privacy text
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            Text("By continuing, you agree to our")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Button("Terms of Service") {
                                    // Handle terms tap
                                }
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.primaryRed)
                                .underline()
                                
                                Text("and")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Button("Privacy Policy") {
                                    // Handle privacy tap
                                }
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.primaryRed)
                                .underline()
                            }
                        }
                        .padding(.top, DesignSystem.Spacing.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.bottom, DesignSystem.Spacing.xxxl)
                    .offset(y: buttonsOffset)
                    .opacity(contentOpacity)
                }
            }
            .onAppear {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        // Logo scale animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
        }
        
        // Content fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            contentOpacity = 1.0
        }
        
        // Buttons slide up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            buttonsOffset = 0
        }
    }
}

#Preview {
    LoginView(
        store: Store(initialState: LoginFeatureDomain.State()) {
            LoginFeatureDomain()
        }
    )
}
