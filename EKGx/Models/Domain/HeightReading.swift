import Foundation

struct HeightReading: Identifiable, Codable, Hashable {

    let id: String
    let patientId: String
    let patientName: String
    let patientDob: String
    let patientGender: String
    let patientMrn: String?
    let recordedAt: Date
    let valueCm: Double
    let displayValue: String   // pre-formatted (e.g. "5'11\" / 180 cm")
    let username: String?

    var formattedDate: String { Self.dateFormatter.string(from: recordedAt) }
    var formattedTime: String { Self.timeFormatter.string(from: recordedAt) }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .none; f.timeStyle = .short; return f
    }()
}
