//
//  AuthServiceProtocol.swift
//  EKGx
//

import Foundation

// MARK: - SignupDetails

struct SignupDetails {
    var firstName: String
    var lastName: String
    var facility: Facility
    var role: UserRole
    var department: String
    var email: String
    var confirmEmail: String
    var password: String
    var confirmPassword: String
    var npi: String    = ""
    var title: String  = ""
    var degree: String = ""
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
    func pinLogin(pin: String, deviceUuid: String, appUuid: String) async throws

    /// Register a new user account.
    func register(details: SignupDetails) async throws

    /// Check whether a PIN has been set up for a given userId.
    func pinStatus(userId: Int64) async throws -> Bool

    /// Set up PIN for first time.
    func setupPin(userId: Int64, facilityId: Int64, pin: String, deviceUuid: String, appUuid: String) async throws

    /// Change existing PIN.
    func changePin(userId: Int64, facilityId: Int64, oldPin: String, newPin: String) async throws

    /// Send a forgot-password email.
    func forgotPassword(email: String) async throws

    /// Log out and clear session.
    func logout() async throws
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case networkUnavailable
    case sessionExpired
    case serverError(statusCode: Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:  return L10n.Auth.Login.errorInvalidCredentials
        case .emailAlreadyInUse:   return L10n.Auth.Register.errorEmailInUse
        case .networkUnavailable:  return L10n.Auth.Login.errorNetwork
        case .sessionExpired,
             .serverError,
             .unknown:             return L10n.Auth.Login.errorGeneric
        }
    }
}
