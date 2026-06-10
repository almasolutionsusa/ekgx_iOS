//
//  VitalsUploadService.swift
//  EKGx
//
//  Uploads vital-sign readings to POST /api/vitals.
//
//  All request bodies include appUuid, patientUuid, patient demographics,
//  the vital type/unit/value fields, device info, and an ISO 8601 recordedAt.
//  Nil optional fields are omitted from the JSON (encodeIfPresent).
//

import Foundation

// MARK: - VitalUploadBody

struct VitalUploadBody: Encodable {

    // Required
    let appUuid: String
    let patientUuid: String
    let type: String
    let unit: String
    let recordedAt: String      // ISO 8601

    // Patient demographics
    var firstName: String?
    var lastName: String?
    var dob: String?
    var gender: String?
    var medicalRecordNumber: String?

    // Value — numeric vitals use `val`; BP uses systolicValue + diastolicValue
    var val: Double?
    var systolicValue: Int?
    var diastolicValue: Int?
    var pulseRate: Int?

    // Device / method
    var method: String?
    var deviceName: String?
    var deviceUuid: String?

    // Optional clinical note (e.g. "Patient resting, no symptoms")
    var response: String?

    // Omit nil fields from the JSON output
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(appUuid,      forKey: .appUuid)
        try c.encode(patientUuid,  forKey: .patientUuid)
        try c.encode(type,         forKey: .type)
        try c.encode(unit,         forKey: .unit)
        try c.encode(recordedAt,   forKey: .recordedAt)
        try c.encodeIfPresent(firstName,           forKey: .firstName)
        try c.encodeIfPresent(lastName,            forKey: .lastName)
        try c.encodeIfPresent(dob,                 forKey: .dob)
        try c.encodeIfPresent(gender,              forKey: .gender)
        try c.encodeIfPresent(medicalRecordNumber, forKey: .medicalRecordNumber)
        try c.encodeIfPresent(val,                 forKey: .val)
        try c.encodeIfPresent(systolicValue,       forKey: .systolicValue)
        try c.encodeIfPresent(diastolicValue,      forKey: .diastolicValue)
        try c.encodeIfPresent(pulseRate,           forKey: .pulseRate)
        try c.encodeIfPresent(method,              forKey: .method)
        try c.encodeIfPresent(deviceName,          forKey: .deviceName)
        try c.encodeIfPresent(deviceUuid,          forKey: .deviceUuid)
        try c.encodeIfPresent(response,            forKey: .response)
    }

    enum CodingKeys: String, CodingKey {
        case appUuid, patientUuid, type, unit, recordedAt
        case firstName, lastName, dob, gender, medicalRecordNumber
        case val, systolicValue, diastolicValue, pulseRate
        case method, deviceName, deviceUuid, response
    }
}

// MARK: - VitalsUploadService

final class VitalsUploadService {

    private let client: APIClient
    private let authService: AuthServiceProtocol

    init(client: APIClient = .shared, authService: AuthServiceProtocol) {
        self.client = client
        self.authService = authService
    }

    // MARK: - Blood Pressure

    func uploadBP(
        systolic: Int,
        diastolic: Int,
        pulseRate: Int?,
        patient: Patient,
        deviceName: String?,
        arm: BPArm? = nil,
        position: BPPosition? = nil,
        methodOverride: String? = nil,
        recordedAt: Date = Date()
    ) async throws {
        let methodParts = [arm?.fullLabel, position?.label].compactMap { $0 }
        var body = base(patient: patient, type: "BLOOD_PRESSURE", unit: "mmHg", recordedAt: recordedAt)
        body.systolicValue = systolic
        body.diastolicValue = diastolic
        body.pulseRate = pulseRate
        body.method = methodOverride ?? (methodParts.isEmpty ? "Automatic cuff" : methodParts.joined(separator: ", "))
        body.deviceName = deviceName
        try await post(body)
    }

    // MARK: - SpO2

    func uploadSpO2(
        value: Int,
        pulseRate: Int?,
        patient: Patient,
        deviceName: String?,
        methodOverride: String? = nil,
        recordedAt: Date = Date()
    ) async throws {
        var body = base(patient: patient, type: "SPO2", unit: "%", recordedAt: recordedAt)
        body.val = Double(value)
        body.pulseRate = pulseRate
        body.method = methodOverride ?? "Fingertip pulse oximeter"
        body.deviceName = deviceName
        try await post(body)
    }

    // MARK: - Temperature

