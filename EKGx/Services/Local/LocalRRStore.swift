import Foundation

final class LocalRRStore {

    private let key = "ekgx.rrReadings.v1"
    private var allReadings: [RRReading] = []

    init() { load() }

    func save(_ reading: RRReading) {
        allReadings.append(reading)
        persist()
    }

    func delete(id: String) {
        allReadings.removeAll { $0.id == id }
        persist()
    }

    func readings(for patientId: String) -> [RRReading] {
        allReadings
            .filter { $0.patientId == patientId }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(allReadings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data    = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([RRReading].self, from: data)
        else { return }
        allReadings = decoded
    }
}
