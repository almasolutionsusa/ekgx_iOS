//
//  PatientRepositoryProtocol.swift
//  EKGx
//
//  Abstracts patient data source so the VM stays the same whether
//  patients come from Core Data (current) or a hospital API (future).
//

import Foundation

struct NewPatientInput {
    let firstName: String
    let lastName: String
    let birthDate: String   // "yyyy-MM-dd"
    let gender: String
    let mrn: String
    let createdBy: String   // logged-in username
}

protocol PatientRepositoryProtocol: AnyObject {
    /// Returns all patients sorted by lastName then firstName.
    func fetchAll() async throws -> [LocalPatient]
    /// Live filter — returns patients matching any of the non-empty fields.
    func search(text: String, dob: String?) async throws -> [LocalPatient]
    func add(_ input: NewPatientInput) async throws -> LocalPatient
    func update(_ patient: LocalPatient) async throws
    func delete(_ id: String) async throws
}
