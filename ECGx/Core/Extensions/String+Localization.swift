//
//  String+Localization.swift
//  ECGx
//
//  Convenience extension for type-safe localized string lookup.
//

import Foundation

extension String {

    /// Returns the localized string for this key from Localizable.strings.
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Returns a localized format string with the given arguments substituted.
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
