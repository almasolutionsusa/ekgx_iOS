//
//  LoginRequest.swift
//  EKGx
//

import Foundation

// MARK: - Auth Requests

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct PinLoginRequest: Encodable {
    let pin: String
    let deviceUuid: String
    let appUuid: String
}

struct PinSetupRequest: Encodable {
    let userId: Int64
    let facilityId: Int64
    let pin: String
    let deviceUuid: String
    let appUuid: String
}

struct PinChangeRequest: Encodable {
    let userId: Int64
    let facilityId: Int64
    let oldPin: String
    let newPin: String
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}

// MARK: - App Requests

struct AppCheckinRequest: Encodable {
    let uuid: String
    let version: String
}
