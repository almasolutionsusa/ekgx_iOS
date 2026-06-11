//
//  AnalysisViewModel.swift
//  EKGx
//

import Foundation
import SwiftUI
import UIKit

private extension Patient {
    var genderSDK: vhECGPatientGender {
        switch gender.lowercased() {
        case "f", "female": return .female
        default:            return .male
        }
    }
}

// MARK: - Visualization Mode

enum VisualizationMode {
    case standard       // normal 3×4 grid
    case table          // lead params table overlay
    case layers         // merged/overlay waveform
}

// MARK: - AnalysisViewModel

@Observable
@MainActor
final class AnalysisViewModel {

    // MARK: - Analysis state

    enum AnalysisState { case analyzing, success, failed }
    private(set) var state: AnalysisState = .analyzing

    // MARK: - UI state

    var showControlsMenu: Bool = false
    var showDiagnosisPanel: Bool = false
    var showVisualizationMenu: Bool = false
    var showRejectConfirm: Bool = false
    var visualizationMode: VisualizationMode = .standard

    // Editable diagnosis — user can add/remove items
    var diagnosisLines: [String] = []

    // MARK: - Upload state

    var isUploading: Bool = false
    var uploadSuccess: Bool = false
    var uploadError: String? = nil
    var showUploadResult: Bool = false

    // MARK: - Emergency Session

    let isEmergencySession: Bool
    private let emergencyReturnRoute: AppRoute
    private let recordingIsEmergency: Bool

    /// True when the emergency banner should be visible — live session OR a stored emergency exam.
    var showEmergencyBanner: Bool { isEmergencySession || recordingIsEmergency }

    // PIN gate (shown when anonymous user taps "Send to EMR")
    var showEmergencyPinSheet: Bool = false
    var emergencyPinInput: String = ""
    var emergencyPinError: String? = nil
    private(set) var isPinVerified: Bool = false

    // Patient assignment (shown after PIN verified)
    var showAssignPatientSheet: Bool = false
    var assignedPatient: Patient? = nil

    // Patient list state for the assignment sheet
    var assignSearchQuery: String = "" { didSet { filterAssignPatients() } }
    private var allAssignPatients: [LocalPatient] = []
    var filteredAssignPatients: [LocalPatient] = []
    var isLoadingAssignPatients: Bool = false

    // Create patient inside assignment sheet
    var showEmergencyCreatePatient: Bool = false
    var ecFirstName: String = ""
    var ecLastName: String = ""
    var ecDob: Date? = nil
    var ecGender: String = "Male"
    var ecMRN: String = ""
    var isEmergencyCreating: Bool = false
    var emergencyCreateError: String? = nil

    /// True when the local recording is already synced — upload button should be disabled.
    var isAlreadySynced: Bool {
        guard let id = localRecordingId else { return false }
        return recordingStore.status(for: id) == .synced
    }

    /// True when the app is in offline mode — upload must be disabled regardless of sync state.
    let isLocalMode: Bool

    var performedBy: String {
        guard let id = localRecordingId else { return "" }
        return patientExams.first(where: { $0.id == id })?.username ?? ""
    }

    // MARK: - Exam History

    var patientExams: [ECGRecording] = []
    var showExamHistory = false

    // Compare
    var compareRecording: ECGRecording?
    var compareECGData: ECGLeads = []
    var showCompareView = false
    private var pendingCompare = false

    // MARK: - Data

    private(set) var patient: Patient
    var ecgData: ECGLeads
    var sampleRate: Int

    private(set) var analysis: vhECGAnalysisObject?
    private(set) var measurements: vhMeasurements?
    private(set) var leadParameters: vhParameters?
    private(set) var templateData: ECGLeads = []
    // Plain Swift strings — @Observable tracks these natively, updated after every re-analysis.
    // vhMeasurements is an ObjC object mutated in-place, so SwiftUI can't observe it directly.
    var mergeHR:     String = "—"
    var mergePR:     String = "—"
    var mergeQRS:    String = "—"
    var mergeQT:     String = "—"
    var mergeQTc:    String = "—"
    var mergePaxis:  String = "—"
    var mergeQRSaxis:String = "—"
    var mergeTaxis:  String = "—"

    private let router: AppRouter
    private let uploadService: EKGUploadService
    private let checkinService: AppCheckinService
    private let recordingStore: LocalRecordingStore
    private let authService: AuthServiceProtocol
    private let patientRepository: PatientRepositoryProtocol?
    /// The locally persisted recording created when analysis starts.
    private(set) var localRecordingId: String? = nil

