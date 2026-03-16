//
//  Validators.swift
//  EKGx
//
//  Pure validation functions. Each function returns a localized error string
//  when validation fails, or nil when the input is valid.
//

import Foundation

struct Validators {

    // MARK: - Email

    static func validateEmail(_ email: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return L10n.Validation.emailEmpty
        }
        let emailRegex = "^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: trimmed) ? nil : L10n.Validation.emailInvalid
    }

    // MARK: - Password

    static func validatePassword(_ password: String) -> String? {
        if password.isEmpty { return L10n.Validation.passwordEmpty }
        return password.count < 8 ? L10n.Validation.passwordTooShort : nil
    }

    static func validatePasswordMatch(_ password: String, _ confirmation: String) -> String? {
        return password == confirmation ? nil : L10n.Validation.passwordMismatch
    }

    // MARK: - Name

    static func validateName(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.Validation.nameEmpty : nil
    }
}
