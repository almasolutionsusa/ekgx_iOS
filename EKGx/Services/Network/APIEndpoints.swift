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
        static let register       = "/api/auth/register"
        static let pinLogin       = "/api/auth/pin-login"
        static let forgotPassword = "/api/auth/forgot-password"
        static let pinSetup        = "/api/auth/pin/setup"
        static let pinChange       = "/api/auth/pin/change"
        static let pinStatus       = "/api/auth/pin/status"
        static let changePassword  = "/api/auth/change-password"
    }

    // MARK: - App

    enum App {
        static let checkin            = "/api/app/checkin"
        static let info               = "/api/app/info"
        static let faq                = "/api/app/faq"
        static let terms              = "/api/app/terms"
        static let privacyPolicy      = "/api/app/privacy-policy"
        static let indicationsForUse  = "/api/app/indications-for-use"
        static let supportTicket      = "/api/app/support-ticket"
    }

    // MARK: - Orders

    enum Orders {
        static let create   = "/api/orders"
        static let list     = "/api/orders/app"
        static func complete(_ id: Int64) -> String { "/api/orders/\(id)/complete" }
        static func cancel(_ id: Int64)   -> String { "/api/orders/\(id)/cancel" }
    }

    // MARK: - EKG

    enum EKG {
        static let upload = "/api/ekg/upload"
    }

    // MARK: - Vitals

    enum Vitals {
        static let upload = "/api/observations"
    }

    // MARK: - Patients

    enum Patients {
        static let create = "/api/patients"
        static let search = "/api/patients/search"
    }
}
