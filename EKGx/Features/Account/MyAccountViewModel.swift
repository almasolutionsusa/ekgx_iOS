//
//  MyAccountViewModel.swift
//  EKGx
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

    var department: String          = "Cardiology"
    var role: String                = "Cardiologist"

    // MARK: - Security Flows

    var showSetPinSheet: Bool          = false
    var showChangePasswordSheet: Bool  = false
    var showDeactivateAlert: Bool      = false

    // MARK: - PIN state

    var pinOld: String          = ""
    var pinInput: String        = ""
    var pinConfirm: String      = ""
    var pinError: String?       = nil
    var isSubmittingPin: Bool   = false

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

    // MARK: - PIN Status (from GET /api/auth/pin/status)

    /// True when the user has a PIN configured at their facility.
    /// Nil while the status is still loading.
    var hasPin: Bool? = nil
    /// Days until the current PIN expires. Nil if no PIN or still loading.
    var pinDaysUntilExpiry: Int? = nil
    var isLoadingPinStatus: Bool = false

    // MARK: - Dependencies

    private let router: AppRouter
    private let authService: AuthServiceProtocol
    private let appInfoService: AppInfoService

    var facilityName: String {
        appInfoService.cached?.facilityName ?? authService.loginData?.facilityName ?? "—"
    }

    init(router: AppRouter, authService: AuthServiceProtocol, appInfoService: AppInfoService) {
        self.router = router
        self.authService = authService
        self.appInfoService = appInfoService
        savedState = currentSnapshot
    }

    // MARK: - Activation

    /// Call from MyAccountView.onAppear — refreshes PIN status from the server.
    func activate() {
        Task { await loadPinStatus() }
    }

    private func loadPinStatus() async {
        isLoadingPinStatus = true
        defer { isLoadingPinStatus = false }
        do {
            let data = try await authService.pinStatus()
            if let days = data?.daysUntilExpiry {
                hasPin = true
                pinDaysUntilExpiry = days
            } else {
                hasPin = false
                pinDaysUntilExpiry = nil
            }
        } catch {
            // 404 or auth error typically means "no pin"
            hasPin = false
            pinDaysUntilExpiry = nil
        }
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
        pinOld     = ""
        pinInput   = ""
        pinConfirm = ""
        pinError   = nil
        showSetPinSheet = true
    }

    func submitPin() {
        if hasPin == true {
            guard pinOld.count == 6, pinOld.allSatisfy(\.isNumber) else {
                pinError = L10n.Account.Pin.errorDigits
                return
            }
        }
        guard pinInput.count == 6, pinInput.allSatisfy(\.isNumber) else {
            pinError = L10n.Account.Pin.errorDigits
            return
        }
        guard pinInput == pinConfirm else {
            pinError = L10n.Account.Pin.errorMismatch
            return
        }
        Task { await performSubmitPin() }
    }

    private func performSubmitPin() async {
        isSubmittingPin = true
        pinError = nil
        defer { isSubmittingPin = false }

        do {
            if hasPin == true {
                let userId     = authService.loginData?.user.id ?? 0
                let facilityId = authService.loginData?.facilityId ?? 0
                try await authService.changePin(userId: userId, facilityId: facilityId, oldPin: pinOld, newPin: pinInput)
            } else {
                let appUuid = UserDefaults.standard.string(forKey: AppCheckinService.Keys.appUuid) ?? ""
                try await authService.setupPin(pin: pinInput, appUuid: appUuid)
            }
            showSetPinSheet = false
            pinOld     = ""
            pinInput   = ""
            pinConfirm = ""
            pinError   = nil
            await loadPinStatus()
        } catch let error as AuthError {
            pinError = error.errorDescription
        } catch {
            pinError = L10n.Auth.Login.errorGeneric
        }
    }

    func cancelPin() {
        showSetPinSheet = false
        pinOld     = ""
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
        firstNameError = firstName.trimmingCharacters(in: .whitespaces).isEmpty
            ? L10n.Account.Personal.errorFirstName : nil
        lastNameError = lastName.trimmingCharacters(in: .whitespaces).isEmpty
            ? L10n.Account.Personal.errorLastName : nil
        return firstNameError == nil && lastNameError == nil
    }

    private func clearErrors() {
        firstNameError = nil
        lastNameError  = nil
    }

    // MARK: - Snapshot helpers

    private var currentSnapshot: AccountSnapshot {
        AccountSnapshot(
            firstName:    firstName,
            lastName:     lastName,
            workEmail:    workEmail,
            phone:        phone,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            city:         city,
            state:        state,
            zipCode:      zipCode,
            country:      country,
            department:   department,
            role:         role
        )
    }

    private func apply(snapshot: AccountSnapshot) {
        firstName    = snapshot.firstName
        lastName     = snapshot.lastName
        workEmail    = snapshot.workEmail
        phone        = snapshot.phone
        addressLine1 = snapshot.addressLine1
        addressLine2 = snapshot.addressLine2
        city         = snapshot.city
        state        = snapshot.state
        zipCode      = snapshot.zipCode
        country      = snapshot.country
        department   = snapshot.department
        role         = snapshot.role
    }
}

// MARK: - Snapshot (Equatable for change detection)

private struct AccountSnapshot: Equatable {
    var firstName:    String = "Sarah"
    var lastName:     String = "Mitchell"
    var workEmail:    String = "s.mitchell@centralmed.org"
    var phone:        String = "+1 (312) 555-0198"
    var addressLine1: String = "420 N Michigan Ave"
    var addressLine2: String = ""
    var city:         String = "Chicago"
    var state:        String = "IL"
    var zipCode:      String = "60611"
    var country:      String = "United States"
    var department:   String = "Cardiology"
    var role:            String           = "Cardiologist"
}
