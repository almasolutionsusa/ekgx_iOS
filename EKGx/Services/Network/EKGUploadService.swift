//
//  EKGUploadService.swift
//  EKGx
//
//  Uploads a completed ECG recording to POST /api/ekg/results.
//  All measurement fields are optional per spec — only appUuid,
//  deviceUuid, and patientUuid are required.
//
//  The raw ECG data is serialised as a binary file and uploaded
//  as multipart/form-data alongside the query parameters.
//

import Foundation

// MARK: - EKG Upload Payload

struct EKGUploadPayload {
    // Required identifiers
    let patientUuid: String
    let appUuid: String
    let deviceUuid: String

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
    var deviceModel: String?
    var recordedAt: Date?

    // Raw ECG file bytes (optional but recommended)
    var fileData: Data?
}

// MARK: - EKGUploadService

final class EKGUploadService {

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    // MARK: - Upload

    func upload(payload: EKGUploadPayload) async throws {
        let fields = buildFields(from: payload)

        do {
            let _: APIResponse<AnyCodable> = try await client.postMultipart(
                path: APIEndpoints.EKG.results,
                fields: fields,
                fileData: payload.fileData,
                fileName: "ecg_\(Int(Date().timeIntervalSince1970)).bin",
                mimeType: "application/octet-stream"
            )
        } catch let error as APIError {
            throw error
        }
    }

    // MARK: - Private

    private func buildFields(from p: EKGUploadPayload) -> [String: String] {
        var f: [String: String] = [
            "appUuid":     p.appUuid,
            "deviceUuid":  p.deviceUuid,
            "patientUuid": p.patientUuid
        ]
        if let v = p.heartRate    { f["heartRate"]    = v }
        if let v = p.rrInterval   { f["rRInterval"]   = v }
        if let v = p.prInterval   { f["pRInterval"]   = v }
        if let v = p.qrsDuration  { f["qRSDuration"]  = v }
        if let v = p.pDuration    { f["pDuration"]    = v }
        if let v = p.qtInterval   { f["qTInterval"]   = v }
        if let v = p.qtCorrected  { f["qTCorrected"]  = v }
        if let v = p.qtDistance   { f["qTDistance"]   = v }
        if let v = p.qtMax        { f["qTMax"]        = v }
        if let v = p.qtMin        { f["qTMin"]        = v }
        if let v = p.pAxis        { f["pAxis"]        = v }
        if let v = p.qrsAxis      { f["qRSAxis"]      = v }
        if let v = p.sv1          { f["sV1"]          = v }
        if let v = p.rv5          { f["rV5"]          = v }
        if let v = p.rv1          { f["rV1"]          = v }
        if let v = p.sv5          { f["sV5"]          = v }
        if let v = p.diagnosis    { f["diagnosis"]    = v }
        if let v = p.duration     { f["duration"]     = v }
        if let v = p.appVersion   { f["appVersion"]   = v }
        if let v = p.deviceModel  { f["deviceModel"]  = v }
        if let date = p.recordedAt {
            f["recordedAt"] = ISO8601DateFormatter().string(from: date)
        }
        return f
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
