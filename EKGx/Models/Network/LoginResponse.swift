//
//  LoginResponse.swift
//  EKGx
//

import Foundation

// MARK: - Login Response Data

struct LoginData: Decodable {
    let user: SessionUser
    let facilities: [SessionFacility]
    let messages: [SessionMessage]
    let appSettings: SessionAppSettings?
}

// MARK: - Session User

struct SessionUser: Decodable {
    let id: Int64
    let username: String
    let email: String?
    let role: String?
    let title: String?
    let organizationId: Int64?
    let createdAt: String?
    let updatedAt: String?

    var displayName: String { username }
}

// MARK: - Facility

struct SessionFacility: Decodable {
    let id: Int64
    let name: String
}

// MARK: - Message

struct SessionMessage: Decodable {
    let id: Int64
    let subject: String
    let body: String
    let targetType: String?
    let read: Bool
    let createdAt: String?
}

// MARK: - App Settings

struct SessionAppSettings: Decodable {
    let lowpass: Double?
    let highpass: Double?
    let acNotch: Bool?
    let emg: String?
    let minnesotaCode: Bool?
    let autolockSeconds: Int?
}

// MARK: - Pin Status Response Data

/// Simplified per spec: `daysUntilExpiry` per facility PIN.
struct PinStatusData: Decodable {
    let daysUntilExpiry: Int?
}

// MARK: - App Checkin Response Data

struct AppCheckinData: Decodable {
    let registered: Bool?
    let assigned: Bool?
    let facility: String?
    let organization: String?
}
