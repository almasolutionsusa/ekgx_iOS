//
//  User.swift
//  ECGx
//

import Foundation

// MARK: - User

struct User: Identifiable, Codable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let role: UserRole
    var companyName: String?
    var emr: EMRType?
    var message: String?

    var fullName: String { "\(firstName) \(lastName)" }
}

// MARK: - UserRole

enum UserRole: String, Codable, CaseIterable {
    case physician     = "physician"
    case nurse         = "nurse"
    case technician    = "technician"
    case administrator = "administrator"

    var label: String {
        switch self {
        case .physician:     return "Physician"
        case .nurse:         return "Nurse"
        case .technician:    return "Technician"
        case .administrator: return "Administrator"
        }
    }
}

// MARK: - EMRType

enum EMRType: Int, Codable, CaseIterable {
    case almaSolutionsEMR = 99
    case pointClickCare   = 1
    case drChrono         = 2
    case eClinical        = 3

    var label: String {
        switch self {
        case .pointClickCare:   return "PointClickCare"
        case .drChrono:         return "drChrono"
        case .eClinical:        return "eClinicalWorks"
        case .almaSolutionsEMR: return "AlmaSolutions EMR"
        }
    }
}

// MARK: - Facility

enum Facility: String, CaseIterable {
    case generalHospital    = "General Hospital"
    case universityClinical = "University Clinical Center"
    case heartCenter        = "Heart & Vascular Center"
    case communityHealth    = "Community Health Network"
    case privateClinic      = "Private Clinic"
    case other              = "Other"

    var label: String { rawValue }
}
