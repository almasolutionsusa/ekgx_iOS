//
//  Patient.swift
//  EKGx
//

import Foundation

// MARK: - Patient

struct Patient: Identifiable, Codable, Hashable {

    let id: Int?
    let patientId: String?
    let uniqueId: String?
    let firstName: String
    let lastName: String
    let birthDate: String
    let gender: String
    let medicalRecordNumber: String?
    let hasPhoto: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId              = "emrPatientId"
        case uniqueId               = "uniqueId"
        case firstName              = "firstName"
        case lastName               = "lastName"
        case birthDate              = "birthDate"
        case gender                 = "gender"
        case medicalRecordNumber    = "medicalRecordNumber"
        case hasPhoto               = "hasPhoto"
    }

    // MARK: - Computed

    var fullName: String { "\(firstName) \(lastName)" }

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

    var ageYears: Int {
        guard let date = Self.dateFormatter.date(from: birthDate) else { return 0 }
        return Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
    }

    var genderDisplay: String {
        switch gender.lowercased() {
        case "m", "male":   return "Male"
        case "f", "female": return "Female"
        default:            return gender
        }
    }

    var genderIcon: String {
        switch gender.lowercased() {
        case "m", "male":   return "person.fill"
        case "f", "female": return "person.fill"
        default:            return "person.fill"
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

// MARK: - Mock Data

extension Patient {

    static let mockPatients: [Patient] = [
        Patient(id: 1,  patientId: "EMR-10041", uniqueId: "UID-A001", firstName: "James",    lastName: "Hartwell",   birthDate: "1965-03-14", gender: "Male",   medicalRecordNumber: "MRN-88210", hasPhoto: false),
        Patient(id: 2,  patientId: "EMR-10042", uniqueId: "UID-A002", firstName: "Margaret",  lastName: "Schultz",    birthDate: "1978-07-22", gender: "Female", medicalRecordNumber: "MRN-88211", hasPhoto: false),
        Patient(id: 3,  patientId: "EMR-10043", uniqueId: "UID-A003", firstName: "Robert",    lastName: "Nguyen",     birthDate: "1952-11-05", gender: "Male",   medicalRecordNumber: "MRN-88212", hasPhoto: false),
        Patient(id: 4,  patientId: "EMR-10044", uniqueId: "UID-A004", firstName: "Linda",     lastName: "Okafor",     birthDate: "1983-01-30", gender: "Female", medicalRecordNumber: "MRN-88213", hasPhoto: false),
        Patient(id: 5,  patientId: "EMR-10045", uniqueId: "UID-A005", firstName: "Thomas",    lastName: "Brennan",    birthDate: "1970-09-17", gender: "Male",   medicalRecordNumber: "MRN-88214", hasPhoto: false),
        Patient(id: 6,  patientId: "EMR-10046", uniqueId: "UID-A006", firstName: "Patricia",  lastName: "Morales",    birthDate: "1961-04-08", gender: "Female", medicalRecordNumber: "MRN-88215", hasPhoto: false),
        Patient(id: 7,  patientId: "EMR-10047", uniqueId: "UID-A007", firstName: "Kevin",     lastName: "Fitzgerald", birthDate: "1989-12-03", gender: "Male",   medicalRecordNumber: "MRN-88216", hasPhoto: false),
        Patient(id: 8,  patientId: "EMR-10048", uniqueId: "UID-A008", firstName: "Barbara",   lastName: "Chen",       birthDate: "1947-06-25", gender: "Female", medicalRecordNumber: "MRN-88217", hasPhoto: false),
        Patient(id: 9,  patientId: "EMR-10049", uniqueId: "UID-A009", firstName: "Michael",   lastName: "Stein",      birthDate: "1975-08-11", gender: "Male",   medicalRecordNumber: "MRN-88218", hasPhoto: false),
        Patient(id: 10, patientId: "EMR-10050", uniqueId: "UID-A010", firstName: "Dorothy",   lastName: "Vasquez",    birthDate: "1958-02-19", gender: "Female", medicalRecordNumber: "MRN-88219", hasPhoto: false),
        Patient(id: 11, patientId: "EMR-10051", uniqueId: "UID-A011", firstName: "Charles",   lastName: "Patel",      birthDate: "1991-05-07", gender: "Male",   medicalRecordNumber: "MRN-88220", hasPhoto: false),
        Patient(id: 12, patientId: "EMR-10052", uniqueId: "UID-A012", firstName: "Susan",     lastName: "Kovacs",     birthDate: "1964-10-14", gender: "Female", medicalRecordNumber: "MRN-88221", hasPhoto: false),
    ]
}
