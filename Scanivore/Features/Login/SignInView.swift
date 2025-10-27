
import SwiftUI
import ComposableArchitecture

// MARK: - Sign In Feature Domain
@Reducer
struct SignInFeatureDomain {
    @ObservableState
    struct State: Equatable {
        var email = ""
        var password = ""
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
        case signInTapped
        case forgotPasswordTapped
        case backTapped
        case clearError
        case validateEmail
        case validatePassword
        case signInResponse(TaskResult<Bool>)
        
        enum Delegate: Equatable {
            case signedIn
            case navigateBack
            case navigateToForgotPassword
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
                    try await Task.sleep(nanoseconds: 800_000_000) // 800ms debounce
                    await send(.validateEmail)
                }
                
            case let .passwordChanged(password):
                state.password = password
                state.passwordError = nil
                return .run { send in
                    try await Task.sleep(nanoseconds: 800_000_000)
                    await send(.validatePassword)
                }
                
            case .validateEmail:
                if !state.email.isEmpty && state.email.count > 3 && !isValidEmail(state.email) {
                    state.emailError = "Please enter a valid email address"
                }
                return .none
                
            case .validatePassword:
               
                return .none
                
            case .signInTapped:
                guard state.isFormValid else { return .none }
                
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { [email = state.email, password = state.password] send in
                    await send(.signInResponse(
                        await TaskResult {
                            @Dependency(\.authGateway) var authGateway
                            
                            
                            _ = try await authGateway.login(email, password)
                            return true
                        }
                    ))
                }
                
            case let .signInResponse(.success(success)):
                state.isLoading = false
                if success {
                    return .run { send in
                        
                        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        await send(.clearError)
                        await send(.delegate(.signedIn))
                    }
                } else {
                    state.errorMessage = "Invalid email or password. Please try again."
                    return .none
                }
                
            case let .signInResponse(.failure(error)):
                state.isLoading = false
                
                if let apiError = error as? APIError {
                    switch apiError.statusCode {
                    case 401:
                        if apiError.detail.lowercased().contains("user not found") || 
                           apiError.detail.lowercased().contains("does not exist") {
                            state.errorMessage = "No account found with this email. Please check your email or create a new account."
                        } else if apiError.detail.lowercased().contains("password") {
                            state.errorMessage = "Incorrect password. Please try again or reset your password."
                        } else {
                            state.errorMessage = "Invalid email or password. Please check your credentials and try again."
                        }
                    case 400:
                        state.errorMessage = apiError.detail
                    case 404:
                        state.errorMessage = "No account found with this email. Please check your email or create a new account."
                    default:
                        state.errorMessage = "Sign in failed: \(apiError.detail)"
                    }
                } else {
                    state.errorMessage = "Sign in failed: \(error.localizedDescription)"
                }
                return .none
                
            case .forgotPasswordTapped:
                return .run { send in
                    await send(.delegate(.navigateToForgotPassword))
                }
                
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

struct SignInView: View {
    let store: StoreOf<SignInFeatureDomain>
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
                            title: "Welcome Back",
                            subtitle: "Sign in to your account to continue using Scanivore",
                            showBackButton: true,
                            onBackTapped: {
                                store.send(.backTapped)
                            }
                        )
                        .padding(.top, DesignSystem.Spacing.xl)
                        
                        VStack(spacing: DesignSystem.Spacing.lg) {
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
                                placeholder: "Enter your password",
                                text: .init(
                                    get: { store.password },
                                    set: { store.send(.passwordChanged($0)) }
                                ),
                                isSecure: true,
                                errorMessage: store.passwordError
                            )
                            
                            HStack {
                                Spacer()
                                
                                Button("Forgot Password?") {
                                    store.send(.forgotPasswordTapped)
                                }
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.primaryRed)
                            }
                            
                            if let errorMessage = store.errorMessage {
                                Text(errorMessage)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(errorMessage.contains("✅") ? .green : DesignSystem.Colors.error)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }
                            
                            AuthButton(
                                title: "Sign In",
                                isLoading: store.isLoading,
                                isEnabled: store.isFormValid,
                                style: .primary,
                                action: {
                                    store.send(.signInTapped)
                                }
                            )
                            .padding(.top, DesignSystem.Spacing.md)
                            
                            HStack {
                                Text("Don't have an account?")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Button("Create Account") {
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

// MARK: - API Integration Complete
 
#Preview {
    SignInView(
        store: Store(initialState: SignInFeatureDomain.State()) {
            SignInFeatureDomain()
        }
    )
}
