//
//  AuthServiceProtocol.swift
//  EKGx
//

import Foundation

// MARK: - SignupDetails

struct SignupDetails {
    var firstName: String
    var lastName: String
    var email: String
    var password: String
}

// MARK: - AuthServiceProtocol

protocol AuthServiceProtocol: AnyObject {
    /// True when a valid session exists (cookie-based or mock).
    var isAuthenticated: Bool { get }

    /// The authenticated user's session data (nil when offline/local mode).
    var currentUser: SessionUser? { get }

    /// Full login response including facilities, messages, appSettings.
    var loginData: LoginData? { get }

    /// Email + password login. On success, session cookie is persisted.
    func login(email: String, password: String) async throws

    /// PIN login. On success, session cookie is persisted.
    func pinLogin(pin: String, appUuid: String) async throws

    /// Register a new user account.
    func register(details: SignupDetails) async throws

    /// Check PIN expiry for the authenticated user.
    func pinStatus() async throws -> PinStatusData?

    /// Set up a new 6-digit PIN for the authenticated user.
    func setupPin(pin: String, appUuid: String) async throws

    /// Change existing PIN.
    func changePin(userId: Int64, facilityId: Int64, oldPin: String, newPin: String) async throws

    /// Change the authenticated user's password.
    func changePassword(oldPassword: String, newPassword: String) async throws

    /// Send a forgot-password email.
    func forgotPassword(email: String) async throws

    /// Log out and clear session.
    func logout() async throws

    /// Restore a minimal in-memory session from locally stored user data (no network call).
    /// Used after a successful local PIN validation to make loginData available app-wide.
    func restoreLocalSession(username: String, email: String?, facilityId: Int64?, facilityName: String?, firstName: String?, lastName: String?)

    /// Clears the stored access token so the next API call triggers a fresh authentication.
    func clearAccessToken()

    /// Ensures a valid access token is present in TokenStore.
    /// If the token is missing (e.g. after local login), silently re-authenticates with stored credentials.
    /// Throws AuthError.sessionExpired if credentials are unavailable.
    func ensureValidToken() async throws
}

// Default overload so existing call sites don't need to pass firstName/lastName.
extension AuthServiceProtocol {
    func restoreLocalSession(username: String, email: String?, facilityId: Int64?, facilityName: String?) {
        restoreLocalSession(username: username, email: email, facilityId: facilityId, facilityName: facilityName, firstName: nil, lastName: nil)
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case networkUnavailable
    case sessionExpired
    case accountNotVerified
    case serverError(statusCode: Int)
    case backend(message: String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:   return L10n.Auth.Login.errorInvalidCredentials
        case .emailAlreadyInUse:    return L10n.Auth.Register.errorEmailInUse
        case .networkUnavailable:   return L10n.Auth.Login.errorNetwork
        case .sessionExpired:       return L10n.Auth.Login.errorSessionExpired
        case .accountNotVerified:   return L10n.Auth.Login.errorAccountNotVerified
        case .backend(let message): return message
        case .serverError,
             .unknown:              return L10n.Auth.Login.errorGeneric
        }
    }
}
