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
        // Restore session from persisted JWT (cookie is a secondary fallback)
        self.isAuthenticated = TokenStore.shared.accessToken != nil || client.isAuthenticated
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        let body = LoginRequest(username: email, password: password)
        do {
            let response: APIResponse<LoginData> = try await client.post(
                path: APIEndpoints.Auth.login,
                body: body
            )
            persistSession(from: response.data)
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
            persistSession(from: response.data)
        } catch let error as APIError {
            throw mapAPIError(error)
        }
    }

    // MARK: - Session Persistence

    private func persistSession(from data: LoginData?) {
        loginData   = data
        currentUser = data?.user
        TokenStore.shared.accessToken  = data?.accessToken
        TokenStore.shared.refreshToken = data?.refreshToken
        TokenStore.shared.facilityId   = data?.facilityId
        isAuthenticated = true
    }

    // MARK: - Register

    func register(details: SignupDetails) async throws {
        let body = AppRegistrationRequest(
            username:  details.email,
            email:     details.email,
            firstName: details.firstName,
            lastName:  details.lastName,
            password:  details.password,
            appUuid:   UserDefaults.standard.string(forKey: AppCheckinService.Keys.appUuid) ?? ""
        )
        do {
            try await client.postVoid(path: APIEndpoints.Auth.register, body: body)
        } catch let error as APIError {
            throw mapAPIError(error)
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

    // MARK: - Change Password

    func changePassword(oldPassword: String, newPassword: String) async throws {
        try await ensureValidToken()
        let appUuid = UserDefaults.standard.string(forKey: AppCheckinService.Keys.appUuid) ?? ""
        let body = ChangePasswordRequest(oldPassword: oldPassword, newPassword: newPassword, appUuid: appUuid)
        do {
            try await client.postVoid(path: APIEndpoints.Auth.changePassword, body: body)
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
        TokenStore.shared.clear()
        currentUser     = nil
        loginData       = nil
        isAuthenticated = false
    }

    func clearAccessToken() {
        TokenStore.shared.accessToken = nil
    }

    // MARK: - Token Ensure

    func ensureValidToken() async throws {
        let token = TokenStore.shared.accessToken ?? ""
        print("┌─── ensureValidToken ───────────────────────")
        print("│ accessToken present: \(!token.isEmpty)")

        guard token.isEmpty else {
            print("│ ✅ Token already valid — skipping re-auth")
            print("└────────────────────────────────────────────")
            return
        }

        let store          = LocalUserStore.shared
        let storedEmail    = store.email
        let storedUsername = store.username
        // Try email key first, then username key as fallback (handles key-mismatch from older logins)
        let storedPassword = storedEmail.flatMap { store.storedPassword(for: $0) }
                          ?? storedUsername.flatMap { store.storedPassword(for: $0) }
        print("│ storedEmail   : \(storedEmail ?? "nil")")
        print("│ storedUsername: \(storedUsername ?? "nil")")
        print("│ storedPassword: \(storedPassword != nil ? "✅ found" : "❌ nil")")

        let loginId = storedEmail ?? storedUsername
        guard let email = loginId, let password = storedPassword else {
            print("│ ❌ No credentials — throwing sessionExpired")
            print("└────────────────────────────────────────────")
            throw AuthError.sessionExpired
        }

        print("│ 🔄 Silent re-auth for: \(email)")
        print("└────────────────────────────────────────────")

        do {
            try await login(email: email, password: password)
            print("✅ ensureValidToken: silent re-auth succeeded")
        } catch {
            print("❌ ensureValidToken: silent re-auth failed — \(error)")
            throw AuthError.sessionExpired
        }
    }

    // MARK: - Local Session Restore

    /// Rebuilds a minimal in-memory session from cached local user data.
    /// The access token already stored in TokenStore is reused for API calls.
    func restoreLocalSession(username: String, email: String?, facilityId: Int64?, facilityName: String?, firstName: String? = nil, lastName: String? = nil) {
        let user = SessionUser(
            id: 0,
            username: username,
            email: email,
            firstName: firstName,
            lastName: lastName,
            role: nil,
            title: nil,
            organizationId: facilityId,
            createdAt: nil,
            updatedAt: nil
        )
        loginData = LoginData(
            user: user,
            facilities: [],
            messages: [],
            appSettings: nil,
            accessToken: nil,
            refreshToken: nil,
            facilityId: facilityId,
            facilityName: facilityName,
            loginMethod: "local_pin",
            pinExpiryWarning: nil
        )
        currentUser     = user
        isAuthenticated = true
    }

    // MARK: - Private

    private func mapAPIError(_ error: APIError) -> AuthError {
        switch error {
        case .invalidCredentials:   return .invalidCredentials
        case .sessionExpired:       return .sessionExpired
        case .conflict:             return .emailAlreadyInUse
        case .networkUnavailable:   return .networkUnavailable
        case .forbidden:            return .sessionExpired
        case .serverError(let c):   return .serverError(statusCode: c)
        case .backend(let message):
            if message.lowercased().contains("disabled") { return .accountNotVerified }
            return .backend(message: message)
        default:                    return .unknown
        }
    }
}
