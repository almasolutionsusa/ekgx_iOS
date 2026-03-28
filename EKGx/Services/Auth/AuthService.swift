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

    func pinLogin(pin: String, deviceUuid: String, appUuid: String) async throws {
        let body = PinLoginRequest(pin: pin, deviceUuid: deviceUuid, appUuid: appUuid)
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

    // MARK: - Register (not in current spec — kept for future)

    func register(details: SignupDetails) async throws {
        // Registration is currently web-only per spec.
        // When endpoint is added, implement here.
        throw AuthError.unknown
    }

    // MARK: - PIN Management

    func pinStatus(userId: Int64) async throws -> Bool {
        do {
            let response: APIResponse<PinStatusData> = try await client.get(
                path: APIEndpoints.Auth.pinStatus,
                query: ["userId": "\(userId)"]
            )
            return response.data?.hasPin ?? false
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    func setupPin(userId: Int64, facilityId: Int64, pin: String, deviceUuid: String, appUuid: String) async throws {
        let body = PinSetupRequest(
            userId: userId,
            facilityId: facilityId,
            pin: pin,
            deviceUuid: deviceUuid,
            appUuid: appUuid
        )
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