    func uploadTemp(
        value: Double,
        unit: String,
        patient: Patient,
        deviceName: String?,
        methodOverride: String? = nil,
        recordedAt: Date = Date()
    ) async throws {
        var body = base(patient: patient, type: "TEMPERATURE", unit: unit, recordedAt: recordedAt)
        body.val = value
        body.method = methodOverride ?? "Oral"
        body.deviceName = deviceName
        try await post(body)
    }

    // MARK: - Respiratory Rate

    func uploadRR(
        value: Int,
        patient: Patient,
        recordedAt: Date = Date()
    ) async throws {
        var body = base(patient: patient, type: "RESPIRATORY_RATE", unit: "breaths/min", recordedAt: recordedAt)
        body.val = Double(value)
        body.method = "Manual count"
        body.deviceName = "Manual"
        body.deviceUuid = "manual-001"
        try await post(body)
    }

    // MARK: - Pain Level

    func uploadPain(
        value: Int,
        patient: Patient,
        recordedAt: Date = Date()
    ) async throws {
        var body = base(patient: patient, type: "PAIN_LEVEL", unit: "/10", recordedAt: recordedAt)
        body.val = Double(value)
        body.method = "Patient reported"
        body.deviceName = "Manual"
        body.deviceUuid = "manual-001"
        try await post(body)
    }

    // MARK: - Weight

    func uploadWeight(
        value: Double,
        unit: String,
        patient: Patient,
        deviceName: String?,
        recordedAt: Date = Date()
    ) async throws {
        var body = base(patient: patient, type: "WEIGHT", unit: unit, recordedAt: recordedAt)
        body.val = value
        body.method = "Standing scale"
        body.deviceName = deviceName
        try await post(body)
    }

    // MARK: - Height

    func uploadHeight(
        valueCm: Double,
        patient: Patient,
        recordedAt: Date = Date()
    ) async throws {
        var body = base(patient: patient, type: "HEIGHT", unit: "cm", recordedAt: recordedAt)
        body.val = valueCm
        body.method = "Manual"
        body.deviceName = "Manual"
        body.deviceUuid = "manual-001"
        try await post(body)
    }

    // MARK: - Heart Rate

    func uploadHeartRate(
        bpm: Int,
        patient: Patient,
        deviceName: String?,
        recordedAt: Date = Date()
    ) async throws {
        var body = base(patient: patient, type: "HEART_RATE", unit: "bpm", recordedAt: recordedAt)
        body.val = Double(bpm)
        body.method = "Pulse oximeter"
        body.deviceName = deviceName
        try await post(body)
    }

    // MARK: - Private

    private func base(patient: Patient, type: String, unit: String, recordedAt: Date) -> VitalUploadBody {
        VitalUploadBody(
            appUuid:    UserDefaults.standard.string(forKey: AppCheckinService.Keys.appUuid) ?? "",
            patientUuid: patient.patientId ?? patient.uniqueId ?? "",
            type:       type,
            unit:       unit,
            recordedAt: ISO8601DateFormatter().string(from: recordedAt),
            firstName:           patient.firstName.isEmpty  ? nil : patient.firstName,
            lastName:            patient.lastName.isEmpty   ? nil : patient.lastName,
            dob:                 patient.birthDate.isEmpty  ? nil : patient.birthDate,
            gender:              patient.gender.isEmpty     ? nil : patient.gender,
            medicalRecordNumber: patient.medicalRecordNumber
        )
    }

    private func post(_ body: VitalUploadBody) async throws {
        try await ensureAuthenticated()
        print("📤 Uploading vital: type=\(body.type) unit=\(body.unit) val=\(body.val.map { String($0) } ?? "\(body.systolicValue ?? 0)/\(body.diastolicValue ?? 0)") patient=\(body.patientUuid)")
        do {
            let _: APIResponse<AnyCodable> = try await client.post(
                path: APIEndpoints.Vitals.upload,
                body: body
            )
            print("✅ Vital uploaded: \(body.type)")
        } catch {
            print("❌ Vital upload failed: \(body.type) — \(error)")
            throw error
        }
    }

    /// Silently re-login with stored credentials if no access token is present.
    /// Mirrors the EKG upload flow: PIN verification triggers a server login to
    /// get a fresh JWT before the upload request is sent.
    private func ensureAuthenticated() async throws {
        guard (TokenStore.shared.accessToken ?? "").isEmpty else { return }
        let store    = LocalUserStore.shared
        let loginId  = store.email ?? store.username ?? ""
        let password = store.storedPassword(for: loginId)
                    ?? store.username.flatMap { store.storedPassword(for: $0) }
        if !loginId.isEmpty, let password {
            try? await authService.login(email: loginId, password: password)
        }
    }
}
