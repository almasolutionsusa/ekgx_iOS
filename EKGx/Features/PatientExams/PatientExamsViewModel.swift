import Foundation

@Observable
@MainActor
final class PatientExamsViewModel {

    // MARK: - State

    let patient: Patient
    var recordings: [ECGRecording] = []
    var selectedVitalType: VitalType? = nil   // nil = All
    var uploadingIds: Set<String> = []
    var recordingToDelete: ECGRecording? = nil
    var showDeleteConfirm: Bool = false

    // MARK: - Dependencies

    private let recordingStore: LocalRecordingStore
    private let router: AppRouter
    private let diContainer: AppDIContainer

    init(patient: Patient, recordingStore: LocalRecordingStore, router: AppRouter, diContainer: AppDIContainer) {
        self.patient       = patient
        self.recordingStore = recordingStore
        self.router        = router
        self.diContainer   = diContainer
    }

    // MARK: - Lifecycle

    func activate() { load() }

    func refresh() { load() }

    private func load() {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        recordings = pid.isEmpty ? [] : recordingStore.recordings(for: pid)
    }

    // MARK: - Computed

    var isLocalMode: Bool { diContainer.isLocalMode }
    var examCount: Int { recordings.count }

    // Vital types that actually have recordings — drives the filter strip.
    // When Echo recordings are added, extend this to read a vitalType field from ECGRecording.
    var availableVitalTypes: [VitalType] {
        recordings.isEmpty ? [] : [.ekg]
    }

    var filteredRecordings: [ECGRecording] {
        guard let type = selectedVitalType else { return recordings }
        return type == .ekg ? recordings : []
    }

    // MARK: - Open in Analysis (read-only)

    func openRecording(_ recording: ECGRecording) {
        let rawData = recordingStore.ecgFileData(for: recording.id)
        let leads: ECGLeads
        if let raw = rawData, !raw.isEmpty {
            leads = EKGUploadService.deserialise(data: raw, leadCount: recording.leadCount)
        } else {
            leads = []
        }
        diContainer.lastRecordingPatient        = patient
        diContainer.lastRecordingData           = leads
        diContainer.lastRecordingSampleRate     = recording.sampleRate
        diContainer.lastRecordingTotalDuration  = nil
        diContainer.lastRecordingExistingId     = recording.id
        router.analysisReturnRoute = .patientExams
        router.navigate(to: .ecgAnalysis(recordingId: recording.id))
    }

    // MARK: - Upload

    func uploadRecording(_ recording: ECGRecording) {
        guard recording.status != .synced, !uploadingIds.contains(recording.id) else { return }
        uploadingIds.insert(recording.id)
        Task {
            do {
                try await diContainer.authService.ensureValidToken()

                let rawData = recordingStore.ecgFileData(for: recording.id)
                let pdfData = recordingStore.pdfData(for: recording.id)
                let appUuid = diContainer.checkinService.appUuid
                var payload = EKGUploadPayload(patientUuid: recording.patientId, appUuid: appUuid)
                payload.firstName           = recording.patientName.components(separatedBy: " ").first
                payload.lastName            = recording.patientName.components(separatedBy: " ").dropFirst().joined(separator: " ").nilIfEmpty
                payload.dob                 = recording.patientDob.nilIfEmpty
                payload.gender              = recording.patientGender.nilIfEmpty
                payload.medicalRecordNumber = recording.patientMrn
                payload.heartRate   = recording.heartRate
                payload.prInterval  = recording.prInterval
                payload.qrsDuration = recording.qrsDuration
                payload.qtInterval  = recording.qtInterval
                payload.qtCorrected = recording.qtCorrected
                payload.diagnosis   = recording.diagnosis
                payload.duration    = String(recording.durationSeconds)
                payload.appVersion  = recording.appVersion
                payload.recordedAt  = recording.recordedAt
                payload.fileData    = rawData
                payload.pdfData     = pdfData
                try await diContainer.ekgUploadService.upload(payload: payload)
                recordingStore.updateStatus(id: recording.id, status: .synced)
                load()
            } catch {
                recordingStore.updateStatus(id: recording.id, status: .failed)
                load()
            }
            uploadingIds.remove(recording.id)
        }
    }

    // MARK: - Delete

    func confirmDelete(_ recording: ECGRecording) {
        recordingToDelete  = recording
        showDeleteConfirm  = true
    }

    func deleteConfirmed() {
        guard let recording = recordingToDelete else { return }
        recordingStore.delete(id: recording.id)
        recordings.removeAll { $0.id == recording.id }
        recordingToDelete = nil
    }

    func cancelDelete() {
        recordingToDelete = nil
        showDeleteConfirm = false
    }

    // MARK: - Navigation

    func navigateBack() {
        let destination = router.patientExamsReturnRoute
        router.patientExamsReturnRoute = .vitals  // reset to default for next time
        router.navigate(to: destination)
    }
}
