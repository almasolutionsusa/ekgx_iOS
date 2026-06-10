//
//  ExamCompareView.swift
//  EKGx
//
//  Side-by-side comparison of two ECG exams for the same patient.
//  Left = current exam (live analysis data).
//  Right = selected exam (raw ECG loaded from store, measurements from snapshot).
//

import SwiftUI

// MARK: - ExamCompareView

struct ExamCompareView: View {

    @Bindable var viewModel: AnalysisViewModel
    @Environment(\.dismiss) private var dismiss

    private var compare: ECGRecording? { viewModel.compareRecording }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                Divider()

                GeometryReader { geo in
                    VStack(spacing: 0) {
                        // ── Exam headers (Current | Compare) ─────────────
                        examHeadersRow
                            .fixedSize(horizontal: false, vertical: true)

                        // ── Interpretation (70pt, horizontal scroll) ──────
                        interpretationSection

                        Divider()

                        // ── ECG traces ────────────────────────────────────
                        HStack(spacing: 0) {
                            examPanel(
                                ecgData: viewModel.ecgData,
                                templateData: viewModel.templateData,
                                sampleRate: viewModel.sampleRate
                            )

                            Rectangle()
                                .fill(AppColors.borderSubtle.opacity(0.6))
                                .frame(width: 1)

                            examPanel(
                                ecgData: viewModel.compareECGData,
                                templateData: viewModel.compareECGData,
                                sampleRate: compare?.sampleRate ?? 660
                            )
                        }
                        .frame(height: geo.size.height * 0.6)

                        Divider()

                        // ── Measurement cards (full width) ────────────────
                        measurementTable
                            .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Back")
                        .font(AppTypography.callout)
                }
                .foregroundStyle(AppColors.brandPrimary)
            }
            .buttonStyle(.hapticPlain)

            Spacer()

