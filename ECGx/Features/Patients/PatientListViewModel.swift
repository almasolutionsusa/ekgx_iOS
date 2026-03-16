//
//  PatientListViewModel.swift
//  ECGx
//

import Foundation

@Observable
@MainActor
final class PatientListViewModel {

    // MARK: - State

    var patients: [Patient] = Patient.mockPatients
    var searchQuery: String = ""
    var isSearching: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var showAddPatient: Bool = false
    var selectedPatient: Patient? = nil

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

    var totalCount: Int { patients.count }

    // MARK: - Dependencies

    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
    }

    // MARK: - Actions

    func searchPatients() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        // Simulate API search (replace with real network call)
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            isLoading = false
        }
    }

    func clearSearch() {
        searchQuery = ""
        isSearching = false
    }

    func selectPatient(_ patient: Patient) {
        selectedPatient = patient
        router.navigate(to: .patientDetail(patientId: patient.uniqueId ?? "\(patient.id ?? 0)"))
    }

    func navigateBack() {
        router.navigate(to: .dashboard)
    }

    func openAddPatient() {
        showAddPatient = true
    }
}
