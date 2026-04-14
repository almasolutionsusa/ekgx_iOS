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
    var appVersion: String?
    var recordedAt: Date?

    // Raw EKG file bytes (.plist signal data)
    var fileData: Data?
    // Rendered 12-lead JPEG (optional — required for IN_HOUSE EMR)
    var imageData: Data?
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
        if let image = payload.imageData {
            files.append(MultipartFile(
                fieldName: "imageFile",
                fileName: "ecg_\(Int(Date().timeIntervalSince1970)).jpg",
                mimeType: "image/jpeg",
                data: image
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
        if let v = p.duration     { q["duration"]     = v }
        if let v = p.appVersion   { q["appVersion"]   = v }
        if let date = p.recordedAt {
            q["recordedAt"] = ISO8601DateFormatter().string(from: date)
        }
        return q
    }
}

// MARK: - ECGLeads → Binary Serialisation

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
}
