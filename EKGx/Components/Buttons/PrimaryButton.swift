//
//  PrimaryButton.swift
//  EKGx
//
//  Full-width CTA button with loading state support.
//

import SwiftUI

struct PrimaryButton: View {

    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppMetrics.buttonHeight)
            .background(
                isDisabled || isLoading
                    ? AppColors.brandPrimary.opacity(0.5)
                    : AppColors.brandPrimary
            )
            .cornerRadius(AppMetrics.radiusMedium)
        }
        .disabled(isDisabled || isLoading)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Sign In", action: {})
        PrimaryButton(title: "Sign In", isLoading: true, action: {})
        PrimaryButton(title: "Sign In", isDisabled: true, action: {})
    }
    .padding(32)
    .background(AppColors.surfaceBackground)
}
