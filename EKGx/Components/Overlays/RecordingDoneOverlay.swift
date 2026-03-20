//
//  RecordingDoneOverlay.swift
//  EKGx
//
//  Modal overlay shown after a recording completes.
//  Displays a patient summary and offers Redo / View Analysis actions.
//

import SwiftUI

struct RecordingDoneOverlay: View {

    let patient: Patient
    let elapsedFormatted: String
    let onRedo: () -> Void
    let onAnalysis: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing24) {
                headerSection
                patientSummaryRow
                actionButtons
            }
            .padding(AppMetrics.spacing32)
            .background(AppColors.surfaceBackground)
            .cornerRadius(AppMetrics.radiusLarge)
            .padding(.horizontal, AppMetrics.spacing64)
            .shadow(color: .black.opacity(0.4), radius: 24)
        }
    }

    private var headerSection: some View {
        VStack(spacing: AppMetrics.spacing8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.statusSuccess)

            Text(L10n.Recording.Done.title)
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.textPrimary)

            Text(L10n.Recording.Done.durationLabel(elapsedFormatted))
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var patientSummaryRow: some View {
        HStack(spacing: AppMetrics.spacing16) {
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary)
                    .frame(width: 48, height: 48)
                Text(patient.initials)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(patient.fullName)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: AppMetrics.spacing12) {
                    Label(patient.age, systemImage: "person.fill")
                    Label(patient.genderDisplay, systemImage: "heart.fill")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(AppMetrics.spacing16)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppMetrics.radiusMedium)
    }

    private var actionButtons: some View {
        HStack(spacing: AppMetrics.spacing16) {
            PrimaryButton(
                title: L10n.Recording.Done.redoButton,
                background: AppColors.surfaceCard,
                foreground: AppColors.textPrimary,
                action: onRedo
            )
            PrimaryButton(
                title: L10n.Recording.Done.analysisButton,
                background: AppColors.brandPrimary,
                foreground: .white,
                action: onAnalysis
            )
        }
    }
}
