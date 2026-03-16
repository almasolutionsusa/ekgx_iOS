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
    // Optional
    var npi: String        = ""
    var title: String      = ""
    var degree: String     = ""
}

// MARK: - AuthServiceProtocol

protocol AuthServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    func login(email: String, password: String) async throws
    func register(details: SignupDetails) async throws
    func logout() async throws
}

// MARK: - AuthError

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case networkUnavailable
    case tokenExpired
    case serverError(statusCode: Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:   return L10n.Auth.Login.errorInvalidCredentials
        case .emailAlreadyInUse:    return L10n.Auth.Register.errorEmailInUse
        case .networkUnavailable:   return L10n.Auth.Login.errorNetwork
        case .tokenExpired,
             .serverError,
             .unknown:              return L10n.Auth.Login.errorGeneric
        }
    }
}
