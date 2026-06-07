//
//  CoreDataPatientRepository.swift
//  EKGx
//
//  PatientRepositoryProtocol backed by Core Data (PatientEntity).
//  All reads/writes run on the view context's main queue via async.
//

import CoreData

final class CoreDataPatientRepository: PatientRepositoryProtocol {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Fetch All

    func fetchAll() async throws -> [LocalPatient] {
        try await context.perform {
            let request = NSFetchRequest<PatientEntity>(entityName: "PatientEntity")
            request.sortDescriptors = [
                NSSortDescriptor(key: "lastName",  ascending: true),
                NSSortDescriptor(key: "firstName", ascending: true)
            ]
            return try self.context.fetch(request).map(Self.map)
        }
    }

    // MARK: - Search

    func search(text: String, dob: String?) async throws -> [LocalPatient] {
        try await context.perform {
            let request = NSFetchRequest<PatientEntity>(entityName: "PatientEntity")
            var predicates: [NSPredicate] = []

            let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !q.isEmpty {
                predicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "firstName CONTAINS[cd] %@", q),
                    NSPredicate(format: "lastName  CONTAINS[cd] %@", q),
                    NSPredicate(format: "mrn       CONTAINS[cd] %@", q)
                ]))
            }

            if let dob, !dob.isEmpty {
                predicates.append(NSPredicate(format: "dob == %@", dob))
            }

            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }

            request.sortDescriptors = [
                NSSortDescriptor(key: "lastName",  ascending: true),
                NSSortDescriptor(key: "firstName", ascending: true)
            ]

            return try self.context.fetch(request).map(Self.map)
        }
    }

    // MARK: - Add

    func add(_ input: NewPatientInput) async throws -> LocalPatient {
        try await context.perform {
            let entity = PatientEntity(context: self.context)
            entity.id        = UUID().uuidString
            entity.firstName = input.firstName
            entity.lastName  = input.lastName
            entity.dob       = input.birthDate
            entity.gender    = input.gender
            entity.mrn       = input.mrn.isEmpty ? nil : input.mrn
            entity.createdAt = Date()
            entity.createdBy = input.createdBy.isEmpty ? nil : input.createdBy
            try self.context.save()
            return Self.map(entity)
        }
    }

    // MARK: - Update

    func update(_ patient: LocalPatient) async throws {
        try await context.perform {
            let request = NSFetchRequest<PatientEntity>(entityName: "PatientEntity")
            request.predicate = NSPredicate(format: "id == %@", patient.id)
            guard let entity = try self.context.fetch(request).first else { return }
            entity.firstName = patient.firstName
            entity.lastName  = patient.lastName
            entity.dob       = patient.birthDate
            entity.gender    = patient.gender
            entity.mrn       = patient.mrn.isEmpty ? nil : patient.mrn
            try self.context.save()
        }
    }

    // MARK: - Delete

    func delete(_ id: String) async throws {
        try await context.perform {
            let request = NSFetchRequest<PatientEntity>(entityName: "PatientEntity")
            request.predicate = NSPredicate(format: "id == %@", id)
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }

    // MARK: - Mapping

    private static func map(_ entity: PatientEntity) -> LocalPatient {
        LocalPatient(
            id:        entity.id ?? UUID().uuidString,
            firstName: entity.firstName ?? "",
            lastName:  entity.lastName  ?? "",
            birthDate: entity.dob       ?? "",
            gender:    entity.gender    ?? "",
            mrn:       entity.mrn       ?? "",
            createdAt: entity.createdAt ?? Date(),
            createdBy: entity.createdBy ?? ""
        )
    }
}
