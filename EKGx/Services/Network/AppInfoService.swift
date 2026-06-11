//
//  AppInfoService.swift
//  EKGx
//
//  Resolves App → Kit → Facility → Organization and returns facility/org
//  details plus enum values (titles, degrees) needed for the registration form.
//
//  Per spec: GET /api/app/info?appUuid=... — permitAll, no auth required.
//

import Foundation

// MARK: - Response Model

struct AppInfoData: Codable {
    let assigned: Bool?
    let message: String?
    let facilityId: Int64?
    let facilityName: String?
    let organizationId: Int64?
    let organizationName: String?
    let titles: [String]?
    let degrees: [String]?
}

// MARK: - Service

final class AppInfoService {

    private let client: APIClient
    private let checkinService: AppCheckinService
    private static let persistKey = "appInfoService.cachedAppInfo"

    /// The most recent app info fetched from the server. Cached in memory
    /// so any view model that needs `facilityId` can read it synchronously.
    private(set) var cached: AppInfoData? = nil {
        didSet { persist() }
    }

    /// Convenience accessor for the facility ID used by patient/ekg APIs.
    /// Prefers the freshly-fetched info; falls back to the facilityId
    /// persisted from the most recent login response.
    var facilityId: Int64? { cached?.facilityId ?? TokenStore.shared.facilityId }

    init(client: APIClient = .shared, checkinService: AppCheckinService) {
        self.client         = client
        self.checkinService = checkinService
        self.cached         = Self.loadPersisted()
    }

    private static func loadPersisted() -> AppInfoData? {
        guard let data = UserDefaults.standard.data(forKey: persistKey),
              let info = try? JSONDecoder().decode(AppInfoData.self, from: data) else { return nil }
        return info
    }

    private func persist() {
        guard let info = cached,
              let data = try? JSONEncoder().encode(info) else { return }
        UserDefaults.standard.set(data, forKey: Self.persistKey)
    }

    /// Fetches the full app info (facility, org, enum options) for the current install.
    /// Returns nil on any error — callers should treat nil as "not assigned".
    /// Side effect: updates `cached` on success.
    @discardableResult
    func getInfo() async -> AppInfoData? {
        let appUuid = checkinService.appUuid
        guard !appUuid.isEmpty else { return nil }

        do {
            let response: APIResponse<AppInfoData> = try await client.get(
                path: APIEndpoints.App.info,
                query: ["appUuid": appUuid]
            )
            if let data = response.data {
                cached = data
            }
            return response.data
        } catch {
            return nil
        }
    }
}
