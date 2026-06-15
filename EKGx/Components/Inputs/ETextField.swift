//
//  ETextField.swift
//  EKGx
//
//  Branded text field component for the EKGx design system.
//  Renders an accessible, focus-aware input with optional leading icon
//  and inline validation error display.
//

import SwiftUI

struct ETextField<Trailing: View>: View {

    // MARK: - Properties

    let label: String?
    let placeholder: String
    let systemImage: String?
    @Binding var text: String
    var errorMessage: String?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never
    var autocorrectionDisabled: Bool = true
    var trailingContent: (() -> Trailing)?

    init(label: String? = nil, placeholder: String, systemImage: String? = nil,
         text: Binding<String>, errorMessage: String? = nil,
         keyboardType: UIKeyboardType = .default,
         textContentType: UITextContentType? = nil,
         autocapitalization: TextInputAutocapitalization = .never,
         autocorrectionDisabled: Bool = true,
         @ViewBuilder trailingContent: @escaping () -> Trailing) {
        self.label = label; self.placeholder = placeholder; self.systemImage = systemImage
        self._text = text; self.errorMessage = errorMessage; self.keyboardType = keyboardType
        self.textContentType = textContentType; self.autocapitalization = autocapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
        self.trailingContent = trailingContent
    }

    @FocusState private var isFocused: Bool
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isCompact: Bool { sizeClass == .compact }
    private var fieldHeight:  CGFloat { isCompact ? 46 : AppMetrics.textFieldHeight }
    private var iconSmall:    CGFloat { isCompact ? 17 : AppMetrics.iconSizeSmall }
    private var iconMedium:   CGFloat { isCompact ? 22 : AppMetrics.iconSizeMedium }
    private var inputFont:    Font    { isCompact ? AppTypography.phoneBodyMedium : AppTypography.body }
    private var labelFont:    Font    { isCompact ? AppTypography.phoneCaption  : AppTypography.captionBold }
    private var errorFont:    Font    { isCompact ? AppTypography.phoneCaption  : AppTypography.caption }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            // Label
            if let label {
                Text(label)
                    .font(labelFont)
                    .foregroundStyle(AppColors.textSecondary)
                    .tracking(0.5)
            }

            // Input container
            HStack(spacing: AppMetrics.spacing12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: iconSmall, weight: .medium))
                        .foregroundStyle(iconColor)
                        .frame(width: iconMedium)
                }

                TextField(placeholder, text: $text)
                    .font(inputFont)
                    .foregroundStyle(AppColors.textPrimary)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(autocorrectionDisabled)
                    .focused($isFocused)

                if !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: iconSmall, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.hapticPlain)
                    .transition(.opacity.combined(with: .scale(scale: 0.7)))
                }

                if let trailing = trailingContent {
                    trailing()
                }
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .frame(height: fieldHeight)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .animation(.easeInOut(duration: 0.15), value: text.isEmpty)

            // Inline error
            if let error = errorMessage {
                HStack(spacing: AppMetrics.spacing4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: isCompact ? 11 : 12))
                    Text(error)
                        .font(errorFont)
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

// MARK: - Convenience init (no trailing)

extension ETextField where Trailing == EmptyView {
    init(label: String? = nil, placeholder: String, systemImage: String? = nil,
         text: Binding<String>, errorMessage: String? = nil,
         keyboardType: UIKeyboardType = .default,
         textContentType: UITextContentType? = nil,
         autocapitalization: TextInputAutocapitalization = .never,
         autocorrectionDisabled: Bool = true) {
        self.label = label; self.placeholder = placeholder; self.systemImage = systemImage
        self._text = text; self.errorMessage = errorMessage; self.keyboardType = keyboardType
        self.textContentType = textContentType; self.autocapitalization = autocapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
        self.trailingContent = nil
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
