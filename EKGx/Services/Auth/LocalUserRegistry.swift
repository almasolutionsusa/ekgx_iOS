//
//  LocalUserRegistry.swift
//  EKGx
//
//  Persists a table of every user who has successfully API-logged-in on this
//  device. Each record is keyed by username. PIN hashes live separately in
//  LocalUserStore (Keychain) — this file only stores profile data.
//

import Foundation

// MARK: - LocalUserRecord

struct LocalUserRecord: Codable, Identifiable, Equatable {

    let username: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let facilityId: Int64?
    let facilityName: String?

    var id: String { username }

    var displayName: String {
        let full = [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? (email ?? username) : full
    }

    var initials: String {
        let f = firstName?.first.map { String($0).uppercased() } ?? ""
        let l = lastName?.first.map  { String($0).uppercased() } ?? ""
        let combined = f + l
        return combined.isEmpty ? String(username.prefix(2).uppercased()) : combined
    }

    var hasPin: Bool {
        LocalUserStore.shared.hasPin(forUser: username)
    }
}

// MARK: - LocalUserRegistry

final class LocalUserRegistry {

    static let shared = LocalUserRegistry()
    private init() {}

    private let storageKey = "ekgx.localUsers.v1"

    // MARK: - Access

    var all: [LocalUserRecord] {
        get {
            guard let data = UserDefaults.standard.data(forKey: storageKey),
                  let decoded = try? JSONDecoder().decode([LocalUserRecord].self, from: data)
            else { return [] }
            return decoded
        }
        set {
            UserDefaults.standard.set(try? JSONEncoder().encode(newValue), forKey: storageKey)
        }
    }

    // MARK: - Mutations

    /// Inserts or updates the record for a user. Most-recently-logged-in user goes to the front.
    func upsert(_ record: LocalUserRecord) {
        var current = all.filter { $0.username != record.username }
        current.insert(record, at: 0)
        all = current
    }

    func remove(username: String) {
        all = all.filter { $0.username != username }
    }
}
