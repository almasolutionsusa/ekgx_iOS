import Foundation

// MARK: - DateRangeFilter

enum DateRangeFilter: Equatable {
    case all
    case today
    case last7Days
    case last30Days
    case custom(from: Date, to: Date)

    var label: String {
        switch self {
        case .all:        return L10n.PatientExams.Date.allDates
        case .today:      return L10n.PatientExams.Date.today
        case .last7Days:  return L10n.PatientExams.Date.last7Days
        case .last30Days: return L10n.PatientExams.Date.last30Days
        case .custom:     return L10n.PatientExams.filterCustom
        }
    }

    var icon: String {
        switch self {
        case .all:        return "calendar"
        case .today:      return "sun.max"
        case .last7Days:  return "calendar.badge.clock"
        case .last30Days: return "calendar.badge.clock"
        case .custom:     return "slider.horizontal.3"
        }
    }

    func includes(_ date: Date) -> Bool {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .all:        return true
        case .today:      return cal.isDateInToday(date)
        case .last7Days:  return date >= cal.date(byAdding: .day, value: -7, to: now)!
        case .last30Days: return date >= cal.date(byAdding: .day, value: -30, to: now)!
        case .custom(let from, let to):
            let start = cal.startOfDay(for: from)
            let end   = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: to))!
            return date >= start && date < end
        }
    }
}

// MARK: - ExamRecord

enum ExamRecord: Identifiable {
    case ekg(ECGRecording)
    case bp(BPRecording)
    case spo2(SpO2Reading)
    case temp(TempReading)
    case rr(RRReading)
    case pain(PainReading)
    case weight(WeightReading)
    case height(HeightReading)

    var id: String {
        switch self {
        case .ekg(let r):  return r.id
        case .bp(let r):   return r.id
        case .spo2(let r): return r.id
        case .temp(let r): return r.id
        case .rr(let r):   return r.id
        case .pain(let r):   return r.id
        case .weight(let r): return r.id
        case .height(let r): return r.id
        }
    }

    var recordedAt: Date {
        switch self {
        case .ekg(let r):    return r.recordedAt
        case .bp(let r):     return r.recordedAt
        case .spo2(let r):   return r.recordedAt
        case .temp(let r):   return r.recordedAt
        case .rr(let r):     return r.recordedAt
        case .pain(let r):   return r.recordedAt
        case .weight(let r): return r.recordedAt
        case .height(let r): return r.recordedAt
        }
    }
}

// MARK: - PatientExamsViewModel

@Observable
@MainActor
final class PatientExamsViewModel {

    // MARK: - State

