//
//  AuthService.swift
//  EKGx
//
//  Production authentication service.
//  Uses APIClient (cookie-based session) to communicate with the EKGx backend.
//

import Foundation

final class AuthService: AuthServiceProtocol {

    // MARK: - State

    private(set) var isAuthenticated: Bool = false
    private(set) var currentUser: SessionUser? = nil
    private(set) var loginData: LoginData? = nil

    private let client: APIClient

    // MARK: - Init

    init(client: APIClient = .shared) {
        self.client = client
        // Restore session from persisted cookie if still valid
        self.isAuthenticated = client.isAuthenticated
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        let body = LoginRequest(username: email, password: password)
        do {
            let response: APIResponse<LoginData> = try await client.post(
                path: APIEndpoints.Auth.login,
                body: body
            )
            loginData       = response.data
            currentUser     = response.data?.user
            isAuthenticated = true
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    // MARK: - PIN Login

    func pinLogin(pin: String, appUuid: String) async throws {
        let body = PinLoginRequest(pin: pin, appUuid: appUuid)
        do {
            let response: APIResponse<LoginData> = try await client.post(
                path: APIEndpoints.Auth.pinLogin,
                body: body
            )
            loginData       = response.data
            currentUser     = response.data?.user
            isAuthenticated = true
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    // MARK: - Register

    func register(details: SignupDetails) async throws {
        let body = AppRegistrationRequest(
            username:  details.email,                  // server expects unique username
            email:     details.email,
            firstName: details.firstName,
            lastName:  details.lastName,
            phone:     nil,
            title:     mapRoleToTitle(details.role),
            appUuid:   UserDefaults.standard.string(forKey: AppCheckinService.Keys.appUuid) ?? "",
            npi:       details.npi.isEmpty ? nil : details.npi,
            degree:    details.degree.isEmpty ? nil : details.degree.uppercased()
        )
        do {
            try await client.postVoid(path: APIEndpoints.Auth.register, body: body)
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    private func mapRoleToTitle(_ role: UserRole) -> String {
        switch role {
        case .physician:     return "PHYSICIAN"
        case .nurse:         return "RN"
        case .technician:    return "TECHNICIAN"
        case .administrator: return "OTHER"
        }
    }

    // MARK: - PIN Management

    func pinStatus() async throws -> PinStatusData? {
        do {
            let response: APIResponse<PinStatusData> = try await client.get(
                path: APIEndpoints.Auth.pinStatus
            )
            return response.data
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    func setupPin(pin: String, appUuid: String) async throws {
        let body = PinSetupRequest(pin: pin, appUuid: appUuid)
        do {
            try await client.postVoid(path: APIEndpoints.Auth.pinSetup, body: body)
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    func changePin(userId: Int64, facilityId: Int64, oldPin: String, newPin: String) async throws {
        let body = PinChangeRequest(userId: userId, facilityId: facilityId, oldPin: oldPin, newPin: newPin)
        do {
            try await client.postVoid(path: APIEndpoints.Auth.pinChange, body: body)
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    // MARK: - Forgot Password

    func forgotPassword(email: String) async throws {
        let body = ForgotPasswordRequest(email: email)
        do {
            try await client.postVoid(path: APIEndpoints.Auth.forgotPassword, body: body)
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    // MARK: - Logout

    func logout() async throws {
        client.clearSession()
        currentUser     = nil
        loginData       = nil
        isAuthenticated = false
    }

    // MARK: - Private

    private func mapAPIError(_ error: APIError) -> AuthError {
        switch error {
        case .invalidCredentials:  return .invalidCredentials
        case .conflict:            return .emailAlreadyInUse
        case .networkUnavailable:  return .networkUnavailable
        case .forbidden:           return .sessionExpired
        case .serverError(let c):  return .serverError(statusCode: c)
        default:                   return .unknown
        }
    }
}
