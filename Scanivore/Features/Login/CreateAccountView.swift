//
//  CreateAccountView.swift
//  Scanivore
//
//  Create account view with form validation
//

import SwiftUI
import ComposableArchitecture

// MARK: - Create Account Feature Domain
@Reducer
struct CreateAccountFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var email = ""
        var password = ""
        var confirmPassword = ""
        var fullName = ""
        var isLoading = false
        var errorMessage: String?
        
        // Validation states
        var emailError: String?
        var passwordError: String?
        var confirmPasswordError: String?
        
        var isFormValid: Bool {
            !email.isEmpty &&
            !password.isEmpty &&
            !confirmPassword.isEmpty &&
            emailError == nil &&
            passwordError == nil &&
            confirmPasswordError == nil
        }
    }
    
    enum Action: Equatable {
        case emailChanged(String)
        case passwordChanged(String)
        case confirmPasswordChanged(String)
        case fullNameChanged(String)
        case createAccountTapped
        case backTapped
        case clearError
        case validateEmail
        case validatePassword
        case validateConfirmPassword
        case createAccountResponse(TaskResult<Bool>)
        
        enum Delegate: Equatable {
            case accountCreated
            case navigateBack
        }
        case delegate(Delegate)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .emailChanged(email):
                state.email = email
                state.emailError = nil
                return .run { send in
                    try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                    await send(.validateEmail)
                }
                
            case let .passwordChanged(password):
                state.password = password
                state.passwordError = nil
                return .run { send in
                    try await Task.sleep(nanoseconds: 300_000_000)
                    await send(.validatePassword)
                }
                
            case let .confirmPasswordChanged(confirmPassword):
                state.confirmPassword = confirmPassword
                state.confirmPasswordError = nil
                return .run { send in
                    try await Task.sleep(nanoseconds: 300_000_000)
                    await send(.validateConfirmPassword)
                }
                
            case let .fullNameChanged(fullName):
                state.fullName = fullName
                return .none
                
            case .validateEmail:
                if !state.email.isEmpty && !isValidEmail(state.email) {
                    state.emailError = "Please enter a valid email address"
                }
                return .none
                
            case .validatePassword:
                if !state.password.isEmpty {
                    let passwordValidation = validatePassword(state.password)
                    if let error = passwordValidation {
                        state.passwordError = error
                    }
                }
                return .none
                
            case .validateConfirmPassword:
                if !state.confirmPassword.isEmpty && state.password != state.confirmPassword {
                    state.confirmPasswordError = "Passwords do not match"
                }
                return .none
                
            case .createAccountTapped:
                guard state.isFormValid else { return .none }
                
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { [email = state.email, password = state.password, fullName = state.fullName] send in
                    await send(.createAccountResponse(
                        await TaskResult {
                            @Dependency(\.authGateway) var authGateway
                            
                            // Call real API
                            _ = try await authGateway.register(email, password, fullName)
                            return true
                        }
                    ))
                }
                
            case let .createAccountResponse(.success(success)):
                state.isLoading = false
                if success {
                    return .run { send in
                        await send(.delegate(.accountCreated))
                    }
                } else {
                    state.errorMessage = "Failed to create account. Please try again."
                    return .none
                }
                
            case let .createAccountResponse(.failure(error)):
                state.isLoading = false
                
                // Handle API-specific errors
                if let apiError = error as? APIError {
                    switch apiError.statusCode {
                    case 409:
                        state.errorMessage = "An account with this email already exists. Please try signing in instead."
                    case 400:
                        state.errorMessage = apiError.detail
                    default:
                        state.errorMessage = "Account creation failed: \(apiError.detail)"
                    }
                } else {
                    state.errorMessage = "Account creation failed: \(error.localizedDescription)"
                }
                return .none
                
            case .backTapped:
                return .run { send in
                    await send(.delegate(.navigateBack))
                }
                
            case .clearError:
                state.errorMessage = nil
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

struct CreateAccountView: View {
    let store: StoreOf<CreateAccountFeatureDomain>
    @State private var contentOpacity: Double = 0
    @State private var formOffset: CGFloat = 30
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.backgroundSecondary,
                        DesignSystem.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        AuthHeader(
                            title: "Create Account",
                            subtitle: "Join Scanivore to start scanning and get healthier food choices",
                            showBackButton: true,
                            onBackTapped: {
                                store.send(.backTapped)
                            }
                        )
                        .padding(.top, DesignSystem.Spacing.xl)
                        
                        // Form
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // Full Name field
                            AuthTextField(
                                title: "Full Name",
                                placeholder: "Enter your full name",
                                text: .init(
                                    get: { store.fullName },
                                    set: { store.send(.fullNameChanged($0)) }
                                ),
                                keyboardType: .default,
                                errorMessage: nil
                            )
                            
                            // Email field
                            AuthTextField(
                                title: "Email Address",
                                placeholder: "Enter your email",
                                text: .init(
                                    get: { store.email },
                                    set: { store.send(.emailChanged($0)) }
                                ),
                                keyboardType: .emailAddress,
                                errorMessage: store.emailError
                            )
                            
                            // Password field
                            AuthTextField(
                                title: "Password",
                                placeholder: "Create a password",
                                text: .init(
                                    get: { store.password },
                                    set: { store.send(.passwordChanged($0)) }
                                ),
                                isSecure: true,
                                errorMessage: store.passwordError
                            )
                            
                            // Confirm password field
                            AuthTextField(
                                title: "Confirm Password",
                                placeholder: "Confirm your password",
                                text: .init(
                                    get: { store.confirmPassword },
                                    set: { store.send(.confirmPasswordChanged($0)) }
                                ),
                                isSecure: true,
                                errorMessage: store.confirmPasswordError
                            )
                            
                            // Error message
                            if let errorMessage = store.errorMessage {
                                Text(errorMessage)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.error)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }
                            
                            // Create account button
                            AuthButton(
                                title: "Create Account",
                                isLoading: store.isLoading,
                                isEnabled: store.isFormValid,
                                style: .primary,
                                action: {
                                    store.send(.createAccountTapped)
                                }
                            )
                            .padding(.top, DesignSystem.Spacing.md)
                            
                            // Sign in link
                            HStack {
                                Text("Already have an account?")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Button("Sign In") {
                                    store.send(.backTapped)
                                }
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.primaryRed)
                            }
                            .padding(.top, DesignSystem.Spacing.sm)
                        }
                        .offset(y: formOffset)
                        .opacity(contentOpacity)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.bottom, DesignSystem.Spacing.xxxl)
                    }
                }
            }
            .onAppear {
                startAnimations()
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.6)) {
            contentOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            formOffset = 0
        }
    }
}

