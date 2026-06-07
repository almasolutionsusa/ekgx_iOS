//
//  LocalPatient.swift
//  EKGx
//
//  Device-local patient record backed by Core Data (PatientEntity).
//  All patient management is local — no API required.
//

import Foundation

struct LocalPatient: Identifiable, Codable, Hashable {

    let id: String          // UUID generated on creation
    var firstName: String
    var lastName: String
    var birthDate: String   // "yyyy-MM-dd"
    var gender: String
    var mrn: String
    var createdAt: Date
    var createdBy: String   // logged-in username; empty when no login context

    init(id: String = UUID().uuidString,
         firstName: String,
         lastName: String,
         birthDate: String,
         gender: String,
         mrn: String,
         createdAt: Date = Date(),
         createdBy: String = "") {
        self.id        = id
        self.firstName = firstName
        self.lastName  = lastName
        self.birthDate = birthDate
        self.gender    = gender
        self.mrn       = mrn
        self.createdAt = createdAt
        self.createdBy = createdBy
    }

    var fullName: String { "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    var age: String {
        guard let date = Self.dateFormatter.date(from: birthDate) else { return "—" }
        let years = Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
        return "\(years) yrs"
    }

    var genderDisplay: String {
        switch gender.lowercased() {
        case "m", "male":   return "Male"
        case "f", "female": return "Female"
        default:            return gender
        }
    }

    func toPatient() -> Patient {
        Patient(
            id: nil,
            patientId: id,
            uniqueId: id,
            firstName: firstName,
            lastName: lastName,
            birthDate: birthDate,
            gender: gender,
            medicalRecordNumber: mrn.isEmpty ? nil : mrn,
            hasPhoto: false
        )
    }

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
