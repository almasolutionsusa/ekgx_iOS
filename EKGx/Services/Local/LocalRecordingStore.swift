//
//  LocalRecordingStore.swift
//  EKGx
//
//  Persists ECG recordings locally via CoreData.
//  Each recording stores patient info, measurements, status, and optionally
//  the raw ECG binary + rendered JPEG image.
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
    func save(recording: ECGRecording, ecgFileData: Data?, imageData: Data?) -> ECGRecordingEntity? {
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
        entity.imageData       = imageData
        entity.appVersion      = recording.appVersion
        entity.username        = recording.username
        persist()
        return entity
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

    /// Raw ECG binary for a given recording ID (may be nil if not stored).
    func ecgFileData(for id: String) -> Data? {
        let request: NSFetchRequest<ECGRecordingEntity> = ECGRecordingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return (try? context.fetch(request).first)?.ecgFileData
    }

    // MARK: - Private

    private func persist() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}
