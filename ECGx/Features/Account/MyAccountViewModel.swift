//
//  MyAccountViewModel.swift
//  ECGx
//
//  Manages all state for the My Account screen.
//  Tracks unsaved changes via snapshot comparison.
//  PIN, password change, and deactivation are gated behind confirmation flows.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class MyAccountViewModel {

    // MARK: - Profile Picture

    var profileImageData: Data?          = nil
    var showImagePicker: Bool            = false

    // MARK: - Personal Info

    var firstName: String  = "Sarah"
    var lastName: String   = "Mitchell"
    var workEmail: String  = "s.mitchell@centralmed.org"
    var phone: String      = "+1 (312) 555-0198"

    // MARK: - Address

    var addressLine1: String = "420 N Michigan Ave"
    var addressLine2: String = ""
    var city: String         = "Chicago"
    var state: String        = "IL"
    var zipCode: String      = "60611"
    var country: String      = "United States"

    // MARK: - Facility / Role

    var currentFacility: Facility   = .centralMedicalCenter
    var department: String          = "Cardiology"
    var role: String                = "Cardiologist"

    // MARK: - Security Flows

    var showSetPinSheet: Bool          = false
    var showChangePasswordSheet: Bool  = false
    var showDeactivateAlert: Bool      = false

    // MARK: - PIN state

    var pinInput: String        = ""
    var pinConfirm: String      = ""
    var pinError: String?       = nil

    // MARK: - Change Password state

    var currentPassword: String  = ""
    var newPassword: String      = ""
    var confirmPassword: String  = ""
    var passwordError: String?   = nil

    // MARK: - Unsaved changes

    private var savedState: AccountSnapshot = .init()
    var hasUnsavedChanges: Bool { currentSnapshot != savedState }

    // MARK: - Field validation

    var firstNameError: String?  = nil
    var lastNameError: String?   = nil
    var emailError: String?      = nil
    var phoneError: String?      = nil

    // MARK: - Dependencies

    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
        savedState = currentSnapshot
    }

    // MARK: - Facility Enum

    enum Facility: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case centralMedicalCenter = "Central Medical Center"
        case northShoreHospital   = "North Shore Hospital"
        case universityMedical    = "University Medical Center"
        case stJamesClinic        = "St. James Clinic"
        case lakeviewCardiology   = "Lakeview Cardiology Group"
    }

    // MARK: - Actions

    func saveChanges() {
        guard validate() else { return }
        savedState = currentSnapshot
        // Persist via API call here
    }

    func discardChanges() {
        apply(snapshot: savedState)
        clearErrors()
    }

    func navigateBack() {
        router.navigate(to: .dashboard)
    }

    // MARK: - Image Picker

    func requestProfileImageChange() {
        showImagePicker = true
    }

    func setProfileImage(_ data: Data?) {
        profileImageData = data
    }

    // MARK: - PIN

    func openSetPin() {
        pinInput   = ""
        pinConfirm = ""
        pinError   = nil
        showSetPinSheet = true
    }

    func submitPin() {
        guard pinInput.count == 4, pinInput.allSatisfy(\.isNumber) else {
            pinError = L10n.Account.Pin.errorDigits
            return
        }
        guard pinInput == pinConfirm else {
            pinError = L10n.Account.Pin.errorMismatch
            return
        }
        // Save PIN via Keychain here
        showSetPinSheet = false
        pinInput   = ""
        pinConfirm = ""
        pinError   = nil
    }

    func cancelPin() {
        showSetPinSheet = false
        pinInput   = ""
        pinConfirm = ""
        pinError   = nil
    }

    // MARK: - Change Password

    func openChangePassword() {
        currentPassword = ""
        newPassword     = ""
        confirmPassword = ""
        passwordError   = nil
        showChangePasswordSheet = true
    }

    func submitPasswordChange() {
        guard !currentPassword.isEmpty else {
            passwordError = L10n.Account.Password.errorCurrent
            return
        }
        guard newPassword.count >= 8 else {
            passwordError = L10n.Account.Password.errorTooShort
            return
        }
        guard newPassword == confirmPassword else {
            passwordError = L10n.Account.Password.errorMismatch
            return
        }
        // Submit via API here
        showChangePasswordSheet = false
        currentPassword = ""
        newPassword     = ""
        confirmPassword = ""
        passwordError   = nil
    }

    func cancelPasswordChange() {
        showChangePasswordSheet = false
        currentPassword = ""
        newPassword     = ""
        confirmPassword = ""
        passwordError   = nil
    }

    // MARK: - Deactivate

    func confirmDeactivate() {
        showDeactivateAlert = true
    }

    func executeDeactivate() {
        // Call deactivation API, then log out
        router.navigate(to: .login)
    }

    // MARK: - Private

    private func validate() -> Bool {
        var valid = true

        firstNameError = firstName.trimmingCharacters(in: .whitespaces).isEmpty
            ? L10n.Account.Personal.errorFirstName : nil
        lastNameError = lastName.trimmingCharacters(in: .whitespaces).isEmpty
            ? L10n.Account.Personal.errorLastName : nil
        emailError = workEmail.trimmingCharacters(in: .whitespaces).isEmpty
            ? L10n.Account.Personal.errorEmail : nil
        phoneError = nil

        if firstNameError != nil || lastNameError != nil || emailError != nil { valid = false }
        return valid
    }

    private func clearErrors() {
        firstNameError = nil
        lastNameError  = nil
        emailError     = nil
        phoneError     = nil
    }

    // MARK: - Snapshot helpers

    private var currentSnapshot: AccountSnapshot {
        AccountSnapshot(
            firstName:       firstName,
            lastName:        lastName,
            workEmail:       workEmail,
            phone:           phone,
            addressLine1:    addressLine1,
            addressLine2:    addressLine2,
            city:            city,
            state:           state,
            zipCode:         zipCode,
            country:         country,
            currentFacility: currentFacility,
            department:      department,
            role:            role
        )
    }

    private func apply(snapshot: AccountSnapshot) {
        firstName       = snapshot.firstName
        lastName        = snapshot.lastName
        workEmail       = snapshot.workEmail
        phone           = snapshot.phone
        addressLine1    = snapshot.addressLine1
        addressLine2    = snapshot.addressLine2
        city            = snapshot.city
        state           = snapshot.state
        zipCode         = snapshot.zipCode
        country         = snapshot.country
        currentFacility = snapshot.currentFacility
        department      = snapshot.department
        role            = snapshot.role
    }
}

// MARK: - Snapshot (Equatable for change detection)

private struct AccountSnapshot: Equatable {
    var firstName:       String           = "Sarah"
    var lastName:        String           = "Mitchell"
    var workEmail:       String           = "s.mitchell@centralmed.org"
    var phone:           String           = "+1 (312) 555-0198"
    var addressLine1:    String           = "420 N Michigan Ave"
    var addressLine2:    String           = ""
    var city:            String           = "Chicago"
    var state:           String           = "IL"
    var zipCode:         String           = "60611"
    var country:         String           = "United States"
    var currentFacility: MyAccountViewModel.Facility = .centralMedicalCenter
    var department:      String           = "Cardiology"
    var role:            String           = "Cardiologist"
}