    // MARK: - Init

    let totalDuration: Int?

    init(
        patient: Patient,
        ecgData: ECGLeads,
        sampleRate: Int = 660,
        totalDuration: Int? = nil,
        existingRecordingId: String? = nil,
        isLocalMode: Bool = false,
        isEmergencySession: Bool = false,
        emergencyReturnRoute: AppRoute = AppRoute.login,
        recordingIsEmergency: Bool = false,
        patientRepository: PatientRepositoryProtocol? = nil,
        router: AppRouter,
        uploadService: EKGUploadService,
        checkinService: AppCheckinService,
        recordingStore: LocalRecordingStore,
        authService: AuthServiceProtocol
    ) {
        self.patient               = patient
        self.ecgData               = ecgData
        self.sampleRate            = sampleRate
        self.totalDuration         = totalDuration
        self.localRecordingId      = existingRecordingId
        self.isLocalMode           = isLocalMode
        self.isEmergencySession    = isEmergencySession
        self.emergencyReturnRoute  = emergencyReturnRoute
        self.recordingIsEmergency  = recordingIsEmergency
        self.patientRepository     = patientRepository
        self.router                = router
        self.uploadService         = uploadService
        self.checkinService        = checkinService
        self.recordingStore        = recordingStore
        self.authService           = authService
    }

    // MARK: - Analysis

    func runAnalysis() {
        guard state == .analyzing else { return }

        let data   = ecgData
        let rate   = sampleRate
        let age    = patient.ageYears
        let gender = patient.genderSDK

        Task.detached(priority: .userInitiated) { [weak self] in
            let obj     = vhECGAnalysisObject()
            let success = obj.analysisECG(data, withRate: rate, withPatientAge: age, with: gender)

            await MainActor.run { [weak self] in
                guard let self else { return }
                let template: ECGLeads = obj.templateAnalysisResult.templateData() as? [[NSNumber]] ?? []
                if success, !template.isEmpty {
                    self.analysis        = obj
                    self.diagnosisLines  = obj.interpretation as? [String] ?? []
                    self.measurements    = obj.measurementsResult
                    self.leadParameters  = obj.parametersResult
                    self.templateData    = template
                    self.copyMergeStrings(from: obj.measurementsResult)
                    self.state           = .success
                    self.saveLocalRecording()
                    self.loadPatientExams()
                } else {
                    self.state = .failed
                }
            }
        }
    }

    // MARK: - Upload

