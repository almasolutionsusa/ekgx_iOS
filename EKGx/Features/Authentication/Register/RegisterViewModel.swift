//
//  RegisterViewModel.swift
//  EKGx
//

import Foundation

@Observable
@MainActor
final class RegisterViewModel {

    // MARK: - Mandatory Input

    var firstName: String    = ""
    var lastName: String     = ""
    var phone: String        = ""
    var email: String        = ""
    var confirmEmail: String = ""
    var password: String     = ""
    var confirmPassword: String = ""

    /// Selected title — required. Values come from the server (titles enum).
    var title: String? = nil
    /// Selected degree — required. Values come from the server (degrees enum).
    var degree: String? = nil
    /// Optional NPI identifier.
    var npi: String = ""

    // MARK: - Server-provided enum options (from GET /api/app/info)

    var titles: [String]  = []
    var degrees: [String] = []

    // MARK: - Resolved Facility (from GET /api/app/info)

    var facilityName: String = ""
    var organizationName: String = ""
    var facilityId: Int64? = nil
    var isLoadingFacility: Bool = false
    var facilityNotAssigned: Bool = false

    // MARK: - UI State

    var isLoading: Bool       = false
    var errorMessage: String? = nil

    // Per-field errors
    var firstNameError: String?     = nil
    var lastNameError: String?      = nil
    var titleError: String?         = nil
    var degreeError: String?        = nil
    var emailError: String?         = nil
    var confirmEmailError: String?  = nil
    var passwordError: String?      = nil
    var confirmPasswordError: String? = nil

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private let appInfoService: AppInfoService
    private let router: AppRouter

    init(authService: AuthServiceProtocol, appInfoService: AppInfoService, router: AppRouter) {
        self.authService    = authService
        self.appInfoService = appInfoService
        self.router         = router
    }

    // MARK: - Activation (called from RegisterView.onAppear)

    func activate() {
        guard facilityName.isEmpty, !isLoadingFacility else { return }
        Task { await loadAppInfo() }
    }

    private func loadAppInfo() async {
        isLoadingFacility   = true
        facilityNotAssigned = false
        defer { isLoadingFacility = false }

        guard let data = await appInfoService.getInfo() else {
            facilityNotAssigned = true
            return
        }

        titles  = data.titles  ?? []
        degrees = data.degrees ?? []

        if data.assigned == true, let name = data.facilityName, !name.isEmpty {
            facilityId       = data.facilityId
            facilityName     = name
            organizationName = data.organizationName ?? ""
        } else {
            facilityNotAssigned = true
        }
    }

    // MARK: - Actions

    func register() {
        guard validateInputs() else { return }
        guard !facilityNotAssigned else {
            errorMessage = L10n.Auth.Register.errorFacilityNotAssigned
            return
        }
        Task { await performRegister() }
    }

    func navigateToLogin() {
        router.navigate(to: .login)
    }

    func clearFieldError(for field: Field) {
        switch field {
        case .firstName:       firstNameError = nil
        case .lastName:        lastNameError = nil
        case .title:           titleError = nil
        case .degree:          degreeError = nil
        case .email:           emailError = nil
        case .confirmEmail:    confirmEmailError = nil
        case .password:        passwordError = nil
        case .confirmPassword: confirmPasswordError = nil
        case .npi, .phone:     break
        }
        errorMessage = nil
    }

    // MARK: - Private

    private func performRegister() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let details = SignupDetails(
            firstName:       firstName.trimmed,
            lastName:        lastName.trimmed,
            phone:           phone.trimmed,
            email:           email.trimmed,
            confirmEmail:    confirmEmail.trimmed,
            password:        password,
            confirmPassword: confirmPassword,
            title:           title ?? "",
            degree:          degree ?? "",
            npi:             npi.trimmed
        )

        do {
            try await authService.register(details: details)
            router.navigate(to: .dashboard)
        } catch let authError as AuthError {
            errorMessage = authError.errorDescription
        } catch {
            errorMessage = L10n.Auth.Login.errorGeneric
        }
    }

    private func validateInputs() -> Bool {
        firstNameError    = firstName.trimmed.isEmpty  ? L10n.Validation.nameEmpty : nil
        lastNameError     = lastName.trimmed.isEmpty   ? L10n.Validation.nameEmpty : nil
        titleError        = (title?.isEmpty ?? true)   ? L10n.Validation.required : nil
        degreeError       = (degree?.isEmpty ?? true)  ? L10n.Validation.required : nil
        emailError        = Validators.validateEmail(email)
        confirmEmailError = email.trimmed != confirmEmail.trimmed
                            ? L10n.Validation.emailMismatch : nil
        passwordError        = Validators.validatePasswordStrong(password)
        confirmPasswordError = Validators.validatePasswordMatch(password, confirmPassword)

        return [firstNameError, lastNameError, titleError, degreeError,
                emailError, confirmEmailError,
                passwordError, confirmPasswordError].allSatisfy { $0 == nil }
    }

    // MARK: - Field Enum

    enum Field: Hashable {
        case firstName, lastName, phone
        case email, confirmEmail, password, confirmPassword
        case title, degree, npi
    }
}

// MARK: - String helper

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
