//
//  AuthService.swift
//  ECGx
//
//  Production authentication service. Communicates with the ECGx backend
//  over HTTPS using async/await URLSession.
//
//  NOTE: Replace `baseURL` with your actual API endpoint before release.
//

import Foundation

final class AuthService: AuthServiceProtocol {

    // MARK: - Configuration

    private let baseURL = URL(string: "https://api.ecgxpro.com/v1")!
    private let session: URLSession
    private let decoder = JSONDecoder()

    private(set) var isAuthenticated: Bool = false
    private var accessToken: String?

    // MARK: - Init

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - AuthServiceProtocol

    func login(email: String, password: String) async throws {
        let body = LoginRequest(email: email, password: password)
        let response: LoginResponse = try await post(endpoint: APIEndpoints.Auth.login, body: body)
        accessToken = response.accessToken
        isAuthenticated = true
    }

    func register(details: SignupDetails) async throws {
        let body = RegisterRequest(
            firstName:  details.firstName,
            lastName:   details.lastName,
            email:      details.email,
            password:   details.password,
            role:       details.role.rawValue,
            facility:   details.facility.rawValue,
            department: details.department,
            npi:        details.npi.isEmpty ? nil : details.npi,
            title:      details.title.isEmpty ? nil : details.title,
            degree:     details.degree.isEmpty ? nil : details.degree
        )
        let response: LoginResponse = try await post(endpoint: APIEndpoints.Auth.register, body: body)
        accessToken = response.accessToken
        isAuthenticated = true
    }

    func logout() async throws {
        accessToken = nil
        isAuthenticated = false
    }

    // MARK: - Private Helpers

    private func post<Body: Encodable, Response: Decodable>(
        endpoint: String,
        body: Body
    ) async throws -> Response {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw AuthError.unknown
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.unknown
            }
            switch httpResponse.statusCode {
            case 200...299:
                return try decoder.decode(Response.self, from: data)
            case 401:
                throw AuthError.invalidCredentials
            case 409:
                throw AuthError.emailAlreadyInUse
            default:
                throw AuthError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkUnavailable
        }
    }
}
