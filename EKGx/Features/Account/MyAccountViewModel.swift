//
//  MyAccountViewModel.swift
//  EKGx
//
//  Manages all state for the My Account screen.
//  Tracks unsaved changes via snapshot comparison.
//  PIN and password change are gated behind confirmation flows.
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

    var firstName: String = ""
    var lastName: String  = ""
    var email: String     = ""

    // MARK: - Security Flows

    var showSetPinSheet: Bool          = false
    var showChangePasswordSheet: Bool  = false
    var showDeactivateAlert: Bool      = false

    // MARK: - PIN state

    var pinInput: String        = ""
    var pinConfirm: String      = ""
    var pinError: String?       = nil


    // MARK: - Change Password state

    enum PasswordStep { case verify, setNew }
    var passwordStep: PasswordStep  = .verify
    var verifyPasswordInput: String = ""
    var verifyError: String?        = nil
    var currentPassword: String     = ""
    var newPassword: String         = ""
    var confirmPassword: String     = ""
    var passwordError: String?      = nil
    var isChangingPassword: Bool    = false
    var passwordSuccess: Bool       = false

    // MARK: - Unsaved changes

    private var savedState: AccountSnapshot = .init()
    var hasUnsavedChanges: Bool { currentSnapshot != savedState }

    // MARK: - Field validation

    var firstNameError: String? = nil
    var lastNameError: String?  = nil

    // MARK: - PIN Status (local)

    var hasPin: Bool { LocalUserStore.shared.hasPin(forUser: authService.currentUser?.username) }
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

        // Pre-fill from session data, falling back to locally stored values
        let store = LocalUserStore.shared
        firstName = authService.loginData?.user.firstName ?? store.firstName ?? ""
        lastName  = authService.loginData?.user.lastName  ?? store.lastName  ?? ""
        email     = authService.loginData?.user.email     ?? store.email     ?? ""

        savedState = currentSnapshot
    }

    // MARK: - Activation

    func activate() {
        // PIN status is read directly from LocalUserStore — no network call needed.
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
        router.navigate(to: .patientSelection)
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
        guard pinInput.count == 6, pinInput.allSatisfy(\.isNumber) else {
            pinError = L10n.Account.Pin.errorDigits
            return
        }
        guard pinInput == pinConfirm else {
            pinError = L10n.Account.Pin.errorMismatch
            return
        }
        let sessionUsername = authService.currentUser?.username
        if hasPin && LocalUserStore.shared.validatePin(pinInput, forUser: sessionUsername) {
            pinError = L10n.Account.Pin.errorSamePin
            return
        }
        LocalUserStore.shared.savePin(pinInput, forUser: sessionUsername)
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
        passwordStep        = .verify
        verifyPasswordInput = ""
        verifyError         = nil
        currentPassword     = ""
        newPassword         = ""
        confirmPassword     = ""
        passwordError       = nil
        showChangePasswordSheet = true
    }

    func verifyCurrentPassword() {
        let store       = LocalUserStore.shared
        let storedEmail = authService.loginData?.user.email ?? store.email ?? ""
        print("┌─── verifyCurrentPassword ──────────────────")
        print("│ storedEmail   : \(storedEmail)")
        print("│ isVerified    : \(store.isVerified(email: storedEmail))")
        print("│ inputEmpty    : \(verifyPasswordInput.isEmpty)")

        guard !verifyPasswordInput.isEmpty else {
            print("│ ❌ Empty input")
            print("└────────────────────────────────────────────")
            verifyError = L10n.Account.Password.errorCurrent
            return
        }
        let matched = store.canLoginLocally(email: storedEmail, password: verifyPasswordInput)
        print("│ passwordMatch : \(matched ? "✅" : "❌")")
        print("└────────────────────────────────────────────")

        guard matched else {
            verifyError = L10n.Account.Password.errorWrongCurrent
            return
        }
        currentPassword = verifyPasswordInput
        verifyError     = nil
        passwordStep    = .setNew
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
        Task {
            isChangingPassword = true
            passwordError      = nil
            defer { isChangingPassword = false }
            do {
                try await authService.changePassword(oldPassword: currentPassword, newPassword: newPassword)
                let store = LocalUserStore.shared
                let storedEmail = authService.loginData?.user.email ?? store.email ?? ""
                store.savePasswordHash(newPassword, for: storedEmail)
                store.savePasswordUnderAllKeys(newPassword, typedInput: storedEmail)
                showChangePasswordSheet = false
                currentPassword = ""
                newPassword     = ""
                confirmPassword = ""
            } catch {
                passwordError = error.localizedDescription
            }
        }
    }

    func cancelPasswordChange() {
        showChangePasswordSheet = false
        passwordStep        = .verify
        verifyPasswordInput = ""
        verifyError         = nil
        currentPassword     = ""
        newPassword         = ""
        confirmPassword     = ""
        passwordError       = nil
        isChangingPassword  = false
    }

    // MARK: - Deactivate

    func confirmDeactivate() {
        showDeactivateAlert = true
    }

    func executeDeactivate() {
        router.navigate(to: .login)
    }

    // MARK: - Private

    private func validate() -> Bool {
        let trimFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimLast  = lastName.trimmingCharacters(in: .whitespaces)
        firstNameError = trimFirst.isEmpty ? L10n.Account.Personal.errorFirstName : nil
        lastNameError  = trimLast.isEmpty  ? L10n.Account.Personal.errorLastName  : nil
        return firstNameError == nil && lastNameError == nil
    }

    private func clearErrors() {
        firstNameError = nil
        lastNameError  = nil
    }

    // MARK: - Snapshot helpers

    private var currentSnapshot: AccountSnapshot {
        AccountSnapshot(firstName: firstName, lastName: lastName)
    }

    private func apply(snapshot: AccountSnapshot) {
        firstName = snapshot.firstName
        lastName  = snapshot.lastName
    }
}

// MARK: - Snapshot (Equatable for change detection)

private struct AccountSnapshot: Equatable {
    var firstName: String = ""
    var lastName:  String = ""
}
