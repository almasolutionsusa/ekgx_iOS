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
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showCompareDropdown = false
    private var isCompact: Bool { sizeClass == .compact }

    private var compare: ECGRecording? { viewModel.compareRecording }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar

                Divider()

                GeometryReader { geo in
                    let panelWidth: CGFloat = isCompact ? 760 : geo.size.width
                    ScrollView(isCompact ? [.horizontal] : [], showsIndicators: false) {
                        VStack(spacing: 0) {
                            // ── Exam headers (Current | Compare) ─────────────
                            examHeadersRow
                                .fixedSize(horizontal: false, vertical: true)

                            // ── Interpretation ────────────────────────────────
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
                        .frame(width: panelWidth, height: geo.size.height)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        CompareNavBar(
            patientName: viewModel.patientExams.first?.patientName ?? "",
            onDismiss: { dismiss() }
        )
    }

    // MARK: - Exam Headers Row

    private var examHeadersRow: some View {
        HStack(spacing: 0) {
            // Current exam header — static
            HStack(spacing: AppMetrics.spacing8) {
                Circle()
                    .fill(AppColors.brandPrimary)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Compare.currentExam)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.brandPrimary)
                    Text(currentDateLabel)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, AppMetrics.spacing14)
            .padding(.vertical, AppMetrics.spacing8)
            .frame(maxWidth: .infinity)
            .background(AppColors.brandPrimary.opacity(0.05))

            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.6))
                .frame(width: 1)

            // Compare exam header — tappable dropdown
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { showCompareDropdown.toggle() }
            } label: {
                HStack(spacing: AppMetrics.spacing8) {
                    Circle()
                        .fill(AppColors.accentTeal)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Compare.compareExam)
                            .font(AppTypography.captionBold)
                            .foregroundStyle(AppColors.accentTeal)
                        Text(compareDateLabel)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: showCompareDropdown ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.accentTeal)
                        .animation(.easeInOut(duration: 0.15), value: showCompareDropdown)
                }
                .padding(.horizontal, AppMetrics.spacing14)
                .padding(.vertical, AppMetrics.spacing8)
                .frame(maxWidth: .infinity)
                .background(AppColors.accentTeal.opacity(showCompareDropdown ? 0.10 : 0.05))
                .animation(.easeInOut(duration: 0.15), value: showCompareDropdown)
            }
            .buttonStyle(.hapticPlain)
            .popover(isPresented: $showCompareDropdown, arrowEdge: .top) {
                compareExamPicker
                    .frame(minWidth: 300)
                    .presentationBackground(AppColors.surfaceCard)
            }
        }
    }

    // MARK: - Compare Exam Picker (popover content)

    private var compareExamPicker: some View {
        let currentId = viewModel.localRecordingId
        let available = viewModel.patientExams.filter { $0.id != currentId }

        return VStack(spacing: 0) {
            Text(L10n.Compare.selectExam)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppMetrics.spacing14)
                .padding(.vertical, AppMetrics.spacing8)
                .background(AppColors.surfaceBackground)
                .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)

            if available.isEmpty {
                Text(L10n.Compare.noExams)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.vertical, AppMetrics.spacing20)
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(available) { exam in
                            let isSelected = exam.id == viewModel.compareRecording?.id
                            Button {
                                showCompareDropdown = false
                                viewModel.startCompare(with: exam)
                            } label: {
                                HStack(spacing: AppMetrics.spacing10) {
                                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                                        Text("\(exam.formattedDate)  ·  \(exam.formattedTime)")
                                            .font(AppTypography.callout)
                                            .foregroundStyle(AppColors.textPrimary)
                                        if let hr = exam.heartRate, !hr.isEmpty {
                                            Text(L10n.Compare.hrBpm(hr))
                                                .font(AppTypography.caption)
                                                .foregroundStyle(AppColors.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppColors.accentTeal)
                                            .font(.system(size: 16))
                                    }
                                }
                                .padding(.horizontal, AppMetrics.spacing14)
                                .padding(.vertical, AppMetrics.spacing12)
                                .background(isSelected ? AppColors.accentTeal.opacity(0.06) : Color.clear)
                            }
                            .buttonStyle(.hapticPlain)

                            if exam.id != available.last?.id {
                                Divider().padding(.leading, AppMetrics.spacing14)
                            }
                        }
                    }
                }
            }
        }
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
                .padding(.horizontal, AppMetrics.spacing12)
            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.4))
                .frame(width: 1)
            interpretationColumn(lines: compare?.diagnosis?.components(separatedBy: "; ") ?? [], color: AppColors.accentTeal)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppMetrics.spacing12)
        }
        .padding(.vertical, AppMetrics.spacing8)
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
                    spacing: AppMetrics.spacing8
                ) {
                    ForEach(measurementRows, id: \.label) { row in
                        measurementCard(row)
                    }
                }
                .padding(AppMetrics.spacing12)
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
            .padding(.horizontal, AppMetrics.spacing14)
            .padding(.vertical, AppMetrics.spacing8)
            .background(AppColors.surfaceBackground)
            .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)
    }

    private func measurementCard(_ row: MeasurementRow) -> some View {
        let delta = computeDelta(current: row.current, compare: row.compare)
        return VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(row.label)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: AppMetrics.spacing6) {
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
                HStack(spacing: AppMetrics.spacing4) {
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
        .padding(AppMetrics.spacing10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceBackground)
        .cornerRadius(AppMetrics.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                .stroke(AppColors.borderSubtle.opacity(0.4), lineWidth: 1)
        )
    }

    private func interpretationColumn(lines: [String], color: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppMetrics.spacing10) {
                if lines.isEmpty {
                    Text(L10n.Compare.noInterpretation)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    ForEach(lines.filter { !$0.isEmpty }, id: \.self) { line in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(color.opacity(0.7))
                                .frame(width: 5, height: 5)
                            Text(line)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textPrimary)
                                .fixedSize(horizontal: true, vertical: false)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, AppMetrics.spacing4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            return L10n.Compare.currentExam
        }
        return "\(exam.formattedDate) \(exam.formattedTime)"
    }

    private var compareDateLabel: String {
        guard let c = compare else { return L10n.Compare.compareExam }
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

// MARK: - Compare Nav Bar

private struct CompareNavBar: View {

    let patientName: String
    let onDismiss: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        HStack(spacing: AppMetrics.spacing12) {
            // Back button
            Button(action: onDismiss) {
                if isCompact {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(AppColors.borderSubtle.opacity(0.4))
                        .clipShape(Circle())
                } else {
                    HStack(spacing: AppMetrics.spacing6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text(L10n.Common.back)
                            .font(AppTypography.callout)
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppMetrics.spacing12)
                    .padding(.vertical, AppMetrics.spacing6)
                    .background(AppColors.borderSubtle.opacity(0.4))
                    .cornerRadius(AppMetrics.radiusMedium)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 1) {
                Text(L10n.Compare.title)
                    .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text(patientName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)

            Spacer()

            // Invisible mirror to keep title centered
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 34, height: 34)
                .opacity(0)
        }
        .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing24)
        .frame(height: isCompact ? 52 : 40)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.6)).frame(height: 1), alignment: .bottom)
    }
}
