//
//  ErrorBanner.swift
//  EKGx
//
//  Non-intrusive inline error banner displayed below form elements
//  or at the top of a form panel.
//

import SwiftUI

struct ErrorBanner: View {

    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AppMetrics.spacing12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: AppMetrics.iconSizeMedium))
                .foregroundStyle(AppColors.statusCritical)

            Text(message)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.statusCritical)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.statusCritical)
                }
            }
        }
        .padding(AppMetrics.spacing16)
        .background(AppColors.statusCritical.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                .strokeBorder(AppColors.statusCritical.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(AppMetrics.radiusMedium)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ErrorBanner(
            message: "Invalid email or password. Please try again.",
            onDismiss: {}
        )
        ErrorBanner(
            message: "Network unavailable. Check your connection."
        )
    }
    .padding(32)
    .background(AppColors.surfaceBackground)
}
