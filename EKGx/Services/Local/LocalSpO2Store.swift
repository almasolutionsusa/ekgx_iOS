import Foundation

final class LocalSpO2Store {

    private let key = "ekgx.spo2Readings.v1"
    private var allReadings: [SpO2Reading] = []

    init() { load() }

    func save(_ reading: SpO2Reading) {
        allReadings.append(reading)
        persist()
    }

    func delete(id: String) {
        allReadings.removeAll { $0.id == id }
        persist()
    }

    func readings(for patientId: String) -> [SpO2Reading] {
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
            let decoded = try? JSONDecoder().decode([SpO2Reading].self, from: data)
        else { return }
        allReadings = decoded
    }
}
