import Foundation

final class LocalPainStore {

    private let key = "ekgx.painReadings.v1"
    private var allReadings: [PainReading] = []

    init() { load() }

    func save(_ reading: PainReading) {
        allReadings.append(reading)
        persist()
    }

    func delete(id: String) {
        allReadings.removeAll { $0.id == id }
        persist()
    }

    func readings(for patientId: String) -> [PainReading] {
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
            let decoded = try? JSONDecoder().decode([PainReading].self, from: data)
        else { return }
        allReadings = decoded
    }
}
