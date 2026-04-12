//
//  AppCheckinService.swift
//  EKGx
//
//  Registers / checks-in this app installation with the server on every launch.
//
//  IMPORTANT: `appUuid` IS the device identifier in the EKGx backend.
//  The server uses a single UUID (per-install / per-device) to resolve
//  App → Kit → Facility → Organization. There is no separate deviceUuid.
//
//  We use `UIDevice.current.identifierForVendor` as the stable value, falling
//  back to a persisted random UUID if vendor ID is unavailable.
//
//  Per spec: POST /api/app/checkin — permitAll, no auth required.
//

import Foundation
import UIKit

final class AppCheckinService {

    // MARK: - Stored identifiers

    enum Keys {
        static let appUuid = "ekgx.appUuid"
    }

    private let client: APIClient
    private let defaults: UserDefaults

    // MARK: - Cached identifier (set after init / checkin)

    private(set) var appUuid: String = ""

    // MARK: - Init

    init(client: APIClient = .shared, defaults: UserDefaults = .standard) {
        self.client   = client
        self.defaults = defaults
        self.appUuid  = resolveAppUuid()
    }

    // MARK: - Checkin

    /// Call once on app launch (or after first network reachability).
    /// Safe to call multiple times — server is idempotent on the same UUID.
    @discardableResult
    func checkin() async -> AppCheckinData? {
        let body = AppCheckinRequest(uuid: appUuid, version: appVersion())

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

    /// The appUuid = device vendor identifier (stable across launches, resets on reinstall).
    /// Falls back to a persisted random UUID if vendor ID is unavailable.
    private func resolveAppUuid() -> String {
        if let vendor = UIDevice.current.identifierForVendor?.uuidString, !vendor.isEmpty {
            defaults.set(vendor, forKey: Keys.appUuid)
            return vendor
        }
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