            HStack(spacing: 0) {
                Text(L10n.Compare.title + " - ")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.patientExams.first?.patientName ?? "")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Spacer to balance back button
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                Text("Back")
                    .font(AppTypography.callout)
            }
            .opacity(0)
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .frame(height: 40)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(UIColor.systemGray5)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Exam Headers Row

    private var examHeadersRow: some View {
        HStack(spacing: 0) {
            examHeader(title: L10n.Compare.currentExam, date: currentDateLabel, isCurrent: true)
            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.6))
                .frame(width: 1)
            examHeader(title: L10n.Compare.compareExam, date: compareDateLabel, isCurrent: false)
        }
    }

    private func examHeader(title: String, date: String, isCurrent: Bool) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isCurrent ? AppColors.brandPrimary : AppColors.accentTeal)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(isCurrent ? AppColors.brandPrimary : AppColors.accentTeal)
                Text(date)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background((isCurrent ? AppColors.brandPrimary : AppColors.accentTeal).opacity(0.05))
    }

    // MARK: - Exam Panel (ECG waveform only)

    @ViewBuilder
    private func examPanel(ecgData: ECGLeads, templateData: ECGLeads, sampleRate: Int) -> some View {
        if ecgData.isEmpty {
            VStack {
                Spacer()
                ProgressView().tint(AppColors.brandPrimary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            EKGStaticView(templateData: templateData, fullData: ecgData, sampleRate: sampleRate)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Bottom Panel

    private var interpretationSection: some View {
        HStack(alignment: .top, spacing: 0) {
            interpretationColumn(lines: viewModel.diagnosisLines, color: AppColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.4))
                .frame(width: 1)
            interpretationColumn(lines: compare?.diagnosis?.components(separatedBy: "; ") ?? [], color: AppColors.accentTeal)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
        .frame(height: 40)
        .clipped()
        .background(AppColors.surfaceCard)
    }

    private var measurementTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeader(L10n.Analysis.Section.measurements, color: AppColors.textSecondary)
            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 4),
                    spacing: 8
                ) {
                    ForEach(measurementRows, id: \.label) { row in
                        measurementCard(row)
                    }
                }
                .padding(12)
            }
        }
        .background(AppColors.surfaceCard)
    }

    private func panelHeader(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(AppTypography.captionBold)
            .foregroundStyle(color)
            .tracking(1.1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(AppColors.surfaceBackground)
            .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)
    }

    private func measurementCard(_ row: MeasurementRow) -> some View {
        let delta = computeDelta(current: row.current, compare: row.compare)
        return VStack(alignment: .leading, spacing: 5) {
            Text(row.label)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(row.current.isEmpty ? "—" : row.current)
                    .font(AppTypography.calloutBold)
                    .foregroundStyle(AppColors.brandPrimary)
                    .lineLimit(1)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
                Text(row.compare.isEmpty ? "—" : row.compare)
                    .font(AppTypography.calloutBold)
                    .foregroundStyle(AppColors.accentTeal)
                    .lineLimit(1)
            }

            if let (text, positive) = delta {
                HStack(spacing: 3) {
                    Image(systemName: positive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 14))
                    Text(text)
                        .font(AppTypography.caption)
                }
                .foregroundStyle(positive ? AppColors.statusCritical : AppColors.statusSuccess)
            } else {
                Text(L10n.Compare.noChange)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceBackground)
        .cornerRadius(AppMetrics.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                .stroke(AppColors.borderSubtle.opacity(0.4), lineWidth: 1)
        )
    }

    private func interpretationColumn(lines: [String], color: Color) -> some View {
        HStack(spacing: 5) {
            if lines.isEmpty {
                Text(L10n.Compare.noInterpretation)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ForEach(lines.filter { !$0.isEmpty }, id: \.self) { line in
                    ScrollView {
                        HStack(alignment: .top, spacing: 5) {
                            Circle()
                                .fill(color.opacity(0.6))
                                .frame(width: 5, height: 5)
                                .padding(.top, 5)
                            Text(line)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Data

    private struct MeasurementRow {
        let label: String
        let current: String
        let compare: String
    }

    private var measurementRows: [MeasurementRow] {
        [
            MeasurementRow(label: L10n.Analysis.Measure.hr,      current: viewModel.mergeHR,      compare: compare?.heartRate   ?? ""),
            MeasurementRow(label: L10n.Analysis.Measure.pr,      current: viewModel.mergePR,      compare: compare?.prInterval  ?? ""),
            MeasurementRow(label: L10n.Analysis.Measure.qrs,     current: viewModel.mergeQRS,     compare: compare?.qrsDuration ?? ""),
            MeasurementRow(label: L10n.Analysis.Measure.qt,      current: viewModel.mergeQT,      compare: compare?.qtInterval  ?? ""),
            MeasurementRow(label: L10n.Analysis.Measure.qtc,     current: viewModel.mergeQTc,     compare: compare?.qtCorrected ?? ""),
            MeasurementRow(label: L10n.Analysis.Measure.paxis,   current: viewModel.mergePaxis,   compare: ""),
            MeasurementRow(label: L10n.Analysis.Measure.qrsaxis, current: viewModel.mergeQRSaxis, compare: ""),
        ]
    }

    private var currentDateLabel: String {
        guard let id = viewModel.localRecordingId,
              let exam = viewModel.patientExams.first(where: { $0.id == id }) else {
            return "Current"
        }
        return "\(exam.formattedDate) \(exam.formattedTime)"
    }

    private var compareDateLabel: String {
        guard let c = compare else { return "Selected" }
        return "\(c.formattedDate) \(c.formattedTime)"
    }

    private func computeDelta(current: String, compare: String) -> (String, Bool)? {
        let curNum = Double(current.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
        let cmpNum = Double(compare.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
        guard let a = curNum, let b = cmpNum, b != 0 else { return nil }
        let diff = a - b
        guard abs(diff) >= 1 else { return nil }
        return (String(format: "%.0f", abs(diff)), diff > 0)
    }
}
