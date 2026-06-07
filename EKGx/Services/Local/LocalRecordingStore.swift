//
//  LocalRecordingStore.swift
//  EKGx
//
//  Persists ECG recordings locally via CoreData.
//  Each recording stores patient info, measurements, status, and optionally
//  the raw ECG binary + rendered multi-page PDF.
//
//  Status lifecycle:
//    .pending  → saved immediately when user proceeds to analysis
//    .synced   → updated after a successful upload to the server
//    .failed   → updated after an upload error
//

import CoreData
import Foundation

@MainActor
final class LocalRecordingStore {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Save

    /// Inserts a new recording with `.pending` status.
    /// Call this when the user proceeds from recording → analysis.
    @discardableResult
    func save(recording: ECGRecording, ecgFileData: Data?, pdfData: Data?) -> ECGRecordingEntity? {
        let entity = ECGRecordingEntity(context: context)
        entity.id              = recording.id
        entity.patientId       = recording.patientId
        entity.patientName     = recording.patientName
        entity.patientDob      = recording.patientDob
        entity.patientGender   = recording.patientGender
        entity.patientMrn      = recording.patientMrn
        entity.recordedAt      = recording.recordedAt
        entity.durationSeconds = Int32(recording.durationSeconds)
        entity.sampleRate      = Int32(recording.sampleRate)
        entity.leadCount       = Int32(recording.leadCount)
        entity.fileSize        = Int64(ecgFileData?.count ?? 0)
        entity.status          = recording.status.rawValue
        entity.diagnosis       = recording.diagnosis
        entity.heartRate       = recording.heartRate
        entity.prInterval      = recording.prInterval
        entity.qrsDuration     = recording.qrsDuration
        entity.qtInterval      = recording.qtInterval
        entity.qtCorrected     = recording.qtCorrected
        entity.ecgFileData     = ecgFileData
        entity.imageData       = pdfData
        entity.appVersion      = recording.appVersion
        entity.username        = recording.username
        entity.isEmergency     = recording.isEmergency
        persist()
        return entity
    }

    // MARK: - Update Patient

    /// Reassigns a local recording to a different patient (used in the emergency assign flow).
    func updatePatient(id: String, patient: Patient) {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        guard let entity = try? context.fetch(request).first else { return }
        entity.patientId     = patient.patientId ?? patient.uniqueId
        entity.patientName   = patient.fullName
        entity.patientDob    = patient.birthDate.isEmpty ? nil : patient.birthDate
        entity.patientGender = patient.gender.isEmpty ? nil : patient.gender
        entity.patientMrn    = patient.medicalRecordNumber
        persist()
    }

    // MARK: - Update Status

    func updateStatus(id: String, status: ECGRecording.RecordingStatus) {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        guard let entity = try? context.fetch(request).first else { return }
        entity.status = status.rawValue
        persist()
    }

    // MARK: - Fetch

    /// All recordings for a given patient, newest first.
    func recordings(for patientId: String) -> [ECGRecording] {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "patientId == %@", patientId)
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        let entities = (try? context.fetch(request)) ?? []
        return entities.compactMap { ECGRecording(entity: $0) }
    }

    /// All patients that have at least one local recording, newest-first.
    func allPatientIds() -> [String] {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        request.propertiesToFetch = ["patientId"]
        request.returnsDistinctResults = true
        request.resultType = .dictionaryResultType
        let results = (try? context.fetch(request)) ?? []
        var seen = Set<String>()
        return results.compactMap { ($0 as? [String: Any])?["patientId"] as? String }
            .filter { seen.insert($0).inserted }
    }

    /// All recordings across all patients, newest first.
    func allRecordings() -> [ECGRecording] {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "recordedAt", ascending: false)]
        let entities = (try? context.fetch(request)) ?? []
        return entities.compactMap { ECGRecording(entity: $0) }
    }

    // MARK: - Delete

    func delete(id: String) {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        guard let entity = try? context.fetch(request).first else { return }
        context.delete(entity)
        persist()
    }

    /// Returns true if the stored recording was flagged as an emergency exam.
    func isEmergency(for id: String) -> Bool {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return (try? context.fetch(request).first)?.isEmergency ?? false
    }

    /// Status of a recording by ID, or nil if not found.
    func status(for id: String) -> ECGRecording.RecordingStatus? {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        guard let entity = try? context.fetch(request).first,
              let raw = entity.status else { return nil }
        return ECGRecording.RecordingStatus(rawValue: raw)
    }

    /// Raw ECG binary for a given recording ID (may be nil if not stored).
    func ecgFileData(for id: String) -> Data? {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return (try? context.fetch(request).first)?.ecgFileData
    }

    /// Stored PDF for a given recording ID (may be nil if not stored).
    func pdfData(for id: String) -> Data? {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return (try? context.fetch(request).first)?.imageData
    }

    // MARK: - Private

    private func persist() {
        guard context.hasChanges else { return }
        try? context.save()
    }

}
