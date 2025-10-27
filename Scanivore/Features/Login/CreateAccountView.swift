
import SwiftUI
import ComposableArchitecture

// MARK: - Create Account Feature Domain
@Reducer
struct CreateAccountFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var email = ""
        var password = ""
        var fullName = ""
        var isLoading = false
        var errorMessage: String?
        
         var emailError: String?
        var passwordError: String?
        
        var isFormValid: Bool {
            !email.isEmpty &&
            !password.isEmpty &&
            emailError == nil &&
            passwordError == nil
        }
    }
    
    enum Action: Equatable {
        case emailChanged(String)
        case passwordChanged(String)
        case fullNameChanged(String)
        case createAccountTapped
        case backTapped
        case signInTapped
        case clearError
        case validateEmail
        case validatePassword
        case createAccountResponse(TaskResult<Bool>)
        
        enum Delegate: Equatable {
            case accountCreated
            case navigateBack
            case navigateToSignIn
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
                    try await Task.sleep(nanoseconds: 800_000_000)
                    await send(.validateEmail)
                }
                
            case let .passwordChanged(password):
                state.password = password
                state.passwordError = nil
                return .run { send in
                    try await Task.sleep(nanoseconds: 800_000_000)
                    await send(.validatePassword)
                }
                
            case let .fullNameChanged(fullName):
                state.fullName = fullName
                return .none
                
            case .validateEmail:
                if !state.email.isEmpty && state.email.count > 3 && !isValidEmail(state.email) {
                    state.emailError = "Please enter a valid email address"
                }
                return .none
                
            case .validatePassword:
                if !state.password.isEmpty && state.password.count >= 6 {
                    let passwordValidation = validatePassword(state.password)
                    if let error = passwordValidation {
                        state.passwordError = error
                    }
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
                
            case .signInTapped:
                return .run { send in
                    await send(.delegate(.navigateToSignIn))
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
                        AuthHeader(
                            title: "Create Account",
                            subtitle: "Join Scanivore to start scanning and get healthier food choices",
                            showBackButton: true,
                            onBackTapped: {
                                store.send(.backTapped)
                            }
                        )
                        .padding(.top, DesignSystem.Spacing.xl)
                        
                        VStack(spacing: DesignSystem.Spacing.lg) {
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
                            
                             if let errorMessage = store.errorMessage {
                                Text(errorMessage)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.error)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }
                            
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
                            
                            
                            HStack {
                                Text("Already have an account?")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Button("Sign In") {
                                    store.send(.signInTapped)
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
    let emailRegex = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
    return email.range(of: emailRegex, options: .regularExpression) != nil
}

private func validatePassword(_ password: String) -> String? {
    if password.count < 8 {
        return "Password must be at least 8 characters"
    }
    
    if password.count > 128 {
        return "Password is too long"
    }
    
    let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
    let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
    
    if !hasLetter && !hasNumber {
        return "Password must contain at least one letter or number"
    }
    
    let veryWeakPasswords = ["password", "12345678", "password123"]
    
    if veryWeakPasswords.contains(password.lowercased()) {
        return "This password is too common"
    }
    
    return nil
}

// MARK: - API Integration Complete

#Preview {
    CreateAccountView(
        store: Store(initialState: CreateAccountFeatureDomain.State()) {
            CreateAccountFeatureDomain()
        }
    )
}
