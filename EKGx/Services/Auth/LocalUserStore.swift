//
//  LocalUserStore.swift
//  EKGx
//
//  Persists the logged-in user's profile and a hashed PIN in the iOS Keychain.
//  Keychain items are encrypted by the OS, excluded from iCloud/iTunes backups,
//  and scoped to this app's bundle identifier.
//
//  PIN keys are per-user: each username gets its own Keychain entry so that
//  a PIN set by user A cannot be used to log in as user B.
//

import Foundation
import CryptoKit
import Security

final class LocalUserStore {

    static let shared = LocalUserStore()

    private enum Key: String, CaseIterable {
        case username     = "ekgx.user.username"
        case email        = "ekgx.user.email"
        case facilityId   = "ekgx.user.facilityId"
        case facilityName = "ekgx.user.facilityName"
        case firstName    = "ekgx.user.firstName"
        case lastName     = "ekgx.user.lastName"
        // PIN is NOT in this enum — it uses a per-user dynamic key.
    }

    // MARK: - Save User

    /// Called after a successful API login. Marks the account as verified.
    func saveUser(username: String, email: String?, facilityId: Int64?, facilityName: String?,
                  firstName: String? = nil, lastName: String? = nil) {
        set(username,                       for: .username)
        set(email,                          for: .email)
        set(facilityName,                   for: .facilityName)
        set(facilityId.map { String($0) },  for: .facilityId)
        set(firstName,                      for: .firstName)
        set(lastName,                       for: .lastName)
        if let email { markVerified(email: email) }
    }

    /// Called after registration succeeds. Stores credentials locally but marks the account
    /// as unverified so local login is blocked until the user confirms their email via API.
    func saveRegisteredUser(email: String, password: String) {
        setRaw("0", forAccount: verifiedAccount(email))
        setRaw(sha256Hex(password), forAccount: passwordHashAccount(email))
    }

    // MARK: - Local Email+Password Login

    /// Returns true when the stored credentials match AND the account has been verified.
    func canLoginLocally(email: String, password: String) -> Bool {
        isVerified(email: email) && validatePassword(password, for: email)
    }

    func isVerified(email: String) -> Bool {
        getRaw(forAccount: verifiedAccount(email)) == "1"
    }

    func markVerified(email: String) {
        setRaw("1", forAccount: verifiedAccount(email))
    }

    func savePasswordHash(_ password: String, for email: String) {
        setRaw(sha256Hex(password), forAccount: passwordHashAccount(email))
    }

    private func validatePassword(_ password: String, for email: String) -> Bool {
        guard let stored = getRaw(forAccount: passwordHashAccount(email)) else { return false }
        return sha256Hex(password) == stored
    }

    // MARK: - Stored Password (for silent re-authentication with the API)

    /// Stores the user's password as-is in the Keychain (Keychain encrypts at rest).
    /// Used only to silently refresh the access token when it expires.
    func savePassword(_ password: String, for email: String) {
        setRaw(password, forAccount: passwordAccount(email))
    }

    func storedPassword(for email: String) -> String? {
        getRaw(forAccount: passwordAccount(email))
    }

    /// Saves the plaintext password under every key that might later be used to look it up:
    /// the typed login input, the stored email (from API response), and the stored username.
    /// This prevents key-mismatch failures when the user logs in with a username instead of email.
    func savePasswordUnderAllKeys(_ password: String, typedInput: String) {
        savePassword(password, for: typedInput)
        if let email = self.email, email != typedInput {
            savePassword(password, for: email)
        }
        if let username = self.username, username != typedInput {
            savePassword(password, for: username)
        }
    }

    private func verifiedAccount(_ email: String) -> String     { "ekgx.user.isVerified.\(email)" }
    private func passwordHashAccount(_ email: String) -> String { "ekgx.user.passwordHash.\(email)" }
    private func passwordAccount(_ email: String) -> String     { "ekgx.user.password.\(email)" }

    // MARK: - PIN (per-user)

    /// Saves a SHA-256 hashed PIN for the given user.
    /// Pass `forUser:` explicitly from authenticated contexts; omit to fall back to the last API-logged-in user.
    func savePin(_ pin: String, forUser explicitUsername: String? = nil) {
        guard let user = explicitUsername ?? username else { return }
        setRaw(sha256Hex(pin), forAccount: pinAccount(user))
    }

    /// Returns true when the PIN matches the hash stored for the given user.
    func validatePin(_ pin: String, forUser explicitUsername: String? = nil) -> Bool {
        guard let user = explicitUsername ?? username else { return false }
        guard let stored = getRaw(forAccount: pinAccount(user)) else { return false }
        return sha256Hex(pin) == stored
    }

    /// True if the given user has a local PIN set.
    func hasPin(forUser explicitUsername: String? = nil) -> Bool {
        guard let user = explicitUsername ?? username else { return false }
        return getRaw(forAccount: pinAccount(user)) != nil
    }

    /// Convenience computed property — uses the last API-logged-in username (for login screen checks).
    var hasPin: Bool { hasPin(forUser: nil) }

    func clearPin(forUser explicitUsername: String? = nil) {
        guard let user = explicitUsername ?? username else { return }
        deleteRaw(forAccount: pinAccount(user))
    }

    var hasSavedUser: Bool { read(.username) != nil }

    // MARK: - Stored values

    var username: String?     { read(.username) }
    var email: String?        { read(.email) }
    var facilityName: String? { read(.facilityName) }
    var facilityId: Int64?    { read(.facilityId).flatMap { Int64($0) } }
    var firstName: String?    { read(.firstName) }
    var lastName: String?     { read(.lastName) }

    // MARK: - Clear

    func clearAll() {
        if let username { deleteRaw(forAccount: pinAccount(username)) }
        if let email {
            deleteRaw(forAccount: verifiedAccount(email))
            deleteRaw(forAccount: passwordHashAccount(email))
            deleteRaw(forAccount: passwordAccount(email))
        }
        Key.allCases.forEach { delete($0) }
    }

    // MARK: - Helpers

    private func pinAccount(_ username: String) -> String {
        "ekgx.user.pinHash.\(username)"
    }

    private func sha256Hex(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Keychain primitives (enum-keyed)

    private func set(_ value: String?, for key: Key) {
        guard let value else { delete(key); return }
        setRaw(value, forAccount: key.rawValue)
    }

    private func read(_ key: Key) -> String? {
        getRaw(forAccount: key.rawValue)
    }

    private func delete(_ key: Key) {
        deleteRaw(forAccount: key.rawValue)
    }

    // MARK: - Keychain primitives (raw account string)

    private func setRaw(_ value: String, forAccount account: String) {
        let data = Data(value.utf8)
        var query = baseQuery(account: account)

        if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
            let update: [CFString: Any] = [kSecValueData: data]
            SecItemUpdate(query as CFDictionary, update as CFDictionary)
        } else {
            query[kSecValueData] = data
            query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    private func getRaw(forAccount account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteRaw(forAccount account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

    private func baseQuery(account: String) -> [CFString: Any] {
        [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Bundle.main.bundleIdentifier ?? "com.ekgx.app",
            kSecAttrAccount: account
        ]
    }
}