// MARK: - Validation Helpers
private func isValidEmail(_ email: String) -> Bool {
    let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    return email.range(of: emailRegex, options: .regularExpression) != nil
}

private func validatePassword(_ password: String) -> String? {
    if password.count < 8 {
        return "Password must be at least 8 characters long"
    }
    
    if password.count > 128 {
        return "Password is too long (maximum 128 characters)"
    }
    
    let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
    let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
    let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
    let hasSpecial = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
    
    let requirementsMet = [hasUppercase, hasLowercase, hasNumber, hasSpecial].filter { $0 }.count
    
    if requirementsMet < 3 {
        return "Password must contain at least 3 of: uppercase letter, lowercase letter, number, special character"
    }
    
    // Check for common weak passwords
    let weakPasswords = ["123456789", "password", "admin", "test", "guest", "user", "qwerty", "letmein", "welcome", "monkey", "dragon"]
    
    if weakPasswords.contains(password.lowercased()) {
        return "Password is too common. Please choose a more secure password"
    }
    
    return nil
}

// MARK: - API Integration Complete
// The CreateAccountView now uses the real Clear-Meat API through the AuthService dependency

#Preview {
    CreateAccountView(
        store: Store(initialState: CreateAccountFeatureDomain.State()) {
            CreateAccountFeatureDomain()
        }
    )
}