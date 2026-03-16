//
//  ETextField.swift
//  ECGx
//
//  Branded text field component for the ECGx design system.
//  Renders an accessible, focus-aware input with optional leading icon
//  and inline validation error display.
//

import SwiftUI

struct ETextField: View {

    // MARK: - Properties

    let label: String
    let placeholder: String
    let systemImage: String?
    @Binding var text: String
    var errorMessage: String?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never
    var autocorrectionDisabled: Bool = true

    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            // Label
            Text(label)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            // Input container
            HStack(spacing: AppMetrics.spacing12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: AppMetrics.iconSizeSmall, weight: .medium))
                        .foregroundStyle(iconColor)
                        .frame(width: AppMetrics.iconSizeMedium)
                }

                TextField(placeholder, text: $text)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(autocorrectionDisabled)
                    .focused($isFocused)
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .frame(height: AppMetrics.textFieldHeight)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )

            // Inline error
            if let error = errorMessage {
                HStack(spacing: AppMetrics.spacing4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(AppTypography.caption)
                }
                .foregroundStyle(AppColors.statusCritical)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    // MARK: - Derived State

    private var borderColor: Color {
        if errorMessage != nil { return AppColors.statusCritical }
        if isFocused         { return AppColors.borderFocused }
        return AppColors.borderSubtle
    }

    private var borderWidth: CGFloat {
        isFocused || errorMessage != nil
            ? AppMetrics.borderWidthFocused
            : AppMetrics.borderWidth
    }

    private var iconColor: Color {
        if errorMessage != nil { return AppColors.statusCritical }
        if isFocused         { return AppColors.brandPrimary }
        return AppColors.textSecondary
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ETextField(
            label: "Email Address",
            placeholder: "doctor@hospital.com",
            systemImage: "envelope",
            text: .constant(""),
            errorMessage: nil
        )
        ETextField(
            label: "Email Address",
            placeholder: "doctor@hospital.com",
            systemImage: "envelope",
            text: .constant("invalid-email"),
            errorMessage: "Please enter a valid email address"
        )
    }
    .padding(32)
    .background(AppColors.surfaceBackground)
}
