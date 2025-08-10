//
//  AuthComponents.swift
//  Scanivore
//
//  Shared authentication UI components
//

import SwiftUI

// MARK: - Auth Text Field
struct AuthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let errorMessage: String?
    
    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Field label
            Text(title)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Input field
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Components.Input.cornerRadius)
                    .fill(DesignSystem.Colors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Components.Input.cornerRadius)
                            .stroke(
                                errorMessage != nil ? DesignSystem.Colors.error :
                                isFocused ? DesignSystem.Colors.primaryRed :
                                DesignSystem.Colors.border,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                    .frame(height: DesignSystem.Components.Input.height)
                
                HStack {
                    if isSecure {
                        if isPasswordVisible {
                            TextField(placeholder, text: $text)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .accentColor(DesignSystem.Colors.primaryRed)
                                .focused($isFocused)
                                .keyboardType(keyboardType)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField(placeholder, text: $text)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .accentColor(DesignSystem.Colors.primaryRed)
                                .focused($isFocused)
                                .keyboardType(keyboardType)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .font(.system(size: 16))
                        }
                    } else {
                        TextField(placeholder, text: $text)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .accentColor(DesignSystem.Colors.primaryRed)
                            .focused($isFocused)
                            .keyboardType(keyboardType)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    if !isSecure {
                        Spacer()
                    }
                }
                .padding(.horizontal, DesignSystem.Components.Input.padding)
            }
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.error)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }
}

// MARK: - Auth Button
struct AuthButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let style: AuthButtonStyle
    let action: () -> Void
    
    enum AuthButtonStyle {
        case primary
        case secondary
    }
    
    init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        style: AuthButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: titleColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(DesignSystem.Typography.buttonText)
                }
            }
            .foregroundColor(titleColor)
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
            .cornerRadius(cornerRadius)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var titleColor: Color {
        switch style {
        case .primary:
            return DesignSystem.Colors.background
        case .secondary:
            return DesignSystem.Colors.primaryRed
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return DesignSystem.Colors.primaryRed
        case .secondary:
            return DesignSystem.Colors.background
        }
    }
    
    private var strokeColor: Color {
        switch style {
        case .primary:
            return Color.clear
        case .secondary:
            return DesignSystem.Colors.primaryRed
        }
    }
    
    private var strokeWidth: CGFloat {
        switch style {
        case .primary:
            return 0
        case .secondary:
            return 2
        }
    }
    
    private var buttonHeight: CGFloat {
        switch style {
        case .primary:
            return DesignSystem.Components.Button.primaryHeight
        case .secondary:
            return DesignSystem.Components.Button.secondaryHeight
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .primary:
            return DesignSystem.Components.Button.primaryCornerRadius
        case .secondary:
            return DesignSystem.Components.Button.secondaryCornerRadius
        }
    }
}

// MARK: - Auth Header
struct AuthHeader: View {
    let title: String
    let subtitle: String
    let showBackButton: Bool
    let onBackTapped: (() -> Void)?
    
    init(
        title: String,
        subtitle: String,
        showBackButton: Bool = true,
        onBackTapped: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.onBackTapped = onBackTapped
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                if showBackButton {
                    Button(action: onBackTapped ?? {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: DesignSystem.Typography.lg))
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Previews
#Preview {
    VStack(spacing: 20) {
        AuthTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant(""),
            keyboardType: .emailAddress
        )
        
        AuthTextField(
            title: "Password",
            placeholder: "Enter your password",
            text: .constant(""),
            isSecure: true,
            errorMessage: "Password is required"
        )
        
        AuthButton(title: "Sign In", action: {})
        
        AuthButton(
            title: "Create Account",
            style: .secondary,
            action: {}
        )
        
        AuthButton(
            title: "Loading...",
            isLoading: true,
            action: {}
        )
    }
    .padding()
}