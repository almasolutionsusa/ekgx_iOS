//
//  LoginRequest.swift
//  ECGx
//

import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let role: String
    let facility: String
    let department: String
    let npi: String?
    let title: String?
    let degree: String?
}
