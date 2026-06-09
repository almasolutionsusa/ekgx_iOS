import Foundation

struct SpO2Reading: Identifiable, Codable, Hashable {

    let id: String
    let patientId: String
    let patientName: String
    let patientDob: String
    let patientGender: String
    let patientMrn: String?
    let recordedAt: Date
    let value: Int
    let pulseRate: Int?
    let unit: String
    let username: String?

    var displayValue: String { "\(value)\(unit)" }
    var formattedDate: String { Self.dateFormatter.string(from: recordedAt) }
    var formattedTime: String { Self.timeFormatter.string(from: recordedAt) }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short; return f
    }()
}
