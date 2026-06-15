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
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing24) {
                headerSection
                patientSummaryRow
                actionButtons
            }
            .padding(isCompact ? AppMetrics.spacing24 : AppMetrics.spacing32)
            .background(AppColors.surfaceBackground)
            .cornerRadius(AppMetrics.radiusLarge)
            .padding(.horizontal, isCompact ? AppMetrics.spacing20 : UIScreen.main.bounds.size.width * 0.2)
            .shadow(color: .black.opacity(0.4), radius: 24)
        }
    }

    private var headerSection: some View {
        VStack(spacing: AppMetrics.spacing8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: isCompact ? 40 : 48))
                .foregroundStyle(AppColors.statusSuccess)

            Text(L10n.Recording.Done.title)
                .font(isCompact ? AppTypography.phoneTitle : AppTypography.title2)
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
                    .frame(width: isCompact ? 40 : 48, height: isCompact ? 40 : 48)
                Text(patient.initials)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(patient.fullName)
                    .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: AppMetrics.spacing12) {
                    Label(patient.age, systemImage: "person.fill")
                    Label(patient.genderDisplay, systemImage: "heart.fill")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(isCompact ? AppMetrics.spacing12 : AppMetrics.spacing16)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppMetrics.radiusMedium)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if isCompact {
            VStack(spacing: AppMetrics.spacing12) {
                PrimaryButton(
                    title: L10n.Recording.Done.redoButton,
                    background: AppColors.surfaceCard,
                    foreground: AppColors.textPrimary,
                    useGradient: false,
                    action: onRedo
                )
                PrimaryButton(
                    title: L10n.Recording.Done.analysisButton,
                    action: onAnalysis
                )
            }
        } else {
            HStack(spacing: AppMetrics.spacing16) {
                PrimaryButton(
                    title: L10n.Recording.Done.redoButton,
                    background: AppColors.surfaceCard,
                    foreground: AppColors.textPrimary,
                    useGradient: false,
                    action: onRedo
                )
                PrimaryButton(
                    title: L10n.Recording.Done.analysisButton,
                    action: onAnalysis
                )
            }
        }
    }
}
