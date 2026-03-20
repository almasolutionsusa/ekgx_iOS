//
//  ExitConfirmationOverlay.swift
//  EKGx
//
//  Modal overlay asking the user to confirm discarding the current recording.
//

import SwiftUI

struct ExitConfirmationOverlay: View {

    let onKeep: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing24) {
                VStack(spacing: AppMetrics.spacing8) {
                    Text(L10n.Recording.Exit.title)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.Recording.Exit.subtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: AppMetrics.spacing16) {
                    PrimaryButton(
                        title: L10n.Recording.Exit.keepButton,
                        background: AppColors.surfaceCard,
                        foreground: AppColors.textPrimary,
                        action: onKeep
                    )
                    PrimaryButton(
                        title: L10n.Recording.Exit.discardButton,
                        background: AppColors.statusCritical,
                        foreground: .white,
                        action: onDiscard
                    )
                }
            }
            .padding(AppMetrics.spacing32)
            .background(AppColors.surfaceBackground)
            .cornerRadius(AppMetrics.radiusLarge)
            .padding(.horizontal, AppMetrics.spacing64)
            .shadow(color: .black.opacity(0.4), radius: 24)
        }
    }
}
