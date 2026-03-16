//
//  LoginResponse.swift
//  EKGx
//

import Foundation

struct LoginResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
}
