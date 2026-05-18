//
//  LocalPatient.swift
//  EKGx
//
//  Lightweight patient record stored locally on-device (UserDefaults).
//  Used in offline mode — no API interaction needed.
//

import Foundation

struct LocalPatient: Identifiable, Codable, Hashable {

    let id: String          // UUID generated on creation
    var firstName: String
    var lastName: String
    var birthDate: String   // "yyyy-MM-dd"
    var gender: String
    var mrn: String

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

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
