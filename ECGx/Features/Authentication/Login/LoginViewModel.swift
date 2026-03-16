//
//  LoginViewModel.swift
//  ECGx
//
//  Drives all state for LoginView. Contains zero UI code.
//

import Foundation

@Observable
@MainActor
final class LoginViewModel {

    // MARK: - Input State

    var email: String = ""
    var password: String = ""

    // MARK: - PIN Login State

    var showPinLogin: Bool = false
    var pinInput: String = ""
    var pinError: String? = nil

    // MARK: - UI State

    var isLoading: Bool = false
    var errorMessage: String? = nil
    var emailError: String? = nil
    var passwordError: String? = nil

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let router: AppRouter

    // MARK: - Init

    init(authService: AuthServiceProtocol, router: AppRouter) {
        self.authService = authService
        self.router = router
    }

    // MARK: - Actions

    func login() {
        guard validateInputs() else { return }
        Task { await performLogin() }
    }

    func navigateToRegister() {
        router.navigate(to: .register)
    }

    func enterWithPin() {
        pinInput = ""
        pinError = nil
        showPinLogin = true
    }

    func cancelPinLogin() {
        showPinLogin = false
        pinInput = ""
        pinError = nil
    }

    func submitPinLogin() {
        guard !pinInput.isEmpty else {
            pinError = L10n.Auth.Login.pinErrorEmpty
            return
        }
        guard pinInput.count == 4, pinInput.allSatisfy(\.isNumber) else {
            pinError = L10n.Auth.Login.pinErrorInvalid
            return
        }
        // TODO: validate PIN against stored/server PIN
        // For now, navigate to dashboard on any 4-digit PIN
        router.navigate(to: .dashboard)
    }

    func clearFieldError(for field: Field) {
        switch field {
        case .email:    emailError = nil
        case .password: passwordError = nil
        case .pin:      pinError = nil
        }
        errorMessage = nil
    }

    // MARK: - Private

    private func performLogin() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            router.navigate(to: .dashboard)
        } catch let authError as AuthError {
            errorMessage = authError.errorDescription
        } catch {
            errorMessage = L10n.Auth.Login.errorGeneric
        }
    }

    private func validateInputs() -> Bool {
        emailError    = Validators.validateEmail(email)
        passwordError = Validators.validatePassword(password)
        return emailError == nil && passwordError == nil
    }

    // MARK: - Field Enum

    enum Field {
        case email, password, pin
    }
}