    func uploadEKG() {
        guard !isUploading else { return }

        // Emergency gate 1: require PIN before upload
        if isEmergencySession && !isPinVerified {
            emergencyPinInput = ""
            emergencyPinError = nil
            showEmergencyPinSheet = true
            return
        }
        // Emergency gate 2: require patient assignment
        if isEmergencySession && assignedPatient == nil {
            showAssignPatientSheet = true
            return
        }

        isUploading = true
        uploadError = nil
        showUploadResult = false

        // Render the PDF on @MainActor before entering the async Task
        let pdfData = renderECGPDF()

        Task {
            do {
                try await authService.ensureValidToken()

                let appUuid = checkinService.appUuid
                let fileData = EKGUploadService.serialise(ecgData: ecgData)
                let m = measurements?.merge

                // Use the assigned patient in emergency mode, otherwise the original patient
                let uploadPatient = assignedPatient ?? patient

                var payload = EKGUploadPayload(
                    patientUuid: uploadPatient.patientId ?? uploadPatient.uniqueId ?? "",
                    appUuid: appUuid
                )
                payload.firstName           = uploadPatient.firstName.nilIfEmpty
                payload.lastName            = uploadPatient.lastName.nilIfEmpty
                payload.dob                 = uploadPatient.birthDate.nilIfEmpty
                payload.gender              = uploadPatient.gender.nilIfEmpty
                payload.medicalRecordNumber = uploadPatient.medicalRecordNumber
                payload.heartRate   = nilIfEmpty(m?.hr)
                payload.rrInterval  = nilIfEmpty(m?.rr)
                payload.prInterval  = nilIfEmpty(m?.pr)
                payload.qrsDuration = nilIfEmpty(m?.qrs)
                payload.pDuration   = nilIfEmpty(m?.pd)
                payload.qtInterval  = nilIfEmpty(m?.qt)
                payload.qtCorrected = nilIfEmpty(m?.qTc)
                payload.qtDistance  = nilIfEmpty(m?.qTd)
                payload.qtMax       = nilIfEmpty(measurements?.qTmaxLeadValue)
                payload.qtMin       = nilIfEmpty(measurements?.qTminLeadValue)
                payload.pAxis       = nilIfEmpty(m?.paxis)
                payload.qrsAxis     = nilIfEmpty(m?.qrSaxis)
                payload.rv1         = nilIfEmpty(m?.rv1)
                payload.rv5         = nilIfEmpty(m?.rv5)
                payload.sv1         = nilIfEmpty(m?.sv1)
                payload.sv5         = nilIfEmpty(m?.sv5)
                payload.diagnosis   = diagnosisLines.isEmpty ? nil : diagnosisLines.joined(separator: "; ")
                payload.duration      = String(ecgData.first?.count ?? 0)
                payload.totalDuration = totalDuration.map { String($0) }
                payload.recordedAt  = Date()
                payload.appVersion  = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                payload.fileData    = fileData
                payload.pdfData     = pdfData

                print("── EKG Upload Payload ──────────────────")
                print("  emergency           : \(isEmergencySession) assignedPatient=\(assignedPatient?.firstName ?? "none")")
                print("  patientUuid         : \(payload.patientUuid)")
                print("  appUuid             : \(payload.appUuid)")
                print("  firstName           : \(payload.firstName ?? "nil")")
                print("  lastName            : \(payload.lastName ?? "nil")")
                print("  dob                 : \(payload.dob ?? "nil")")
                print("  gender              : \(payload.gender ?? "nil")")
                print("  medicalRecordNumber : \(payload.medicalRecordNumber ?? "nil")")
                print("  heartRate   : \(payload.heartRate ?? "nil")")
                print("  rrInterval  : \(payload.rrInterval ?? "nil")")
                print("  prInterval  : \(payload.prInterval ?? "nil")")
                print("  qrsDuration : \(payload.qrsDuration ?? "nil")")
                print("  pDuration   : \(payload.pDuration ?? "nil")")
                print("  qtInterval  : \(payload.qtInterval ?? "nil")")
                print("  qtCorrected : \(payload.qtCorrected ?? "nil")")
                print("  qtDistance  : \(payload.qtDistance ?? "nil")")
                print("  qtMax       : \(payload.qtMax ?? "nil")")
                print("  qtMin       : \(payload.qtMin ?? "nil")")
                print("  pAxis       : \(payload.pAxis ?? "nil")")
                print("  qrsAxis     : \(payload.qrsAxis ?? "nil")")
                print("  rv1         : \(payload.rv1 ?? "nil")")
                print("  rv5         : \(payload.rv5 ?? "nil")")
                print("  sv1         : \(payload.sv1 ?? "nil")")
                print("  sv5         : \(payload.sv5 ?? "nil")")
                print("  diagnosis   : \(payload.diagnosis ?? "nil")")
                print("  duration      : \(payload.duration ?? "nil")")
                print("  totalDuration : \(payload.totalDuration ?? "nil")")
                print("  appVersion  : \(payload.appVersion ?? "nil")")
                print("  recordedAt  : \(payload.recordedAt?.description ?? "nil")")
                print("  fileData    : \(payload.fileData?.count ?? 0) bytes")
                print("  pdfData     : \(payload.pdfData?.count ?? 0) bytes")
                print("────────────────────────────────────────")

                try await uploadService.upload(payload: payload)
                uploadSuccess = true
                if let rid = localRecordingId {
                    recordingStore.updateStatus(id: rid, status: .synced)
                }
            } catch let error as APIError {
                print("❌ uploadEKG APIError: \(error)")
                switch error {
                case .sessionExpired, .invalidCredentials:
                    uploadError = L10n.Auth.Login.errorSessionExpired
                default:
                    uploadError = error.errorDescription ?? L10n.Auth.Login.errorGeneric
                }
                uploadSuccess = false
                if let rid = localRecordingId {
                    recordingStore.updateStatus(id: rid, status: .failed)
                }
            } catch {
                print("❌ uploadEKG error: \(error)")
                uploadError = L10n.Auth.Login.errorGeneric
                uploadSuccess = false
                if let rid = localRecordingId {
                    recordingStore.updateStatus(id: rid, status: .failed)
                }
            }
            isUploading = false
            showUploadResult = true
        }
    }

    private func renderECGPDF() -> Data? {
        ECGImageRenderer.renderPDF(
            ecgData: ecgData,
            patient: patient,
            sampleRate: sampleRate,
            measurements: measurements,
            diagnosisLines: diagnosisLines,
            performedBy: performedBy,
            isEmergency: showEmergencyBanner
        )
    }

