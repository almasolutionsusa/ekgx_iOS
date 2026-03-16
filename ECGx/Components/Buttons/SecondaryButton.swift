//
//  SecondaryButton.swift
//  ECGx
//
//  Full-width outline / ghost button for secondary actions.
//

import SwiftUI

struct SecondaryButton: View {

    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(isDisabled ? AppColors.brandPrimary.opacity(0.4) : AppColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppMetrics.buttonHeight)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(
                            isDisabled ? AppColors.brandPrimary.opacity(0.4) : AppColors.brandPrimary,
                            lineWidth: 1.5
                        )
                )
        }
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
