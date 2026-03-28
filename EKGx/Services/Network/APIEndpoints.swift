//
//  APIEndpoints.swift
//  EKGx
//
//  Single source of truth for all API path strings.
//  Always reference these constants — never hardcode paths.
//

import Foundation

enum APIEndpoints {

    // MARK: - Auth

    enum Auth {
        static let login          = "/api/auth/login"
        static let pinLogin       = "/api/auth/pin-login"
        static let forgotPassword = "/api/auth/forgot-password"
        static let pinSetup       = "/api/auth/pin/setup"
        static let pinChange      = "/api/auth/pin/change"
        static let pinStatus      = "/api/auth/pin/status"
    }

    // MARK: - App

    enum App {
        static let checkin = "/api/app/checkin"
    }

    // MARK: - EKG

    enum EKG {
        static let results = "/api/ekg/results"
    }
}
