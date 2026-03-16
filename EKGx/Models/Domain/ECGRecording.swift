//
//  ECGRecording.swift
//  EKGx
//

import Foundation

// MARK: - ECGRecording

struct ECGRecording: Identifiable, Codable, Hashable {

    let id: String
    let patientId: String
    let recordedAt: Date
    let durationSeconds: Int
    let technicianName: String
    let notes: String?
    let status: RecordingStatus
    let fileSize: Int          // bytes
    let leadCount: Int         // e.g. 12

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
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d min", m, s)
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
        let technicians = ["Dr. Sarah Mitchell", "Nurse John Reeves", "Tech. Amy Carson", "Dr. Paul Kim"]
        let notes = [
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
                    id: "REC-\(String(format: "%04d", id))",
                    patientId: pid,
                    recordedAt: recordedAt,
                    durationSeconds: Int.random(in: 30...300),
                    technicianName: technicians[id % technicians.count],
                    notes: notes[id % notes.count],
                    status: statuses[id % statuses.count],
                    fileSize: Int.random(in: 512_000...4_096_000),
                    leadCount: 12
                ))
                id += 1
            }
        }
        return records.sorted { $0.recordedAt > $1.recordedAt }
    }()
}
