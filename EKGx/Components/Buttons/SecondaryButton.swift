//
//  SecondaryButton.swift
//  EKGx
//
//  Full-width outline / ghost button for secondary actions.
//

import SwiftUI

struct SecondaryButton: View {

    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var resolvedFont: Font {
        sizeClass == .compact ? AppTypography.phoneBodyMedium : AppTypography.bodyMedium
    }
    private var resolvedHeight: CGFloat {
        sizeClass == .compact ? 48 : AppMetrics.buttonHeight
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(resolvedFont)
                .foregroundStyle(isDisabled ? AppColors.accentTeal.opacity(0.4) : AppColors.accentTeal)
                .frame(maxWidth: .infinity)
                .frame(height: resolvedHeight)
                .background(Color.clear)
                .contentShape(Rectangle())
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(
                            isDisabled ? AppColors.accentTeal.opacity(0.4) : AppColors.accentTeal,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.hapticPlain)
        .disabled(isDisabled)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Create Account", action: {})
        SecondaryButton(title: "Create Account", isDisabled: true, action: {})
    }
    .padding(32)
    .background(AppColors.surfaceBackground)
}
