//
//  EKGUploadService.swift
//  EKGx
//
//  Uploads a completed ECG recording to POST /api/ekg/upload.
//
//  Per the spec:
//  - Required query params: appUuid, patientUuid
//  - Optional query params: all measurement fields, duration, appVersion, recordedAt
//  - Multipart body: a single `file` field containing the EKG .plist / binary
//  - Server resolves App → Kit → Facility → Org → EMR config automatically,
//    so deviceUuid and deviceModel are NOT sent from the client.
//

import Foundation

// MARK: - EKG Upload Payload

struct EKGUploadPayload {
    // Required identifiers
    let patientUuid: String
    let appUuid: String

    // Patient demographics (optional — enriches the server-side record)
    var firstName: String?
    var lastName: String?
    var dob: String?
    var gender: String?
    var medicalRecordNumber: String?

    // Measurements (all optional)
    var heartRate: String?
    var rrInterval: String?
    var prInterval: String?
    var qrsDuration: String?
    var pDuration: String?
    var qtInterval: String?
    var qtCorrected: String?
    var qtDistance: String?
    var qtMax: String?
    var qtMin: String?
    var pAxis: String?
    var qrsAxis: String?
    var sv1: String?
    var rv5: String?
    var rv1: String?
    var sv5: String?
    var diagnosis: String?
    var duration: String?
    var totalDuration: String?
    var appVersion: String?
    var recordedAt: Date?

    // Raw EKG file bytes (.plist signal data)
    var fileData: Data?
    // Rendered multi-page PDF (optional — required for IN_HOUSE EMR)
    var pdfData: Data?
}

// MARK: - EKGUploadService

final class EKGUploadService {

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // MARK: - Upload

    func upload(payload: EKGUploadPayload) async throws {
        let query = buildQuery(from: payload)

        var files: [MultipartFile] = []
        if let data = payload.fileData {
            files.append(MultipartFile(
                fieldName: "file",
                fileName: "ecg_\(Int(Date().timeIntervalSince1970)).plist",
                mimeType: "application/octet-stream",
                data: data
            ))
        }
        if let pdf = payload.pdfData {
            files.append(MultipartFile(
                fieldName: "imageFile",
                fileName: "ecg_\(Int(Date().timeIntervalSince1970)).pdf",
                mimeType: "application/pdf",
                data: pdf
            ))
        }

        do {
            let _: APIResponse<AnyCodable> = try await client.postMultipart(
                path: APIEndpoints.EKG.upload,
                query: query,
                files: files
            )
        } catch let error as APIError {
            throw error
        }
    }

    // MARK: - Private

    private func buildQuery(from p: EKGUploadPayload) -> [String: String] {
        var q: [String: String] = [
            "appUuid":     p.appUuid,
            "patientUuid": p.patientUuid
        ]
        if let v = p.firstName            { q["firstName"]           = v }
        if let v = p.lastName             { q["lastName"]            = v }
        if let v = p.dob                  { q["dob"]                 = v }
        if let v = p.gender               { q["gender"]              = v }
        if let v = p.medicalRecordNumber  { q["medicalRecordNumber"] = v }
        if let v = p.heartRate    { q["heartRate"]    = v }
        if let v = p.rrInterval   { q["rRInterval"]   = v }
        if let v = p.prInterval   { q["pRInterval"]   = v }
        if let v = p.qrsDuration  { q["qRSDuration"]  = v }
        if let v = p.pDuration    { q["pDuration"]    = v }
        if let v = p.qtInterval   { q["qTInterval"]   = v }
        if let v = p.qtCorrected  { q["qTCorrected"]  = v }
        if let v = p.qtDistance   { q["qTDistance"]   = v }
        if let v = p.qtMax        { q["qTMax"]        = v }
        if let v = p.qtMin        { q["qTMin"]        = v }
        if let v = p.pAxis        { q["pAxis"]        = v }
        if let v = p.qrsAxis      { q["qRSAxis"]      = v }
        if let v = p.sv1          { q["sV1"]          = v }
        if let v = p.rv5          { q["rV5"]          = v }
        if let v = p.rv1          { q["rV1"]          = v }
        if let v = p.sv5          { q["sV5"]          = v }
        if let v = p.diagnosis    { q["diagnosis"]    = v }
        if let v = p.duration      { q["duration"]      = v }
        if let v = p.totalDuration { q["totalDuration"] = v }
        if let v = p.appVersion    { q["appVersion"]    = v }
        if let date = p.recordedAt {
            q["recordedAt"] = ISO8601DateFormatter().string(from: date)
        }
        return q
    }
}

// MARK: - ECGLeads ↔ Binary Serialisation

extension EKGUploadService {
    /// Serialise 12-lead ECG data as raw Int16 little-endian binary.
    /// Format: [lead0_sample0, lead0_sample1, ..., lead11_sampleN]
    static func serialise(ecgData: [[NSNumber]]) -> Data {
        var data = Data()
        for frame in ecgData {
            for sample in frame {
                var val = Int16(truncatingIfNeeded: sample.intValue)
                withUnsafeBytes(of: &val) { data.append(contentsOf: $0) }
            }
        }
        return data
    }

    /// Inverse of `serialise`.
    /// serialise writes lead-by-lead: [lead0_s0, lead0_s1, ..., lead1_s0, lead1_s1, ..., lead11_sN]
    static func deserialise(data: Data, leadCount: Int = 12) -> [[NSNumber]] {
        guard leadCount > 0, data.count >= leadCount * 2 else { return [] }
        let totalSamples = data.count / 2
        let samplesPerLead = totalSamples / leadCount
        guard samplesPerLead > 0 else { return [] }
        var leads: [[NSNumber]] = Array(repeating: [], count: leadCount)
        data.withUnsafeBytes { ptr in
            let shorts = ptr.bindMemory(to: Int16.self)
            for l in 0..<leadCount {
                leads[l].reserveCapacity(samplesPerLead)
                for s in 0..<samplesPerLead {
                    let idx = l * samplesPerLead + s
                    leads[l].append(NSNumber(value: Int(shorts[idx])))
                }
            }
        }
        return leads
    }
}
