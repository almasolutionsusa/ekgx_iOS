import Foundation

// MARK: - BP Risk Level (top-level so it resolves cleanly in any SwiftUI view file)

enum BPRiskLevel: String, Codable {
    case normal, elevated, highStage1, highStage2, crisis

    var label: String {
        switch self {
        case .normal:      return "Normal"
        case .elevated:    return "Elevated"
        case .highStage1:  return "High · Stage 1"
        case .highStage2:  return "High · Stage 2"
        case .crisis:      return "Hypertensive Crisis"
        }
    }

    var systemImage: String {
        switch self {
        case .normal:      return "checkmark.circle.fill"
        case .elevated:    return "exclamationmark.circle"
        case .highStage1:  return "exclamationmark.circle.fill"
        case .highStage2:  return "exclamationmark.triangle.fill"
        case .crisis:      return "cross.circle.fill"
        }
    }
}

// MARK: - BP Recording

struct BPRecording: Identifiable, Codable, Hashable {

    let id: String
    let patientId: String
    let patientName: String
    let patientDob: String
    let patientGender: String
    let patientMrn: String?
    let recordedAt: Date
    let systolic: Int
    let diastolic: Int
    let pulseRate: Int?
    let username: String?
    let arm: BPArm?
    let position: BPPosition?

    // MARK: - Computed

    var displayValue: String { "\(systolic)/\(diastolic)" }

    var formattedDate: String { Self.dateFormatter.string(from: recordedAt) }
    var formattedTime: String { Self.timeFormatter.string(from: recordedAt) }

    var riskLevel: BPRiskLevel {
        if systolic > 180 || diastolic > 120 { return .crisis }
        if systolic >= 140 || diastolic >= 90 { return .highStage2 }
        if systolic >= 130 || diastolic >= 80 { return .highStage1 }
        if systolic >= 120                    { return .elevated }
        return .normal
    }

    // MARK: - Private formatters

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short; return f
    }()
}
