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

    // MARK: - Username (email or plain username)

    static func validateUsername(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.Validation.emailEmpty : nil
    }

    // MARK: - Password

    static func validatePassword(_ password: String) -> String? {
        if password.isEmpty { return L10n.Validation.passwordEmpty }
        return password.count < 4 ? L10n.Validation.passwordTooShort : nil
    }

    /// HIPAA-compliant password: 8+ chars, must contain a letter,
    /// a digit, and a special character.
    static func validatePasswordStrong(_ password: String) -> String? {
        if password.isEmpty { return L10n.Validation.passwordEmpty }
        if password.count < 8 { return L10n.Validation.passwordTooShort }

        let hasLetter  = password.rangeOfCharacter(from: .letters) != nil
        let hasDigit   = password.rangeOfCharacter(from: .decimalDigits) != nil
        let specialSet = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:'\",.<>/?`~\\")
        let hasSpecial = password.rangeOfCharacter(from: specialSet) != nil

        if !hasLetter  { return L10n.Validation.passwordNoLowercase }
        if !hasDigit   { return L10n.Validation.passwordNoDigit }
        if !hasSpecial { return L10n.Validation.passwordNoSpecial }
        return nil
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
