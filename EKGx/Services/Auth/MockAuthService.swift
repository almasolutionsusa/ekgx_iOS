//
//  MockAuthService.swift
//  EKGx
//
//  In-memory stub used for SwiftUI Previews and unit tests.
//

import Foundation

final class MockAuthService: AuthServiceProtocol {

    enum Scenario {
        case success
        case invalidCredentials
        case networkUnavailable
    }

    var scenario: Scenario = .success
    private(set) var isAuthenticated: Bool = false

    func login(email: String, password: String) async throws {
        try await Task.sleep(nanoseconds: 800_000_000)
        switch scenario {
        case .success:             isAuthenticated = true
        case .invalidCredentials:  throw AuthError.invalidCredentials
        case .networkUnavailable:  throw AuthError.networkUnavailable
        }
    }

    func register(details: SignupDetails) async throws {
        try await Task.sleep(nanoseconds: 800_000_000)
        if scenario == .success {
            isAuthenticated = true
        } else {
            throw AuthError.invalidCredentials
        }
    }

    func logout() async throws {
        isAuthenticated = false
    }
}
