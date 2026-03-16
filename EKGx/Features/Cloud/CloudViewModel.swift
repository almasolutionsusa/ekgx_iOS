//
//  CloudViewModel.swift
//  EKGx
//

import Foundation

@Observable
@MainActor
final class CloudViewModel {

    // MARK: - Patient list state

    var patients: [Patient] = Patient.mockPatients
    var searchQuery: String = ""
    var selectedPatient: Patient? = nil

    // MARK: - Recording state

    var recordings: [ECGRecording] = []
    var isLoadingRecordings: Bool = false

    // MARK: - Dependencies

    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
    }

    // MARK: - Computed

    var filteredPatients: [Patient] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return patients }
        return patients.filter {
            $0.fullName.localizedCaseInsensitiveContains(query) ||
            ($0.medicalRecordNumber?.localizedCaseInsensitiveContains(query) ?? false) ||
            ($0.patientId?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    // MARK: - Actions

    func selectPatient(_ patient: Patient) {
        selectedPatient = patient
        loadRecordings(for: patient)
    }

    func clearSearch() {
        searchQuery = ""
    }

    func navigateBack() {
        router.navigate(to: .dashboard)
    }

    // MARK: - Private

    private func loadRecordings(for patient: Patient) {
        guard let uid = patient.uniqueId else {
            recordings = []
            return
        }
        isLoadingRecordings = true
        // Simulate network fetch (replace with real API call)
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            recordings = ECGRecording.mockRecordings(for: uid)
                .sorted { $0.recordedAt > $1.recordedAt }
            isLoadingRecordings = false
        }
    }
}
