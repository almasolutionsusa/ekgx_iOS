//
//  PatientsService.swift
//  EKGx
//
//  Patient search and creation scoped to the authenticated user's facility.
//  Per spec:
//   - POST /api/patients         — create a new patient (unique MRN per facility)
//   - POST /api/patients/search  — search by (firstName+lastName+dob) OR MRN
//
//  Both endpoints accept a flat {string: string} body per the spec.
//

import Foundation

// MARK: - Search Response Models

struct PatientSearchResponse: Decodable {
    let patients: [RemotePatient]
}

struct RemotePatient: Decodable, Hashable {
    let id: Int64?
    let uuid: String?
    let emrPatientId: String?
    let firstName: String?
    let lastName: String?
    let dob: String?
    let gender: String?
    let email: String?
    let phone: String?
    let medicalRecordNumber: String?
    let active: Bool?
    let organizationId: Int64?
    let organizationName: String?
    let facilityIds: [Int64]?
    let facilityNames: [String]?
    let facilityUuids: [String]?
    let createdAt: String?
    let updatedAt: String?

    var fullName: String {
        [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

// MARK: - PatientsService

final class PatientsService {

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // MARK: - Create

    /// Creates a new patient at the user's facility. Returns the created patient.
    func create(
        firstName: String,
        lastName: String,
        dob: String,               // ISO date yyyy-MM-dd
        gender: String,            // "Male" | "Female" | "Other"
        mrn: String,
        facilityId: Int64
    ) async throws -> RemotePatient? {
        let body: [String: String] = [
            "firstName":  firstName,
            "lastName":   lastName,
            "dob":        dob,
            "gender":     gender,
            "mrn":        mrn,
            "facilityId": String(facilityId)
        ]
        // Server may return either a raw RemotePatient or wrap it in {patient: ...}
        // We try the direct shape first.
        let response: APIResponse<RemotePatient> = try await client.post(
            path: APIEndpoints.Patients.create,
            body: body
        )
        return response.data
    }

    // MARK: - Search

    /// Searches for patients by name+dob OR by MRN.
    /// Pass either `firstName`+`lastName`+`dob`, or `mrn`. `facilityId` is required.
    func search(
        firstName: String? = nil,
        lastName: String? = nil,
        dob: String? = nil,
        mrn: String? = nil,
        facilityId: Int64
    ) async throws -> [RemotePatient] {
        var body: [String: String] = ["facilityId": String(facilityId)]
        if let v = firstName, !v.isEmpty { body["firstName"] = v }
        if let v = lastName,  !v.isEmpty { body["lastName"]  = v }
        if let v = dob,       !v.isEmpty { body["dob"]       = v }
        if let v = mrn,       !v.isEmpty { body["mrn"]       = v }

        let response: APIResponse<PatientSearchResponse> = try await client.post(
            path: APIEndpoints.Patients.search,
            body: body
        )
        return response.data?.patients ?? []
    }
}
