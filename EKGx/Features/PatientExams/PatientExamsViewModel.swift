import Foundation

// MARK: - ExamRecord

enum ExamRecord: Identifiable {
    case ekg(ECGRecording)
    case bp(BPRecording)

    var id: String {
        switch self {
        case .ekg(let r): return r.id
        case .bp(let r):  return r.id
        }
    }

    var recordedAt: Date {
        switch self {
        case .ekg(let r): return r.recordedAt
        case .bp(let r):  return r.recordedAt
        }
    }
}

// MARK: - PatientExamsViewModel

@Observable
@MainActor
final class PatientExamsViewModel {

    // MARK: - State

    let patient: Patient
    var recordings:  [ECGRecording] = []
    var bpReadings:  [BPRecording]  = []
    var selectedVitalType: VitalType? = nil
    var uploadingIds: Set<String> = []
    var recordingToDelete:   ECGRecording? = nil
    var bpReadingToDelete:   BPRecording?  = nil
    var showDeleteConfirm: Bool = false

    // MARK: - Dependencies

    private let recordingStore: LocalRecordingStore
    private let router: AppRouter
    private let diContainer: AppDIContainer

    init(patient: Patient,
         recordingStore: LocalRecordingStore,
         router: AppRouter,
         diContainer: AppDIContainer) {
        self.patient        = patient
        self.recordingStore = recordingStore
        self.router         = router
        self.diContainer    = diContainer
    }

    // MARK: - Lifecycle

    func activate() { load() }
    func refresh()  { load() }

    private func load() {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        recordings = pid.isEmpty ? [] : recordingStore.recordings(for: pid)
        bpReadings = pid.isEmpty ? [] : diContainer.bpStore.readings(for: pid)
    }

    // MARK: - Computed

    var isLocalMode: Bool { diContainer.isLocalMode }
    var examCount: Int { recordings.count + bpReadings.count }

    var availableVitalTypes: [VitalType] {
        var types: [VitalType] = []
        if !recordings.isEmpty  { types.append(.ekg) }
        if !bpReadings.isEmpty  { types.append(.bloodPressure) }
        return types
    }

    var filteredRecordings: [ExamRecord] {
        let all: [ExamRecord] = recordings.map { .ekg($0) } + bpReadings.map { .bp($0) }
        let sorted = all.sorted { $0.recordedAt > $1.recordedAt }
        guard let type = selectedVitalType else { return sorted }
        return sorted.filter {
            switch ($0, type) {
            case (.ekg,  .ekg):           return true
            case (.bp,   .bloodPressure): return true
            default:                      return false
            }
        }
    }

    // MARK: - Open EKG in Analysis (read-only)

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

    // MARK: - Upload EKG

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

    func confirmDeleteBP(_ reading: BPRecording) {
        bpReadingToDelete = reading
        showDeleteConfirm = true
    }

    func deleteConfirmed() {
        if let r = recordingToDelete {
            recordingStore.delete(id: r.id)
            recordings.removeAll { $0.id == r.id }
            recordingToDelete = nil
        } else if let r = bpReadingToDelete {
            diContainer.bpStore.delete(id: r.id)
            bpReadings.removeAll { $0.id == r.id }
            bpReadingToDelete = nil
        }
    }

    func cancelDelete() {
        recordingToDelete  = nil
        bpReadingToDelete  = nil
        showDeleteConfirm  = false
    }

    // MARK: - Navigation

    func navigateBack() {
        let destination = router.patientExamsReturnRoute
        router.patientExamsReturnRoute = .vitals
        router.navigate(to: destination)
    }
}
