//
//  APIEndpoints.swift
//  EKGx
//
//  Single source of truth for all API endpoint paths.
//  Reference these constants in every service — never hardcode path strings.
//

import Foundation

enum APIEndpoints {

    // MARK: - Auth

    enum Auth {
        static let login    = "/auth/login"
        static let register = "/auth/register"
        static let logout   = "/auth/logout"
        static let refresh  = "/auth/refresh"
    }

    // MARK: - Patients

    enum Patients {
        static let list   = "/patients"
        static let detail = "/patients/{id}"
    }

    // MARK: - ECG

    enum ECG {
        static let recordings = "/ecg/recordings"
        static let upload     = "/ecg/upload"
    }

    // MARK: - Reports

    enum Reports {
        static let list     = "/reports"
        static let generate = "/reports/generate"
    }
}
