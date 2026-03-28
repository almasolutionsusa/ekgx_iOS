//
//  AppCheckinService.swift
//  EKGx
//
//  Registers / checks-in this app installation with the server on every launch.
//  The server returns appUuid and deviceUuid which are required for ECG uploads.
//
//  Per spec: POST /api/app/checkin — permitAll, no auth required.
//

import Foundation
import UIKit

final class AppCheckinService {

    // MARK: - Stored identifiers

    enum Keys {
        static let appUuid    = "ekgx.appUuid"
        static let deviceUuid = "ekgx.deviceUuid"
    }

    private let client: APIClient
    private let defaults: UserDefaults

    // MARK: - Cached identifiers (set after checkin)

    private(set) var appUuid: String    = ""
    private(set) var deviceUuid: String = ""

    // MARK: - Init

    init(client: APIClient = .shared, defaults: UserDefaults = .standard) {
        self.client   = client
        self.defaults = defaults
        // appUuid is a stable install-level UUID (persisted in UserDefaults)
        appUuid    = defaults.string(forKey: Keys.appUuid) ?? ""
        // deviceUuid is always the hardware vendor identifier
        deviceUuid = UIDevice.current.identifierForVendor?.uuidString ?? ""
        defaults.set(deviceUuid, forKey: Keys.deviceUuid)
    }

    // MARK: - Checkin

    /// Call once on app launch (or after first network reachability).
    /// Safe to call multiple times — server is idempotent on the same UUID.
    @discardableResult
    func checkin() async -> AppCheckinData? {
        let uuid    = persistentInstallUUID()
        let version = appVersion()
        let body    = AppCheckinRequest(uuid: uuid, version: version)

        do {
            let response: APIResponse<AppCheckinData> = try await client.post(
                path: APIEndpoints.App.checkin,
                body: body
            )
            return response.data
        } catch {
            // Checkin failure is non-fatal — app works offline/locally.
        }
        return nil
    }

    // MARK: - Private helpers

    /// Stable UUID that persists across launches (stored in UserDefaults).
    private func persistentInstallUUID() -> String {
        if let existing = defaults.string(forKey: Keys.appUuid), !existing.isEmpty {
            return existing
        }
        let new = UUID().uuidString
        defaults.set(new, forKey: Keys.appUuid)
        return new
    }

    private func appVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
