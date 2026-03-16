//
//  ESecureField.swift
//  EKGx
//
//  Password field with show/hide toggle. Password remains obscured
//  until the user explicitly taps the visibility icon.
//

import SwiftUI

struct ESecureField: View {

    // MARK: - Properties

    let label: String
    let placeholder: String
    @Binding var text: String
    var errorMessage: String?

    @FocusState private var isSecureFocused: Bool
    @FocusState private var isPlainFocused: Bool
    @State private var isRevealed: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            // Input container
            HStack(spacing: AppMetrics.spacing12) {
                Image(systemName: "lock")
                    .font(.system(size: AppMetrics.iconSizeSmall, weight: .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: AppMetrics.iconSizeMedium)

                ZStack {
                    // Secure field (password hidden)
                    SecureField(placeholder, text: $text)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .textContentType(.password)
                        .focused($isSecureFocused)
                        .opacity(isRevealed ? 0 : 1)

                    // Plain field (password visible)
                    TextField(placeholder, text: $text)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isPlainFocused)
                        .opacity(isRevealed ? 1 : 0)
                }

                // Visibility toggle
                Button {
                    let wasFocused = isSecureFocused || isPlainFocused
                    isRevealed.toggle()
                    if wasFocused {
                        if isRevealed { isPlainFocused = true }
                        else          { isSecureFocused = true }
                    }
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .font(.system(size: AppMetrics.iconSizeSmall, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .accessibilityLabel(
                    isRevealed
                        ? L10n.Common.hidePassword
                        : L10n.Common.showPassword
                )
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

    private var isFocused: Bool { isSecureFocused || isPlainFocused }

    private var borderColor: Color {
        if errorMessage != nil { return AppColors.statusCritical }
        if isFocused           { return AppColors.borderFocused }
        return AppColors.borderSubtle
    }

    private var borderWidth: CGFloat {
        isFocused || errorMessage != nil
            ? AppMetrics.borderWidthFocused
            : AppMetrics.borderWidth
    }

    private var iconColor: Color {
        if errorMessage != nil { return AppColors.statusCritical }
        if isFocused           { return AppColors.brandPrimary }
        return AppColors.textSecondary
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        ESecureField(
            label: "Password",
            placeholder: "Enter your password",
            text: .constant(""),
            errorMessage: nil
        )
        ESecureField(
            label: "Password",
            placeholder: "Enter your password",
            text: .constant("abc"),
            errorMessage: "Password must be at least 8 characters"
        )
    }
    .padding(32)
    .background(AppColors.surfaceBackground)
}
