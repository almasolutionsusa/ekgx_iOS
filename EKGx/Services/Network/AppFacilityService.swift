//
//  AppFacilityService.swift
//  EKGx
//
//  Resolves App → Kit → Facility → Organization for the current app install.
//  Returns the facility and organization details if the app is assigned to a kit.
//
//  Per spec: GET /api/app/facility?appUuid=... — permitAll, no auth required.
//  Used by the registration screen to auto-fill the target facility, and by
//  home/settings to display which facility the device belongs to.
//

import Foundation

// MARK: - Response Model

struct AppFacilityData: Decodable {
    let facilityId: Int64?
    let facilityName: String?
    let organizationId: Int64?
    let organizationName: String?
    let assigned: Bool?
}

// MARK: - Service

final class AppFacilityService {

    private let client: APIClient
    private let checkinService: AppCheckinService

    init(client: APIClient = .shared, checkinService: AppCheckinService) {
        self.client         = client
        self.checkinService = checkinService
    }

    /// Fetches the facility the current app is assigned to.
    /// Returns nil on any error — callers should treat nil as "not assigned".
    func getFacility() async -> AppFacilityData? {
        let appUuid = checkinService.appUuid
        guard !appUuid.isEmpty else { return nil }

        do {
            let response: APIResponse<AppFacilityData> = try await client.get(
                path: APIEndpoints.App.facility,
                query: ["appUuid": appUuid]
            )
            return response.data
        } catch {
            return nil
        }
    }
}
