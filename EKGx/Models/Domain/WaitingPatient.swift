//
//  WaitingPatient.swift
//  EKGx
//

import Foundation

struct WaitingPatient: Codable, Identifiable, Equatable {

    let id:        UUID
    let patientId: String
    let firstName: String
    let lastName:  String
    let mrn:       String
    let gender:    String
    let birthDate: String
    let arrivedAt: Date
    var status:    WaitingStatus
    var note:      String

    enum WaitingStatus: String, Codable {
        case waiting
        case inProgress
        case done
    }

    init(from patient: LocalPatient) {
        self.id        = UUID()
        self.patientId = patient.id
        self.firstName = patient.firstName
        self.lastName  = patient.lastName
        self.mrn       = patient.mrn
        self.gender    = patient.gender
        self.birthDate = patient.birthDate
        self.arrivedAt = Date()
        self.status    = .waiting
        self.note      = ""
    }

    var fullName: String { "\(firstName) \(lastName)" }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    var age: String {
        guard let dob = LocalPatient.dateFormatter.date(from: birthDate) else { return "—" }
        let comps = Calendar.current.dateComponents([.year], from: dob, to: Date())
        return "\(comps.year ?? 0) y"
    }

    var genderInitial: String {
        switch gender.lowercased() {
        case "male":   return "M"
        case "female": return "F"
        default:       return "—"
        }
    }

    func elapsedText(relativeTo now: Date) -> String {
        let elapsed = Int(now.timeIntervalSince(arrivedAt))
        if elapsed < 60 { return "just now" }
        let minutes = elapsed / 60
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let mins  = minutes % 60
        return mins == 0 ? "\(hours)h" : "\(hours)h \(mins)m"
    }
}

extension WaitingPatient.WaitingStatus {
    var displayTitle: String {
        switch self {
        case .waiting:    return L10n.WaitingList.Status.waiting
        case .inProgress: return L10n.WaitingList.Status.inProgress
        case .done:       return L10n.WaitingList.Status.done
        }
    }
}
