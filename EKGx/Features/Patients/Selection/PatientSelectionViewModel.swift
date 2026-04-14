//
//  PatientSelectionViewModel.swift
//  EKGx
//
//  Drives the patient selection flow that precedes an ECG recording.
//  User must search and confirm a patient before navigating to the recording screen.
//

import Foundation

@Observable
@MainActor
final class PatientSelectionViewModel {

    // MARK: - Search Inputs

    var firstName: String = ""
    var lastName: String  = ""
    var dob: Date?        = nil
    var mrn: String       = ""

    // MARK: - State

    var isSearching: Bool = false
    var hasSearched: Bool = false
    var results: [SearchedPatient] = []
    var selected: SearchedPatient? = nil
    var errorMessage: String? = nil

    // Per-field errors
    var firstNameError: String? = nil
    var dobError: String?       = nil

    // MARK: - Create Patient Form

    var showCreatePatient: Bool = false
    var createFirstName: String = ""
    var createLastName: String  = ""
    var createDob: Date?        = nil
    var createGender: String    = "Male"
    var createMRN: String       = ""

    var isCreating: Bool             = false
    var createErrorMessage: String?  = nil
    var createFirstNameError: String? = nil
    var createLastNameError: String?  = nil
    var createDobError: String?       = nil
    var createMRNError: String?       = nil

    let genderOptions: [String] = ["Male", "Female", "Other"]

    // MARK: - Dependencies

    private let patientsService: PatientsService
    private let appInfoService: AppInfoService
    private let diContainer: AppDIContainer
    private let router: AppRouter

    init(patientsService: PatientsService, appInfoService: AppInfoService, diContainer: AppDIContainer, router: AppRouter) {
        self.patientsService = patientsService
        self.appInfoService  = appInfoService
        self.diContainer     = diContainer
        self.router          = router
    }

    // MARK: - Computed

    /// Facility ID comes from the app info (resolved on launch).
    var facilityId: Int64? { appInfoService.facilityId }

    var canConfirm: Bool { selected != nil }

    // MARK: - Actions

    func search() {
        let firstTrim = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mrnTrim   = mrn.trimmingCharacters(in: .whitespacesAndNewlines)

        // Either MRN-only OR (firstName + dob required)
        if mrnTrim.isEmpty {
            firstNameError = firstTrim.isEmpty ? L10n.Validation.nameEmpty : nil
            dobError       = dob == nil        ? L10n.Validation.required  : nil
            guard firstNameError == nil && dobError == nil else { return }
        } else {
            firstNameError = nil
            dobError = nil
        }

        Task { await performSearch() }
    }

    func clearSearch() {
        firstName = ""
        lastName  = ""
        dob       = nil
        mrn       = ""
        results.removeAll()
        selected = nil
        hasSearched = false
        errorMessage = nil
        firstNameError = nil
        dobError = nil
    }

    func select(_ patient: SearchedPatient) {
        selected = patient
    }

    // MARK: - Create Patient Actions

