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
    let accessToken: String?
    let refreshToken: String?
    let facilityId: Int64?
    let facilityName: String?
    let loginMethod: String?
    let pinExpiryWarning: String?
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
    /// "OFF" | "FREQ_50HZ" | "FREQ_60HZ"
    let acNotch: String?
    /// "OFF" | "WEAK" | "STRONG"
    let emg: String?
    let minnesotaCode: Bool?
    let autolockSeconds: Int?
}

// MARK: - Pin Status Response Data

/// Per spec: returns an array of PINs (one per facility) with expiry info.
struct PinStatusData: Decodable {
    let pins: [PinStatusEntry]?

    /// Convenience: days until the first (primary) PIN expires.
    /// Nil when the user has no PIN configured.
    var daysUntilExpiry: Int? { pins?.first?.daysUntilExpiry }
}

struct PinStatusEntry: Decodable {
    let daysUntilExpiry: Int?
}

// MARK: - App Checkin Response Data

struct AppCheckinData: Decodable {
    let registered: Bool?
    let assigned: Bool?
    let facilityName: String?
    let organizationName: String?
}