    let patient: Patient
    var recordings:    [ECGRecording] = []
    var bpReadings:    [BPRecording]  = []
    var spo2Readings:  [SpO2Reading]  = []
    var tempReadings:  [TempReading]  = []
    var rrReadings:    [RRReading]    = []
    var painReadings:   [PainReading]   = []
    var weightReadings: [WeightReading] = []
    var heightReadings: [HeightReading] = []
    var selectedVitalType: VitalType? = nil
    var dateFilter: DateRangeFilter = .all
    var customFromDate: Date = Calendar.current.startOfDay(for: Date())
    var customToDate: Date = Date()
    var uploadingIds: Set<String> = []
    var recordingToDelete:   ECGRecording? = nil
    var bpReadingToDelete:   BPRecording?  = nil
    var spo2ReadingToDelete: SpO2Reading?  = nil
    var tempReadingToDelete: TempReading?  = nil
    var rrReadingToDelete:   RRReading?    = nil
    var painReadingToDelete:   PainReading?   = nil
    var weightReadingToDelete: WeightReading? = nil
    var heightReadingToDelete: HeightReading? = nil
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
        load()
    }

    // MARK: - Lifecycle

    func activate() { load() }
    func refresh()  { load() }

    private func load() {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        guard !pid.isEmpty else { return }
        recordings   = recordingStore.recordings(for: pid)
        bpReadings   = diContainer.bpStore.readings(for: pid)
        spo2Readings = diContainer.spo2Store.readings(for: pid)
        tempReadings = diContainer.tempStore.readings(for: pid)
        rrReadings   = diContainer.rrStore.readings(for: pid)
        painReadings   = diContainer.painStore.readings(for: pid)
        weightReadings = diContainer.weightStore.readings(for: pid)
        heightReadings = diContainer.heightStore.readings(for: pid)
    }

    // MARK: - Computed

    var isLocalMode: Bool { diContainer.isLocalMode }
    var examCount: Int {
        recordings.count + bpReadings.count + spo2Readings.count +
        tempReadings.count + rrReadings.count + painReadings.count +
        weightReadings.count + heightReadings.count
    }

    var availableVitalTypes: [VitalType] {
        var types: [VitalType] = []
        if !recordings.isEmpty   { types.append(.ekg) }
        if !bpReadings.isEmpty   { types.append(.bloodPressure) }
        if !spo2Readings.isEmpty { types.append(.oxygenSaturation) }
        if !tempReadings.isEmpty { types.append(.temperature) }
        if !rrReadings.isEmpty   { types.append(.respirations) }
        if !painReadings.isEmpty   { types.append(.painLevel) }
        if !weightReadings.isEmpty { types.append(.weight) }
        if !heightReadings.isEmpty { types.append(.height) }
        return types
    }

    var filteredRecordings: [ExamRecord] {
        let all: [ExamRecord] =
            recordings.map    { .ekg($0)    } +
            bpReadings.map    { .bp($0)     } +
            spo2Readings.map  { .spo2($0)   } +
            tempReadings.map  { .temp($0)   } +
            rrReadings.map    { .rr($0)     } +
            painReadings.map  { .pain($0)   } +
            weightReadings.map { .weight($0) } +
            heightReadings.map { .height($0) }
        let activeDate: DateRangeFilter
        if case .custom = dateFilter {
            activeDate = .custom(from: customFromDate, to: customToDate)
        } else {
            activeDate = dateFilter
        }

        let sorted = all
            .filter { activeDate.includes($0.recordedAt) }
            .sorted { $0.recordedAt > $1.recordedAt }

        guard let type = selectedVitalType else { return sorted }
        return sorted.filter {
            switch ($0, type) {
            case (.ekg,  .ekg):              return true
            case (.bp,   .bloodPressure):    return true
            case (.spo2, .oxygenSaturation): return true
            case (.temp, .temperature):      return true
            case (.rr,   .respirations):     return true
            case (.pain,   .painLevel):  return true
            case (.weight, .weight):     return true
            case (.height, .height):     return true
            default:                     return false
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

    func confirmDeleteBP(_ reading: BPRecording)       { bpReadingToDelete   = reading; showDeleteConfirm = true }
    func confirmDeleteSpO2(_ reading: SpO2Reading)     { spo2ReadingToDelete = reading; showDeleteConfirm = true }
    func confirmDeleteTemp(_ reading: TempReading)     { tempReadingToDelete = reading; showDeleteConfirm = true }
    func confirmDeleteRR(_ reading: RRReading)         { rrReadingToDelete   = reading; showDeleteConfirm = true }
    func confirmDeletePain(_ reading: PainReading)     { painReadingToDelete   = reading; showDeleteConfirm = true }
    func confirmDeleteWeight(_ reading: WeightReading) { weightReadingToDelete = reading; showDeleteConfirm = true }
    func confirmDeleteHeight(_ reading: HeightReading) { heightReadingToDelete = reading; showDeleteConfirm = true }

    func deleteConfirmed() {
        if let r = recordingToDelete {
            recordingStore.delete(id: r.id)
            recordings.removeAll { $0.id == r.id }
            recordingToDelete = nil
        } else if let r = bpReadingToDelete {
            diContainer.bpStore.delete(id: r.id)
            bpReadings.removeAll { $0.id == r.id }
            bpReadingToDelete = nil
        } else if let r = spo2ReadingToDelete {
            diContainer.spo2Store.delete(id: r.id)
            spo2Readings.removeAll { $0.id == r.id }
            spo2ReadingToDelete = nil
        } else if let r = tempReadingToDelete {
            diContainer.tempStore.delete(id: r.id)
            tempReadings.removeAll { $0.id == r.id }
            tempReadingToDelete = nil
        } else if let r = rrReadingToDelete {
            diContainer.rrStore.delete(id: r.id)
            rrReadings.removeAll { $0.id == r.id }
            rrReadingToDelete = nil
        } else if let r = painReadingToDelete {
            diContainer.painStore.delete(id: r.id)
            painReadings.removeAll { $0.id == r.id }
            painReadingToDelete = nil
        } else if let r = weightReadingToDelete {
            diContainer.weightStore.delete(id: r.id)
            weightReadings.removeAll { $0.id == r.id }
            weightReadingToDelete = nil
        } else if let r = heightReadingToDelete {
            diContainer.heightStore.delete(id: r.id)
            heightReadings.removeAll { $0.id == r.id }
            heightReadingToDelete = nil
        }
        showDeleteConfirm = false
    }

    func cancelDelete() {
        recordingToDelete    = nil
        bpReadingToDelete    = nil
        spo2ReadingToDelete  = nil
        tempReadingToDelete  = nil
        rrReadingToDelete    = nil
        painReadingToDelete  = nil
        weightReadingToDelete = nil
        heightReadingToDelete = nil
        showDeleteConfirm    = false
    }

    // MARK: - Navigation

    func navigateBack() {
        let destination = router.patientExamsReturnRoute
        router.patientExamsReturnRoute = .vitals
        router.navigate(to: destination)
    }
}
