//
//  WaitingListViewModel.swift
//  EKGx
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class WaitingListViewModel {

    // MARK: - Queue State

    private(set) var patients: [WaitingPatient] = []

    var activePatients: [WaitingPatient] { patients.filter { $0.status != .done } }
    var donePatients:   [WaitingPatient] { patients.filter { $0.status == .done } }
    var hasDone:        Bool             { !donePatients.isEmpty }
    var activeCount:    Int              { activePatients.count }

    // MARK: - Add Patient Sheet

    var showAddPatient:       Bool           = false
    var addSearchText:        String         = "" { didSet { filterAddPatients() } }
    var allLocalPatients:     [LocalPatient] = []
    var filteredAddPatients:  [LocalPatient] = []
    var isLoadingAddPatients: Bool           = false

    // MARK: - Dependencies

    private let store        = WaitingListStore.shared
    private let repository:    PatientRepositoryProtocol
    private let router:        AppRouter
    private let diContainer:   AppDIContainer
    private var timerTask:     Task<Void, Never>?

    init(repository: PatientRepositoryProtocol, router: AppRouter, diContainer: AppDIContainer) {
        self.repository  = repository
        self.router      = router
        self.diContainer = diContainer
    }

    // MARK: - Lifecycle

    func activate() {
        reload()
        Task { await loadAllLocalPatients() }
    }

    func deactivate() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Queue Operations

    private func reload() {
        patients = store.entries
    }

    func startEKG(for patient: WaitingPatient) {
        store.updateStatus(id: patient.id, to: .inProgress)
        reload()
        Task { await beginRecording(for: patient) }
    }

    private func beginRecording(for patient: WaitingPatient) async {
        let local: LocalPatient?
        if let cached = allLocalPatients.first(where: { $0.id == patient.patientId }) {
            local = cached
        } else {
            local = try? await repository.fetchAll().first { $0.id == patient.patientId }
        }
        guard let local else { return }
        diContainer.lastRecordingPatient      = local.toPatient()
        diContainer.recordingSessionStartedAt = Date()
        router.vitalsReturnRoute              = .waitingList
        router.navigate(to: .vitals)
    }

    func markDone(id: UUID) {
        store.updateStatus(id: id, to: .done)
        reload()
    }

    func markWaiting(id: UUID) {
        store.updateStatus(id: id, to: .waiting)
        reload()
    }

    func remove(id: UUID) {
        store.remove(id: id)
        reload()
    }

    func clearDone() {
        store.clearDone()
        reload()
    }

    func move(from source: IndexSet, to destination: Int) {
        var active = activePatients
        active.move(fromOffsets: source, toOffset: destination)
        store.replaceAll(active + donePatients)
        reload()
    }

    // MARK: - Add Patient

    func openAddPatient() {
        addSearchText  = ""
        showAddPatient = true
        Task { await loadAllLocalPatients() }
    }

    func closeAddPatient() {
        showAddPatient = false
        addSearchText  = ""
    }

    func addToQueue(_ patient: LocalPatient) {
        let entry = WaitingPatient(from: patient)
        store.add(entry)
        reload()
        closeAddPatient()
    }

    func isInQueue(_ patient: LocalPatient) -> Bool {
        patients.contains { $0.patientId == patient.id && $0.status != .done }
    }

    private func loadAllLocalPatients() async {
        isLoadingAddPatients = true
        defer { isLoadingAddPatients = false }
        allLocalPatients = (try? await repository.fetchAll()) ?? []
        filterAddPatients()
    }

    private func filterAddPatients() {
        let q = addSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        filteredAddPatients = q.isEmpty
            ? allLocalPatients
            : allLocalPatients.filter {
                $0.fullName.lowercased().contains(q) || $0.mrn.lowercased().contains(q)
              }
    }

    // MARK: - Navigation

    func navigateBack() {
        router.navigate(to: .patientSelection)
    }
}
