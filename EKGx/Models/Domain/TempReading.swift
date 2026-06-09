import Foundation

struct TempReading: Identifiable, Codable, Hashable {

    let id: String
    let patientId: String
    let patientName: String
    let patientDob: String
    let patientGender: String
    let patientMrn: String?
    let recordedAt: Date
    let value: Double
    let unit: String
    let username: String?

    var displayValue: String { String(format: "%.1f %@", value, unit) }
    var formattedDate: String { Self.dateFormatter.string(from: recordedAt) }
    var formattedTime: String { Self.timeFormatter.string(from: recordedAt) }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short; return f
    }()
}
