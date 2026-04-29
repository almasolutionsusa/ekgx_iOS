//
//  CloudViewModel.swift
//  EKGx
//

import Foundation

@Observable
@MainActor
final class CloudViewModel {

    // MARK: - Patient list state

    var patients: [Patient] = []
    var searchQuery: String = ""
    var selectedPatient: Patient? = nil

    // MARK: - Recording state

    var recordings: [ECGRecording] = []
    var isLoadingRecordings: Bool = false

    // MARK: - Dependencies

    private let router: AppRouter
    private let recordingStore: LocalRecordingStore

    init(router: AppRouter, recordingStore: LocalRecordingStore) {
        self.router = router
        self.recordingStore = recordingStore
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

    func activate() {
        // Build patient list from locally stored recordings
        let allRecordings = recordingStore.allRecordings()
        if !allRecordings.isEmpty {
            // Derive unique patients from recording snapshots
            var seen = Set<String>()
            patients = allRecordings.compactMap { rec -> Patient? in
                guard seen.insert(rec.patientId).inserted else { return nil }
                return Patient(
                    id: nil,
                    patientId: rec.patientId,
                    uniqueId: rec.patientId,
                    firstName: rec.patientName.components(separatedBy: " ").first ?? rec.patientName,
                    lastName: rec.patientName.components(separatedBy: " ").dropFirst().joined(separator: " "),
                    birthDate: rec.patientDob,
                    gender: rec.patientGender,
                    medicalRecordNumber: rec.patientMrn,
                    hasPhoto: nil
                )
            }
        }
    }

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
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        guard !pid.isEmpty else { recordings = []; return }
        isLoadingRecordings = true
        recordings = recordingStore.recordings(for: pid)
        isLoadingRecordings = false
    }
}
