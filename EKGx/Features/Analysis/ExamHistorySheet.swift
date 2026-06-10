//
//  ExamHistorySheet.swift
//  EKGx
//
//  Lists all ECG exams for the current patient.
//  From here the user can switch to any exam or launch a side-by-side compare.
//

import SwiftUI

// MARK: - ExamHistorySheet

struct ExamHistorySheet: View {

    @Bindable var viewModel: AnalysisViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                sheetNav

                Divider()

                if viewModel.patientExams.isEmpty {
                    emptyState
                } else {
                    examList
                }
            }
        }
    }

    // MARK: - Nav

    private var sheetNav: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Exam History")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.patientExams.first.map { $0.patientName } ?? "")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(AppColors.borderSubtle.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(.hapticPlain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - List

    private var examList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.patientExams) { exam in
                    ExamHistoryRow(
                        exam: exam,
                        isCurrent: exam.id == viewModel.localRecordingId,
                        canCompare: exam.id != viewModel.localRecordingId,
                        onSwitch: {
                            viewModel.switchToExam(exam)
                            dismiss()
                        },
                        onCompare: {
                            viewModel.startCompare(with: exam)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppColors.textSecondary.opacity(0.4))
            Text("No other exams found")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
    }
}

// MARK: - ExamHistoryRow

private struct ExamHistoryRow: View {

    let exam: ECGRecording
    let isCurrent: Bool
    let canCompare: Bool
    let onSwitch: () -> Void
    let onCompare: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {

                // Date + Time
                VStack(alignment: .leading, spacing: 3) {
                    Text(exam.formattedDate)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(exam.formattedTime)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                // Status + Current badge
                HStack(spacing: 8) {
                    if isCurrent {
                        Text("Current")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColors.brandPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(AppColors.brandPrimary.opacity(0.1))
                            .cornerRadius(6)
                    }
                    statusBadge
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Action buttons
            if !isCurrent {
                Divider().padding(.horizontal, 16)

                HStack(spacing: 10) {
                    actionButton(label: "View Exam", icon: "eye.fill", color: AppColors.brandPrimary, action: onSwitch)
                    actionButton(label: "Compare", icon: "square.split.2x1.fill", color: AppColors.accentTeal, action: onCompare)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .background(isCurrent ? AppColors.brandPrimary.opacity(0.04) : AppColors.surfaceCard)
        .cornerRadius(AppMetrics.radiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .stroke(isCurrent ? AppColors.brandPrimary.opacity(0.3) : AppColors.borderSubtle.opacity(0.4), lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: exam.status.systemImage)
                .font(.system(size: 10))
            Text(exam.status.label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.1))
        .cornerRadius(6)
    }

    private var statusColor: Color {
        switch exam.status {
        case .synced:  return AppColors.statusSuccess
        case .pending: return AppColors.statusWarning
        case .failed:  return AppColors.statusCritical
        }
    }

    private func actionButton(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(color.opacity(0.1))
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.hapticPlain)
    }
}
