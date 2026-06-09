import Foundation

final class LocalBPStore {

    private let key = "ekgx.bpReadings.v1"
    private var allReadings: [BPRecording] = []

    init() { load() }

    // MARK: - Write

    func save(_ reading: BPRecording) {
        allReadings.append(reading)
        persist()
    }

    func delete(id: String) {
        allReadings.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Read

    func readings(for patientId: String) -> [BPRecording] {
        allReadings
            .filter { $0.patientId == patientId }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(allReadings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data    = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([BPRecording].self, from: data)
        else { return }
        allReadings = decoded
    }
}
