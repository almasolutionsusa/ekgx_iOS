//
//  RegisterViewModel.swift
//  EKGx
//

import Foundation

@Observable
@MainActor
final class RegisterViewModel {

    // MARK: - Input

    var firstName: String       = ""
    var lastName: String        = ""
    var email: String           = ""
    var confirmEmail: String    = ""
    var password: String        = ""
    var confirmPassword: String = ""

    // MARK: - UI State

    var isLoading: Bool           = false
    var errorMessage: String?     = nil
    var registrationSucceeded: Bool = false

    // Per-field errors
    var firstNameError: String?       = nil
    var lastNameError: String?        = nil
    var emailError: String?           = nil
    var confirmEmailError: String?    = nil
    var passwordError: String?        = nil
    var confirmPasswordError: String? = nil

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let router: AppRouter

    init(authService: AuthServiceProtocol, router: AppRouter) {
        self.authService = authService
        self.router      = router
    }

    // MARK: - Actions

    func register() {
        guard validateInputs() else { return }
        Task { await performRegister() }
    }

    func navigateToLogin() {
        router.navigate(to: .login)
    }

    func clearFieldError(for field: Field) {
        switch field {
        case .firstName:       firstNameError = nil
        case .lastName:        lastNameError = nil
        case .email:           emailError = nil
        case .confirmEmail:    confirmEmailError = nil
        case .password:        passwordError = nil
        case .confirmPassword: confirmPasswordError = nil
        }
        errorMessage = nil
    }

    // MARK: - Private

    private func performRegister() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let details = SignupDetails(
            firstName: firstName.trimmed,
            lastName:  lastName.trimmed,
            email:     email.trimmed,
            password:  password
        )

        do {
            try await authService.register(details: details)
            LocalUserStore.shared.saveRegisteredUser(email: details.email, password: details.password)
            registrationSucceeded = true
        } catch let authError as AuthError {
            errorMessage = authError.errorDescription
        } catch {
            errorMessage = L10n.Auth.Login.errorGeneric
        }
    }

    private func validateInputs() -> Bool {
        firstNameError       = firstName.trimmed.isEmpty ? L10n.Validation.nameEmpty : nil
        lastNameError        = lastName.trimmed.isEmpty  ? L10n.Validation.nameEmpty : nil
        emailError           = Validators.validateEmail(email)
        confirmEmailError    = email.trimmed != confirmEmail.trimmed
                               ? L10n.Validation.emailMismatch : nil
        passwordError        = Validators.validatePasswordStrong(password)
        confirmPasswordError = Validators.validatePasswordMatch(password, confirmPassword)

        return [firstNameError, lastNameError,
                emailError, confirmEmailError,
                passwordError, confirmPasswordError].allSatisfy { $0 == nil }
    }

    // MARK: - Field Enum

    enum Field: Hashable {
        case firstName, lastName
        case email, confirmEmail, password, confirmPassword
    }
}

// MARK: - String helper

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
