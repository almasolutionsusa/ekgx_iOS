//
//  PatientSelectionViewModel.swift
//  EKGx
//
//  Unified patient selection — always reads from local Core Data.
//  API-based search is supported in the future via PatientRepositoryProtocol.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class PatientSelectionViewModel {

    // MARK: - Search

    var searchFirstName: String = "" { didSet { applyFilter() } }
    var searchLastName:  String = "" { didSet { applyFilter() } }
    var searchMRN:       String = "" { didSet { applyFilter() } }
    var searchDob:       Date?  = nil { didSet { applyFilter() } }

    // MARK: - Patient List

    private var allPatients: [LocalPatient] = []
    var filteredPatients: [LocalPatient] = []
    var selected: LocalPatient? = nil

    // MARK: - Delete Patient

    var showDeleteConfirm:    Bool         = false
    private var deletingPatient: LocalPatient? = nil

    func examCount(for patient: LocalPatient) -> Int {
        diContainer.recordingStore.recordings(for: patient.id).count
    }

    func confirmDelete(_ patient: LocalPatient) {
        deletingPatient   = patient
        showDeleteConfirm = true
    }

    func cancelDelete() {
        showDeleteConfirm = false
        deletingPatient   = nil
    }

    func deleteConfirmed() {
        guard let patient = deletingPatient else { return }
        showDeleteConfirm = false
        Task {
            do {
                try await repository.delete(patient.id)
                allPatients.removeAll { $0.id == patient.id }
                if selected?.id == patient.id { selected = nil }
                applyFilter()
            } catch {
                // Non-fatal — patient stays in list
            }
            deletingPatient = nil
        }
    }

    // MARK: - Edit Patient Form

    var showEditPatient:      Bool    = false
    private(set) var editingPatient:  LocalPatient? = nil
    var editFirstName:        String  = ""
    var editLastName:         String  = ""
    var editDob:              Date?   = nil
    var editGender:           String  = "Male"
    var editMRN:              String  = ""
    var editFirstNameError:   String? = nil
    var editLastNameError:    String? = nil
    var editDobError:         String? = nil
    var editMRNError:         String? = nil
    var isUpdating:           Bool    = false
    var editErrorMessage:     String? = nil

    // MARK: - Create Patient Form

    var showCreatePatient:    Bool    = false
    var createFirstName:      String  = ""
    var createLastName:       String  = ""
    var createDob:            Date?   = nil
    var createGender:         String  = "Male"
    var createMRN:            String  = ""
    var createFirstNameError: String? = nil
    var createLastNameError:  String? = nil
    var createDobError:       String? = nil
    var createMRNError:       String? = nil
    var isCreating:           Bool    = false
    var createErrorMessage:   String? = nil

    var canSubmitCreate: Bool {
        !createFirstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !createLastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        createDob != nil &&
        !createMRN.trimmingCharacters(in: .whitespaces).isEmpty
    }

    let genderOptions: [String] = ["Male", "Female"]
    var canConfirm: Bool { selected != nil }
    var isSearchActive: Bool {
        !searchFirstName.isEmpty || !searchLastName.isEmpty || !searchMRN.isEmpty || searchDob != nil
    }

    // MARK: - Menu / Logout

    func openMenu() {
        router.menuReturnRoute = .patientSelection
        router.navigate(to: .menu)
    }

    func logout() {
        diContainer.autoLockManager.stop()
        Task { try? await diContainer.authService.logout() }
        router.navigate(to: .login)
    }

    func navigateToWaitingList() { router.navigate(to: .waitingList) }

    var waitingListBadgeCount: Int { WaitingListStore.shared.activeCount }

    // MARK: - Dependencies

    private let repository: PatientRepositoryProtocol
    private let router: AppRouter
    private let diContainer: AppDIContainer

    init(repository: PatientRepositoryProtocol, router: AppRouter, diContainer: AppDIContainer) {
        self.repository  = repository
        self.router      = router
        self.diContainer = diContainer
    }

    // MARK: - Load

    func activate() {
        Task { await loadAll() }
    }

    private func loadAll() async {
        do {
            allPatients = try await repository.fetchAll()
            applyFilter()
        } catch {
            // Non-fatal — list stays empty
        }
    }

    private func applyFilter() {
        let firstName = searchFirstName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let lastName  = searchLastName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let mrn       = searchMRN.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let dob       = searchDob.map { LocalPatient.dateFormatter.string(from: $0) }

        var results = allPatients

        if !firstName.isEmpty { results = results.filter { $0.firstName.lowercased().contains(firstName) } }
        if !lastName.isEmpty  { results = results.filter { $0.lastName.lowercased().contains(lastName) } }
        if !mrn.isEmpty       { results = results.filter { $0.mrn.lowercased().contains(mrn) } }
        if let dob            { results = results.filter { $0.birthDate == dob } }

        // Sort by most recent exam — patients with a recording bubble to the top,
        // ordered by the recording's recordedAt date descending.
        let latestDate: [String: Date] = diContainer.recordingStore.allRecordings()
            .reduce(into: [:]) { map, rec in
                if map[rec.patientId] == nil { map[rec.patientId] = rec.recordedAt }
            }
        results.sort {
            switch (latestDate[$0.id], latestDate[$1.id]) {
            case (let a?, let b?): return a > b
            case (_?, nil):        return true
            case (nil, _?):        return false
            default:               return false
            }
        }

        filteredPatients = results

        if !mrn.isEmpty && results.count == 1 {
            selected = results.first
        }
    }

    // MARK: - Selection

    func select(_ patient: LocalPatient) {
        selected = patient
    }

    func clearSearch() {
        searchFirstName = ""
        searchLastName  = ""
        searchMRN       = ""
        searchDob       = nil
        selected        = nil
    }

    // MARK: - Navigation

    func navigateToVitals(_ patient: LocalPatient) {
        selected = patient
        diContainer.lastRecordingPatient = patient.toPatient()
        diContainer.recordingSessionStartedAt = Date()
        router.navigate(to: .vitals)
    }

    func navigateToHistory(_ patient: LocalPatient) {
        diContainer.lastRecordingPatient = patient.toPatient()
        router.patientExamsReturnRoute = .patientSelection
        router.navigate(to: .patientExams)
    }

    func navigateBack() {
        router.navigate(to: .login)
    }

    // MARK: - Create Patient

    func openCreatePatient() {
        createFirstName      = ""
        createLastName       = ""
        createDob            = nil
        createGender         = "Male"
        createMRN            = ""
        createFirstNameError = nil
        createLastNameError  = nil
        createDobError       = nil
        createMRNError       = nil
        createErrorMessage   = nil
        showCreatePatient    = true
    }

    /// Opens the create sheet pre-filled with whatever the user typed in the search fields.
    func openCreatePatientWithSearchData() {
        createFirstName      = searchFirstName
        createLastName       = searchLastName
        createDob            = searchDob
        createGender         = "Male"
        createMRN            = searchMRN
        createFirstNameError = nil
        createLastNameError  = nil
        createDobError       = nil
        createMRNError       = nil
        createErrorMessage   = nil
        showCreatePatient    = true
    }

    func cancelCreatePatient() {
        showCreatePatient = false
    }

    // MARK: - Edit Patient

    func openEditPatient(_ patient: LocalPatient) {
        editingPatient    = patient
        editFirstName     = patient.firstName
        editLastName      = patient.lastName
        editDob           = LocalPatient.dateFormatter.date(from: patient.birthDate)
        editGender        = patient.gender.isEmpty ? "Male" : patient.gender
        editMRN           = patient.mrn
        editFirstNameError = nil
        editLastNameError  = nil
        editDobError       = nil
        editMRNError       = nil
        editErrorMessage   = nil
        showEditPatient   = true
    }

    func cancelEditPatient() {
        showEditPatient = false
        editingPatient  = nil
    }

    func submitEditPatient() {
        guard validateEdit() else { return }
        guard var patient = editingPatient else { return }

        patient.firstName = editFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.lastName  = editLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        patient.birthDate = editDob.map { LocalPatient.dateFormatter.string(from: $0) } ?? ""
        patient.gender    = editGender
        patient.mrn       = editMRN.trimmingCharacters(in: .whitespacesAndNewlines)

        isUpdating = true
        Task {
            defer { isUpdating = false }
            do {
                try await repository.update(patient)
                if let idx = allPatients.firstIndex(where: { $0.id == patient.id }) {
                    allPatients[idx] = patient
                }
                applyFilter()
                if selected?.id == patient.id { selected = patient }
                showEditPatient = false
                editingPatient  = nil
            } catch {
                editErrorMessage = error.localizedDescription
            }
        }
    }

    private func validateEdit() -> Bool {
        let f   = editFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l   = editLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mrn = editMRN.trimmingCharacters(in: .whitespacesAndNewlines)
        editFirstNameError = f.isEmpty ? L10n.Validation.nameEmpty : nil
        editLastNameError  = l.isEmpty ? L10n.Validation.nameEmpty : nil
        editDobError       = editDob == nil ? L10n.Validation.required : nil
        // Duplicate check excludes the patient being edited (same id is allowed to keep its own MRN)
        editMRNError       = !mrn.isEmpty && allPatients.contains(where: {
                               $0.id != editingPatient?.id && $0.mrn.lowercased() == mrn.lowercased()
                             }) ? L10n.Validation.mrnDuplicate : nil
        return editFirstNameError == nil && editLastNameError == nil
            && editDobError == nil && editMRNError == nil
    }

    func submitCreatePatient() {
        guard validateCreate() else { return }

        let dobStr = createDob.map { LocalPatient.dateFormatter.string(from: $0) } ?? ""
        let input  = NewPatientInput(
            firstName: createFirstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName:  createLastName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: dobStr,
            gender:    createGender,
            mrn:       createMRN.trimmingCharacters(in: .whitespacesAndNewlines),
            createdBy: diContainer.authService.currentUser?.displayName.isEmpty == false
                ? diContainer.authService.currentUser!.displayName
                : diContainer.authService.currentUser?.username ?? ""
        )

        isCreating = true
        Task {
            defer { isCreating = false }
            do {
                let patient = try await repository.add(input)
                allPatients.insert(patient, at: 0)
                applyFilter()
                showCreatePatient = false
                navigateToVitals(patient)
            } catch {
                createErrorMessage = error.localizedDescription
            }
        }
    }

    private func validateCreate() -> Bool {
        let f   = createFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l   = createLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mrn = createMRN.trimmingCharacters(in: .whitespacesAndNewlines)
        createFirstNameError = f.isEmpty ? L10n.Validation.nameEmpty : nil
        createLastNameError  = l.isEmpty ? L10n.Validation.nameEmpty : nil
        createDobError       = createDob == nil ? L10n.Validation.required : nil
        createMRNError       = !mrn.isEmpty && allPatients.contains(where: { $0.mrn.lowercased() == mrn.lowercased() })
                               ? L10n.Validation.mrnDuplicate : nil
        return createFirstNameError == nil && createLastNameError == nil
            && createDobError == nil && createMRNError == nil
    }
}
