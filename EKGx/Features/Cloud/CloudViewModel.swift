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

    // MARK: - Upload state (per recording)

    var uploadingIds: Set<String> = []
    var uploadResultId: String? = nil
    var uploadResultSuccess: Bool = false
    var uploadResultMessage: String? = nil

    // MARK: - Dependencies

    private let router: AppRouter
    private let recordingStore: LocalRecordingStore
    private let diContainer: AppDIContainer

    init(router: AppRouter, recordingStore: LocalRecordingStore, diContainer: AppDIContainer) {
        self.router = router
        self.recordingStore = recordingStore
        self.diContainer = diContainer
    }

    // MARK: - Computed

    var isLocalMode: Bool { diContainer.isLocalMode }

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
        let allRecordings = recordingStore.allRecordings()

        // In offline mode show only recordings that belong to locally created patients.
        // In online mode show all recordings.
        let relevantRecordings: [ECGRecording]
        if isLocalMode {
            let localIds = Set(diContainer.localPatientStore.patients.map { $0.id })
            relevantRecordings = allRecordings.filter { localIds.contains($0.patientId) }
        } else {
            relevantRecordings = allRecordings
        }

        if !relevantRecordings.isEmpty {
            var seen = Set<String>()
            patients = relevantRecordings.compactMap { rec -> Patient? in
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
        } else {
            patients = []
        }

        // Re-fetch recordings so status changes (e.g. pending → synced) are reflected.
        if let patient = selectedPatient {
            loadRecordings(for: patient)
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

    // MARK: - Open recording in Analysis view

    func openRecording(_ recording: ECGRecording) {
        let rawData = recordingStore.ecgFileData(for: recording.id)
        let leads: ECGLeads
        if let raw = rawData, !raw.isEmpty {
            leads = EKGUploadService.deserialise(data: raw, leadCount: recording.leadCount)
        } else {
            leads = []
        }
        diContainer.lastRecordingPatient = Patient(
            id: nil,
            patientId: recording.patientId,
            uniqueId: recording.patientId,
            firstName: recording.patientName.components(separatedBy: " ").first ?? recording.patientName,
            lastName: recording.patientName.components(separatedBy: " ").dropFirst().joined(separator: " "),
            birthDate: recording.patientDob,
            gender: recording.patientGender,
            medicalRecordNumber: recording.patientMrn,
            hasPhoto: nil
        )
        diContainer.lastRecordingData = leads
        diContainer.lastRecordingSampleRate = recording.sampleRate
        diContainer.lastRecordingTotalDuration = nil
        diContainer.lastRecordingExistingId = recording.id
        router.analysisReturnRoute = .cloudReports
        router.navigate(to: .ecgAnalysis(recordingId: recording.id))
    }

    // MARK: - Upload pending / failed recording

    func uploadRecording(_ recording: ECGRecording) {
        guard recording.status != .synced,
              !uploadingIds.contains(recording.id) else { return }

        uploadingIds.insert(recording.id)
        uploadResultId = nil

        Task {
            do {
                let rawData  = recordingStore.ecgFileData(for: recording.id)
                let pdfData  = recordingStore.pdfData(for: recording.id)
                let appUuid  = diContainer.checkinService.appUuid

                var payload  = EKGUploadPayload(
                    patientUuid: recording.patientId,
                    appUuid: appUuid
                )
                payload.heartRate    = recording.heartRate
                payload.prInterval   = recording.prInterval
                payload.qrsDuration  = recording.qrsDuration
                payload.qtInterval   = recording.qtInterval
                payload.qtCorrected  = recording.qtCorrected
                payload.diagnosis    = recording.diagnosis
                payload.duration     = String(recording.durationSeconds)
                payload.appVersion   = recording.appVersion
                payload.recordedAt   = recording.recordedAt
                payload.fileData     = rawData
                payload.pdfData      = pdfData

                try await diContainer.ekgUploadService.upload(payload: payload)

                recordingStore.updateStatus(id: recording.id, status: .synced)
                // refresh list
                if let patient = selectedPatient {
                    recordings = recordingStore.recordings(for: patient.patientId ?? patient.uniqueId ?? "")
                }
                uploadResultId = recording.id
                uploadResultSuccess = true
                uploadResultMessage = nil
            } catch {
                recordingStore.updateStatus(id: recording.id, status: .failed)
                if let patient = selectedPatient {
                    recordings = recordingStore.recordings(for: patient.patientId ?? patient.uniqueId ?? "")
                }
                uploadResultId = recording.id
                uploadResultSuccess = false
                uploadResultMessage = (error as? LocalizedError)?.errorDescription
            }
            uploadingIds.remove(recording.id)
        }
    }

    // MARK: - Delete recording

    func deleteRecording(_ recording: ECGRecording) {
        recordingStore.delete(id: recording.id)
        recordings.removeAll { $0.id == recording.id }
        // Remove patient from list if they have no more recordings
        let pid = recording.patientId
        if recordingStore.recordings(for: pid).isEmpty {
            patients.removeAll { ($0.patientId ?? $0.uniqueId) == pid }
            if selectedPatient?.patientId == pid {
                selectedPatient = nil
            }
        }
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
