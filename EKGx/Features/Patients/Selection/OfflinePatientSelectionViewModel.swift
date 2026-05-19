//
//  OfflinePatientSelectionViewModel.swift
//  EKGx
//
//  Drives patient selection in offline (local) mode.
//  No API calls — patients come from LocalPatientStore only.
//

import Foundation

@Observable
@MainActor
final class OfflinePatientSelectionViewModel {

    // MARK: - State

    var selected: LocalPatient? = nil
    var showCreatePatient: Bool = false

    // Create patient form
    var createFirstName: String = ""
    var createLastName: String  = ""
    var createDob: Date?        = nil
    var createGender: String    = "Male"
    var createMRN: String       = ""

    var createFirstNameError: String? = nil
    var createLastNameError: String?  = nil
    var createDobError: String?       = nil

    let genderOptions: [String] = ["Male", "Female", "Other"]

    // MARK: - Dependencies

    let patientStore: LocalPatientStore
    private let diContainer: AppDIContainer
    private let router: AppRouter

    init(patientStore: LocalPatientStore, diContainer: AppDIContainer, router: AppRouter) {
        self.patientStore = patientStore
        self.diContainer  = diContainer
        self.router       = router
    }

    // MARK: - Computed

    var patients: [LocalPatient] { patientStore.patients }
    var canConfirm: Bool { selected != nil }

    // MARK: - Selection

    func select(_ patient: LocalPatient) {
        selected = patient
    }

    func confirm() {
        guard let patient = selected else { return }
        diContainer.lastRecordingPatient = patient.toPatient()
        diContainer.recordingSessionStartedAt = Date()
        router.navigate(to: .ecgRecording(patientId: patient.id))
    }

    func navigateBack() {
        router.navigate(to: .dashboard)
    }

    // MARK: - Create Patient

    func openCreatePatient() {
        createFirstName = ""
        createLastName  = ""
        createDob       = nil
        createGender    = "Male"
        createMRN       = ""
        createFirstNameError = nil
        createLastNameError  = nil
        createDobError       = nil
        showCreatePatient    = true
    }

    func cancelCreatePatient() {
        showCreatePatient = false
    }

    func submitCreatePatient() {
        guard validateCreate() else { return }
        let dobStr = createDob.map { Self.dobFormatter.string(from: $0) } ?? ""
        let patient = LocalPatient(
            id: UUID().uuidString,
            firstName: createFirstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName:  createLastName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: dobStr,
            gender:    createGender,
            mrn:       createMRN.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        patientStore.add(patient)
        selected = patient
        showCreatePatient = false
    }

    private func validateCreate() -> Bool {
        let f = createFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = createLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        createFirstNameError = f.isEmpty ? L10n.Validation.nameEmpty : nil
        createLastNameError  = l.isEmpty ? L10n.Validation.nameEmpty : nil
        createDobError       = createDob == nil ? L10n.Validation.required : nil
        return createFirstNameError == nil && createLastNameError == nil && createDobError == nil
    }

    private static let dobFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f
    }()
}