    private func saveLocalRecording() {
        guard localRecordingId == nil else { return }
        let m = measurements?.merge
        let fileData = EKGUploadService.serialise(ecgData: ecgData)
        let pdf = renderECGPDF()
        let recording = ECGRecording.makePending(
            patient:        patient,
            durationSeconds: (ecgData.first?.count ?? 0) / max(sampleRate, 1),
            sampleRate:     sampleRate,
            diagnosis:      diagnosisLines.isEmpty ? nil : diagnosisLines.joined(separator: "; "),
            heartRate:      nilIfEmpty(m?.hr),
            prInterval:     nilIfEmpty(m?.pr),
            qrsDuration:    nilIfEmpty(m?.qrs),
            qtInterval:     nilIfEmpty(m?.qt),
            qtCorrected:    nilIfEmpty(m?.qTc),
            fileSize:       fileData.count,
            appVersion:     Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            username: {
                let u = authService.currentUser
                let full = [u?.firstName, u?.lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
                return full.isEmpty ? u?.username : full
            }(),
            isEmergency:    isEmergencySession
        )
        recordingStore.save(recording: recording, ecgFileData: fileData, pdfData: pdf)
        localRecordingId = recording.id
    }

    private func nilIfEmpty(_ s: String?) -> String? {
        guard let s, !s.isEmpty, s != "—" else { return nil }
        return s
    }

    // MARK: - Exam History & Compare

    func loadPatientExams() {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        guard !pid.isEmpty else { return }
        patientExams = recordingStore.recordings(for: pid)
    }

    func switchToExam(_ recording: ECGRecording) {
        guard let raw = recordingStore.ecgFileData(for: recording.id) else { return }
        let leads = EKGUploadService.deserialise(data: raw, leadCount: recording.leadCount)
        guard !leads.isEmpty else { return }
        ecgData          = leads
        sampleRate       = recording.sampleRate
        localRecordingId = recording.id
        showExamHistory  = false
        analysis         = nil
        measurements     = nil
        templateData     = []
        leadParameters   = nil
        diagnosisLines   = []
        state            = .analyzing
        runAnalysis()
    }

    func startCompare(with recording: ECGRecording) {
        guard let raw = recordingStore.ecgFileData(for: recording.id) else { return }
        let leads = EKGUploadService.deserialise(data: raw, leadCount: recording.leadCount)
        guard !leads.isEmpty else { return }
        compareECGData   = leads
        compareRecording = recording
        pendingCompare   = true
        // showCompareView is set via onDismiss in AnalysisView after history sheet fully closes
        showExamHistory  = false
    }

    func openCompareIfPending() {
        guard pendingCompare else { return }
        pendingCompare  = false
        showCompareView = true
    }

    // MARK: - Navigation

    func goBack() {
        if isEmergencySession {
            router.navigate(to: emergencyReturnRoute)
            return
        }
        let dest = router.analysisReturnRoute
        router.analysisReturnRoute = .patientSelection
        router.navigate(to: dest)
    }

    func confirmReject() {
        if isEmergencySession {
            router.navigate(to: emergencyReturnRoute)
            return
        }
        let dest = router.analysisReturnRoute
        router.analysisReturnRoute = .patientSelection
        router.navigate(to: dest)
    }

    // MARK: - Emergency PIN Gate

    func emergencyKeypadInput(_ digit: String) {
        guard emergencyPinInput.count < 6 else { return }
        emergencyPinInput += digit
        emergencyPinError = nil
        if emergencyPinInput.count == 6 { submitEmergencyPin() }
    }

    func emergencyKeypadDelete() {
        guard !emergencyPinInput.isEmpty else { return }
        emergencyPinInput.removeLast()
    }

    func submitEmergencyPin() {
        guard LocalUserStore.shared.hasPin else {
            emergencyPinError = L10n.Auth.Login.pinNotSetup
            emergencyPinInput = ""
            return
        }
        guard LocalUserStore.shared.validatePin(emergencyPinInput) else {
            emergencyPinError = L10n.Auth.Login.pinErrorInvalid
            emergencyPinInput = ""
            return
        }

        isPinVerified = true
        emergencyPinInput = ""
        showEmergencyPinSheet = false

        // PIN proved identity locally. Now do a full server login using the stored
        // email+password so the upload has a real JWT token.
        Task {
            let store = LocalUserStore.shared
            // Password is saved under the login input (email or username).
            // Try the stored email key first, then username as fallback.
            let loginId  = store.email ?? store.username ?? ""
            let password = store.storedPassword(for: loginId)
                        ?? store.username.flatMap { store.storedPassword(for: $0) }

            if !loginId.isEmpty, let password {
                try? await authService.login(email: loginId, password: password)
            } else {
                // No stored credentials — restore in-memory session only.
                // The upload will surface its own auth error.
                authService.restoreLocalSession(
                    username:     store.username ?? "",
                    email:        store.email,
                    facilityId:   store.facilityId,
                    facilityName: store.facilityName
                )
            }
            showAssignPatientSheet = true
        }
    }

    // MARK: - Emergency Patient Assignment

    func loadPatientsForAssignment() {
        guard let repo = patientRepository else { return }
        Task {
            isLoadingAssignPatients = true
            allAssignPatients = (try? await repo.fetchAll()) ?? []
            filterAssignPatients()
            isLoadingAssignPatients = false
        }
    }

    private func filterAssignPatients() {
        let q = assignSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let base = allAssignPatients.filter { $0.mrn != "000000" }
        filteredAssignPatients = q.isEmpty ? base : base.filter {
            $0.firstName.lowercased().contains(q) ||
            $0.lastName.lowercased().contains(q) ||
            $0.mrn.lowercased().contains(q)
        }
    }

    func confirmPatientAssignment(_ patient: LocalPatient) {
        let resolved = patient.toPatient()
        assignedPatient = resolved
        showAssignPatientSheet = false
        // Update the local Core Data record so it no longer shows as anonymous.
        if let rid = localRecordingId {
            recordingStore.updatePatient(id: rid, patient: resolved)
        }
        uploadEKG()
    }

    // MARK: - Emergency Create Patient

    func submitEmergencyCreatePatient() {
        guard !isEmergencyCreating else { return }
        emergencyCreateError = nil
        guard !ecFirstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !ecLastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              ecDob != nil else {
            emergencyCreateError = L10n.Validation.required
            return
        }
        guard let repo = patientRepository else { return }
        isEmergencyCreating = true
        Task {
            defer { isEmergencyCreating = false }
            let dobStr = LocalPatient.dateFormatter.string(from: ecDob ?? Date())
            let input = NewPatientInput(
                firstName: ecFirstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName:  ecLastName.trimmingCharacters(in: .whitespacesAndNewlines),
                birthDate: dobStr,
                gender:    ecGender,
                mrn:       ecMRN.trimmingCharacters(in: .whitespacesAndNewlines),
                createdBy: authService.currentUser?.displayName.isEmpty == false
                    ? authService.currentUser!.displayName
                    : authService.currentUser?.username ?? "emergency"
            )
            do {
                let created = try await repo.add(input)
                showEmergencyCreatePatient = false
                confirmPatientAssignment(created)
            } catch {
                emergencyCreateError = error.localizedDescription
            }
        }
    }

    func cancelEmergencyCreate() {
        showEmergencyCreatePatient = false
        emergencyCreateError = nil
    }

    // MARK: - Helpers

    var leadNames: [String] {
        ["I","II","III","aVR","aVL","aVF","V1","V2","V3","V4","V5","V6"]
    }

    var orderedLeadParams: [vhLeadParameter] {
        guard let p = leadParameters else { return [] }
        return p.leadsParameterArray() as [vhLeadParameter]
    }

    // MARK: - Manual re-analysis (called after dragging beat markers)

    func reanalyseLead(_ lead: vhLeadTemplate) {
        guard let obj = analysis else { return }
        if obj.manualAnalisysLead(lead) {
            measurements   = obj.measurementsResult
            leadParameters = obj.parametersResult
            copyMergeStrings(from: obj.measurementsResult)
        }
    }

    func reanalyseAllLeads() {
        guard let obj = analysis else { return }
        if obj.manualAnalysisAllLead() {
            measurements   = obj.measurementsResult
            leadParameters = obj.parametersResult
            copyMergeStrings(from: obj.measurementsResult)
        }
    }

    private func copyMergeStrings(from m: vhMeasurements) {
        let c = m.merge
        mergeHR      = c.hr.isEmpty      ? "—" : c.hr
        mergePR      = c.pr.isEmpty      ? "—" : c.pr
        mergeQRS     = c.qrs.isEmpty     ? "—" : c.qrs
        mergeQT      = c.qt.isEmpty      ? "—" : c.qt
        mergeQTc     = c.qTc.isEmpty     ? "—" : c.qTc
        mergePaxis   = c.paxis.isEmpty   ? "—" : c.paxis
        mergeQRSaxis = c.qrSaxis.isEmpty ? "—" : c.qrSaxis
        mergeTaxis   = c.taxis.isEmpty   ? "—" : c.taxis
    }
}
