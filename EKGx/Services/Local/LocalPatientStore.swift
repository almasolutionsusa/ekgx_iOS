//
//  LocalPatientStore.swift
//  EKGx
//
//  Persists LocalPatient records to UserDefaults.
//  Used exclusively in offline mode.
//

import Foundation

@Observable
@MainActor
final class LocalPatientStore {

    private enum Keys {
        static let patients = "ekgx.localPatients"
    }

    private(set) var patients: [LocalPatient] = []

    init() {
        patients = load()
    }

    // MARK: - CRUD

    func add(_ patient: LocalPatient) {
        patients.insert(patient, at: 0)
        save()
    }

    func delete(_ patient: LocalPatient) {
        patients.removeAll { $0.id == patient.id }
        save()
    }

    // MARK: - Persistence

    private func load() -> [LocalPatient] {
        guard let data = UserDefaults.standard.data(forKey: Keys.patients),
              let decoded = try? JSONDecoder().decode([LocalPatient].self, from: data)
        else { return [] }
        return decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(patients) else { return }
        UserDefaults.standard.set(data, forKey: Keys.patients)
    }
}
