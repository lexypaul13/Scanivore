import Foundation
import Alamofire
import Dependencies
import ComposableArchitecture

// MARK: - Session Configuration
private let secureSession: Session = {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = APIConfiguration.timeout
    configuration.timeoutIntervalForResource = APIConfiguration.healthAssessmentTimeout
    return Session(configuration: configuration)
}()

// MARK: - User Gateway
@DependencyClient
public struct UserGateway: Sendable {
    public var updatePreferences: @Sendable (UserPreferences) async throws -> User
    public var getProfile: @Sendable () async throws -> User
}

// MARK: - Dependency Key Conformance
extension UserGateway: DependencyKey {
    public static let liveValue: Self = .init(
        updatePreferences: { preferences in
            let headers = try await createAuthHeaders()
            
            return try await secureSession.request(
                "\(APIConfiguration.baseURL)/api/v1/users/me",
                method: .put,
                parameters: ["preferences": preferences],
                encoder: JSONParameterEncoder.default,
                headers: headers
            )
            .validate()
            .serializingDecodable(User.self)
            .value
        },
        
        getProfile: {
            let headers = try await createAuthHeaders()
            
            return try await secureSession.request(
                "\(APIConfiguration.baseURL)/api/v1/users/me",
                method: .get,
                headers: headers
            )
            .validate()
            .serializingDecodable(User.self)
            .value
        }
    )
    
    public static let testValue = Self()
    
    public static let previewValue: Self = .init(
        updatePreferences: { _ in .mock },
        getProfile: { .mock }
    )
}



// MARK: - Dependency Extension
extension DependencyValues {
    public var userGateway: UserGateway {
        get { self[UserGateway.self] }
        set { self[UserGateway.self] = newValue }
    }
}

// MARK: - Helper Functions
@Sendable
private func createAuthHeaders() async throws -> HTTPHeaders {
    var headers = HTTPHeaders()
    headers.add(.contentType("application/json"))
    
    if let token = try await TokenManager.shared.getToken() {
        headers.add(.authorization(bearerToken: token))
    }
    
    return headers
}

// MARK: - Preference Conversion
extension OnboardingPreferences {
    func toAPIPreferences() -> UserPreferences {
        UserPreferences(
            nutritionFocus: nil, // Not collected in onboarding
            avoidPreservatives: avoidPreservatives,
            meatPreferences: preferredMeatTypes.map { $0.rawValue },
            prefer_no_preservatives: avoidPreservatives,
            prefer_antibiotic_free: antibioticFree,
            prefer_organic_or_grass_fed: preferOrganic,
            prefer_no_added_sugars: avoidSugars,
            prefer_no_flavor_enhancers: avoidMSG,
            prefer_reduced_sodium: lowerSodium,
            preferred_meat_types: preferredMeatTypes.map { $0.rawValue }
        )
    }
}
