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
    let appUuid: String
}

struct PinSetupRequest: Encodable {
    let pin: String
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

// MARK: - Registration

struct AppRegistrationRequest: Encodable {
    let username: String
    let email: String
    let firstName: String?
    let lastName: String?
    let phone: String?
    let title: String        // PHYSICIAN | RN | TECHNICIAN | OTHER
    let password: String     // HIPAA-compliant password
    let appUuid: String
    let npi: String?
    let degree: String?      // MD | DO | NP | PA | RN | ...
}

// MARK: - App Requests

struct AppCheckinRequest: Encodable {
    let uuid: String
    let version: String
}

// MARK: - Orders Requests

struct CreateOrderRequest: Encodable {
    let patientUuid: String
    let appUuid: String
    let examType: String?       // "EKG" | "VITALS" | "ULTRASOUND" — defaults to EKG
    let visibility: String?     // "PRIVATE" | "SHARED" — defaults to SHARED
    let note: String?
}

// MARK: - Support Ticket Request

struct SupportTicketRequest: Encodable {
    let appUuid: String
    let subject: String
    let message: String
    let contactName: String?
    let contactEmail: String?
    let contactPhone: String?
}
