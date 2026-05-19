//
//  ECGRecording.swift
//  EKGx
//

import Foundation
import CoreData

// MARK: - ECGRecording

struct ECGRecording: Identifiable, Codable, Hashable {

    let id: String
    let patientId: String
    // Patient snapshot (stored locally so we can show it without re-fetching)
    let patientName: String
    let patientDob: String
    let patientGender: String
    let patientMrn: String?
    let recordedAt: Date
    let durationSeconds: Int
    let sampleRate: Int
    let leadCount: Int         // e.g. 12
    let fileSize: Int          // bytes
    let status: RecordingStatus
    // Measurements snapshot
    let diagnosis: String?
    let heartRate: String?
    let prInterval: String?
    let qrsDuration: String?
    let qtInterval: String?
    let qtCorrected: String?
    let appVersion: String?
    let username: String?

    // MARK: - Status

    enum RecordingStatus: String, Codable {
        case synced     = "synced"
        case pending    = "pending"
        case failed     = "failed"

        var label: String {
            switch self {
            case .synced:  return "Synced"
            case .pending: return "Pending Sync"
            case .failed:  return "Sync Failed"
            }
        }

        var systemImage: String {
            switch self {
            case .synced:  return "checkmark.icloud.fill"
            case .pending: return "icloud.and.arrow.up"
            case .failed:  return "exclamationmark.icloud.fill"
            }
        }
    }

    // MARK: - Computed

    var formattedDate: String {
        Self.displayFormatter.string(from: recordedAt)
    }

    var formattedTime: String {
        Self.timeFormatter.string(from: recordedAt)
    }

    var formattedDuration: String {
        "\(durationSeconds) sec"
    }

    var formattedFileSize: String {
        let kb = Double(fileSize) / 1024.0
        if kb < 1024 { return String(format: "%.0f KB", kb) }
        return String(format: "%.1f MB", kb / 1024.0)
    }

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
}

// MARK: - CoreData Mapping

extension ECGRecording {

    /// Build from a CoreData entity.
    init?(entity: ECGRecordingEntity) {
        guard
            let id          = entity.id,
            let patientId   = entity.patientId,
            let recordedAt  = entity.recordedAt,
            let statusRaw   = entity.status,
            let status      = RecordingStatus(rawValue: statusRaw)
        else { return nil }

        self.id            = id
        self.patientId     = patientId
        self.patientName   = entity.patientName ?? ""
        self.patientDob    = entity.patientDob ?? ""
        self.patientGender = entity.patientGender ?? ""
        self.patientMrn    = entity.patientMrn
        self.recordedAt    = recordedAt
        self.durationSeconds = Int(entity.durationSeconds)
        self.sampleRate    = Int(entity.sampleRate)
        self.leadCount     = Int(entity.leadCount)
        self.fileSize      = Int(entity.fileSize)
        self.status        = status
        self.diagnosis     = entity.diagnosis
        self.heartRate     = entity.heartRate
        self.prInterval    = entity.prInterval
        self.qrsDuration   = entity.qrsDuration
        self.qtInterval    = entity.qtInterval
        self.qtCorrected   = entity.qtCorrected
        self.appVersion    = entity.appVersion
        self.username      = entity.username
    }

    /// Build a new pending recording from an analysis context.
    static func makePending(
        patient: Patient,
        durationSeconds: Int,
        sampleRate: Int,
        diagnosis: String?,
        heartRate: String?,
        prInterval: String?,
        qrsDuration: String?,
        qtInterval: String?,
        qtCorrected: String?,
        fileSize: Int,
        appVersion: String?,
        username: String? = nil
    ) -> ECGRecording {
        ECGRecording(
            id:             UUID().uuidString,
            patientId:      patient.patientId ?? patient.uniqueId ?? UUID().uuidString,
            patientName:    patient.fullName,
            patientDob:     patient.birthDate,
            patientGender:  patient.gender,
            patientMrn:     patient.medicalRecordNumber,
            recordedAt:     Date(),
            durationSeconds: durationSeconds,
            sampleRate:     sampleRate,
            leadCount:      12,
            fileSize:       fileSize,
            status:         .pending,
            diagnosis:      diagnosis,
            heartRate:      heartRate,
            prInterval:     prInterval,
            qrsDuration:    qrsDuration,
            qtInterval:     qtInterval,
            qtCorrected:    qtCorrected,
            appVersion:     appVersion,
            username:       username
        )
    }
}

// MARK: - Mock Data

extension ECGRecording {

    static func mockRecordings(for patientId: String) -> [ECGRecording] {
        let base = mockAll.filter { $0.patientId == patientId }
        return base.isEmpty ? [] : base
    }

    static let mockAll: [ECGRecording] = {
        var records: [ECGRecording] = []
        let calendar = Calendar.current
        let now = Date()

        let patientIds = (1...12).map { "UID-A\(String(format: "%03d", $0))" }
        let notes: [String?] = [
            "Routine 12-lead ECG. Normal sinus rhythm.",
            "Patient reported mild chest discomfort. ST segment reviewed.",
            "Post-medication follow-up. Rhythm stable.",
            "Pre-operative assessment.",
            "Annual cardiac evaluation.",
            nil, nil
        ]
        let statuses: [ECGRecording.RecordingStatus] = [.synced, .synced, .synced, .pending, .failed]

        var id = 1
        for pid in patientIds {
            let count = Int.random(in: 2...6)
            for i in 0..<count {
                let daysAgo = i * Int.random(in: 7...30)
                let recordedAt = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
                records.append(ECGRecording(
                    id:             "REC-\(String(format: "%04d", id))",
                    patientId:      pid,
                    patientName:    "Patient \(pid)",
                    patientDob:     "1980-01-01",
                    patientGender:  "M",
                    patientMrn:     "MRN-\(pid)",
                    recordedAt:     recordedAt,
                    durationSeconds: Int.random(in: 30...300),
                    sampleRate:     660,
                    leadCount:      12,
                    fileSize:       Int.random(in: 512_000...4_096_000),
                    status:         statuses[id % statuses.count],
                    diagnosis:      notes[id % notes.count],
                    heartRate:      "\(Int.random(in: 60...100))",
                    prInterval:     "160",
                    qrsDuration:    "90",
                    qtInterval:     "400",
                    qtCorrected:    "420",
                    appVersion:     "1.0",
                    username:       "dr.demo"
                ))
                id += 1
            }
        }
        return records.sorted { $0.recordedAt > $1.recordedAt }
    }()
}
