//
//  WaitingListStore.swift
//  EKGx
//
//  Local-only queue — persisted to UserDefaults as JSON.
//

import Foundation

final class WaitingListStore {

    static let shared = WaitingListStore()

    private let key = "ekgx.waitingList.v1"
    private(set) var entries: [WaitingPatient] = []

    private init() { load() }

    // MARK: - CRUD

    func add(_ entry: WaitingPatient) {
        let alreadyActive = entries.contains { $0.patientId == entry.patientId && $0.status != .done }
        guard !alreadyActive else { return }
        entries.append(entry)
        persist()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    func updateStatus(id: UUID, to status: WaitingPatient.WaitingStatus) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].status = status
        persist()
    }

    func replaceAll(_ newEntries: [WaitingPatient]) {
        entries = newEntries
        persist()
    }

    func clearDone() {
        entries.removeAll { $0.status == .done }
        persist()
    }

    // MARK: - Counts

    var activeCount:     Int { entries.filter { $0.status != .done }.count }
    var waitingCount:    Int { entries.filter { $0.status == .waiting }.count }
    var inProgressCount: Int { entries.filter { $0.status == .inProgress }.count }
    var doneCount:       Int { entries.filter { $0.status == .done }.count }

    // MARK: - Persistence

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WaitingPatient].self, from: data)
        else { return }
        entries = decoded
    }
}
