//
//  TokenStore.swift
//  EKGx
//
//  Persists the JWT access + refresh tokens returned by /api/auth/login and
//  /api/auth/pin-login. Backed by UserDefaults for now — switch to Keychain
//  before production for HIPAA compliance.
//

import Foundation

final class TokenStore {

    static let shared = TokenStore()

    private enum Keys {
        static let accessToken    = "ekgx.accessToken"
        static let refreshToken   = "ekgx.refreshToken"
        static let facilityId     = "ekgx.sessionFacilityId"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Access

    var accessToken: String? {
        get { defaults.string(forKey: Keys.accessToken) }
        set { defaults.set(newValue, forKey: Keys.accessToken) }
    }

    var refreshToken: String? {
        get { defaults.string(forKey: Keys.refreshToken) }
        set { defaults.set(newValue, forKey: Keys.refreshToken) }
    }

    var facilityId: Int64? {
        get {
            let v = defaults.integer(forKey: Keys.facilityId)
            return v == 0 ? nil : Int64(v)
        }
        set {
            if let v = newValue {
                defaults.set(Int(v), forKey: Keys.facilityId)
            } else {
                defaults.removeObject(forKey: Keys.facilityId)
            }
        }
    }

    func clear() {
        defaults.removeObject(forKey: Keys.accessToken)
        defaults.removeObject(forKey: Keys.refreshToken)
        defaults.removeObject(forKey: Keys.facilityId)
    }
}
