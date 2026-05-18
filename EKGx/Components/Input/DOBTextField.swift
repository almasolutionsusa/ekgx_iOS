//
//  DOBTextField.swift
//  EKGx
//
//  Numeric keypad DOB input — type digits, auto-formats as MM-DD-YYYY.
//  Updates the Date? binding once a valid 8-digit date is complete.
//

import SwiftUI

struct DOBTextField: View {

    let label: String
    @Binding var date: Date?
    var errorMessage: String?

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {

            Text(label)
                .font(AppTypography.captionBold)
                .foregroundStyle(isFocused ? AppColors.brandPrimary : AppColors.textSecondary)

            HStack(spacing: AppMetrics.spacing10) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isFocused ? AppColors.brandPrimary : AppColors.textSecondary)

                TextField("MM-DD-YYYY", text: $text)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .tint(AppColors.brandPrimary)
                    .onChange(of: text) { _, newValue in
                        applyFormat(newValue)
                    }

                if !text.isEmpty {
                    Button { text = ""; date = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, AppMetrics.spacing14)
            .frame(height: AppMetrics.buttonHeight)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(
                        errorMessage != nil ? AppColors.statusCritical :
                        isFocused           ? AppColors.borderFocused   : AppColors.borderSubtle,
                        lineWidth: isFocused ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)

            if let err = errorMessage {
                Text(err)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.statusCritical)
            }
        }
        .onAppear { syncFromDate() }
        .onChange(of: date) { _, newDate in
            if newDate == nil { text = "" }
        }
    }

    // MARK: - Format (MM-DD-YYYY)

    private func applyFormat(_ newValue: String) {
        let raw   = newValue.filter(\.isNumber)
        let chars = Array(raw.prefix(8))

        var formatted = ""
        if chars.count > 0 { formatted += String(chars.prefix(2)) }           // MM
        if chars.count > 2 { formatted += "-" + String(chars[2..<min(4, chars.count)]) } // DD
        if chars.count > 4 { formatted += "-" + String(chars[4..<min(8, chars.count)]) } // YYYY

        if formatted != newValue { text = formatted }

        guard chars.count == 8 else { date = nil; return }

        let m = Int(String(chars[0..<2])) ?? 0
        let d = Int(String(chars[2..<4])) ?? 0
        let y = Int(String(chars[4..<8])) ?? 0

        var comps   = DateComponents()
        comps.month = m
        comps.day   = d
        comps.year  = y

        if let parsed = Calendar.current.date(from: comps), parsed <= Date() {
            date = parsed
        } else {
            date = nil
        }
    }

    private func syncFromDate() {
        guard let d = date else { return }
        let c = Calendar.current.dateComponents([.day, .month, .year], from: d)
        guard let day = c.day, let month = c.month, let year = c.year else { return }
        text = String(format: "%02d-%02d-%04d", month, day, year)
    }
}