    func openCreatePatient() {
        // Pre-fill from the last search to reduce typing
        createFirstName = firstName
        createLastName  = lastName
        createDob       = dob
        createMRN       = mrn
        createGender    = "Male"
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

    func submitCreatePatient() {
        guard validateCreateInputs() else { return }
        Task { await performCreatePatient() }
    }

    private func validateCreateInputs() -> Bool {
        let f = createFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = createLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let m = createMRN.trimmingCharacters(in: .whitespacesAndNewlines)
        createFirstNameError = f.isEmpty ? L10n.Validation.nameEmpty : nil
        createLastNameError  = l.isEmpty ? L10n.Validation.nameEmpty : nil
        createDobError       = createDob == nil ? L10n.Validation.required : nil
        createMRNError       = m.isEmpty ? L10n.Validation.required : nil
        return [createFirstNameError, createLastNameError, createDobError, createMRNError]
            .allSatisfy { $0 == nil }
    }

    private func performCreatePatient() async {
        isCreating = true
        createErrorMessage = nil
        defer { isCreating = false }

        guard let facId = facilityId else {
            createErrorMessage = L10n.Auth.Register.errorFacilityNotAssigned
            return
        }

        let dobStr = createDob.map { Self.dobFormatter.string(from: $0) } ?? ""

        do {
            let patient = try await patientsService.create(
                firstName: createFirstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName:  createLastName.trimmingCharacters(in: .whitespacesAndNewlines),
                dob:       dobStr,
                gender:    createGender,
                mrn:       createMRN.trimmingCharacters(in: .whitespacesAndNewlines),
                facilityId: facId
            )

            guard let patient else {
                createErrorMessage = L10n.Auth.Login.errorGeneric
                return
            }

            // Inject the new patient into results + auto-select
            let created = SearchedPatient.from(patient)
            if !results.contains(created) {
                results.insert(created, at: 0)
            }
            selected = created
            hasSearched = true
            showCreatePatient = false
        } catch let error as APIError {
            createErrorMessage = error.errorDescription
        } catch {
            createErrorMessage = L10n.Auth.Login.errorGeneric
        }
    }

    func confirm() {
        guard let patient = selected else { return }
        // Stash into DI container so RecordingViewModel can pick it up
        diContainer.lastRecordingPatient = patient.toPatient()
        router.navigate(to: .ecgRecording(patientId: patient.id))
    }

    func navigateBack() {
        router.navigate(to: .dashboard)
    }

    // MARK: - Private

    private func performSearch() async {
        isSearching = true
        errorMessage = nil
        selected = nil
        defer { isSearching = false; hasSearched = true }

        guard let facId = facilityId else {
            // Try to fetch it once more — the prefetch on launch may have failed.
            await appInfoService.getInfo()
            guard let retryId = facilityId else {
                errorMessage = L10n.Auth.Register.errorFacilityNotAssigned
                results = []
                return
            }
            await runSearch(facilityId: retryId)
            return
        }

        await runSearch(facilityId: facId)
    }

    private func runSearch(facilityId: Int64) async {
        let dobString: String? = dob.map { Self.dobFormatter.string(from: $0) }

        do {
            let remote = try await patientsService.search(
                firstName: firstName,
                lastName:  lastName,
                dob:       dobString,
                mrn:       mrn,
                facilityId: facilityId
            )
            results = remote.map { SearchedPatient.from($0) }
            // Auto-select if there's exactly one result
            if results.count == 1 { selected = results.first }
        } catch let error as APIError {
            errorMessage = error.errorDescription
            results = []
        } catch {
            errorMessage = L10n.Auth.Login.errorGeneric
            results = []
        }
    }

    private static let dobFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()
}

// MARK: - SearchedPatient (minimal DTO)

/// Minimal patient shape used by the selection flow. The spec returns a
/// generic `{string: string}` map so we parse defensively.
struct SearchedPatient: Identifiable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let dob: String
    let gender: String
    let mrn: String

    var fullName: String { "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) }

    func toPatient() -> Patient {
        Patient(
            id: Int(id),
            patientId: id,
            uniqueId: id,
            firstName: firstName,
            lastName: lastName,
            birthDate: dob,
            gender: gender,
            medicalRecordNumber: mrn,
            hasPhoto: false
        )
    }

    /// Maps a server-side `RemotePatient` into the selection-screen DTO.
    static func from(_ remote: RemotePatient) -> SearchedPatient {
        SearchedPatient(
            id: remote.uuid ?? remote.emrPatientId ?? String(remote.id ?? 0),
            firstName: remote.firstName ?? "",
            lastName:  remote.lastName ?? "",
            dob:       remote.dob ?? "",
            gender:    remote.gender ?? "",
            mrn:       remote.medicalRecordNumber ?? ""
        )
    }
}
