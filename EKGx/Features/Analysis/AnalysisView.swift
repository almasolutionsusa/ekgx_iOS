//
//  AnalysisView.swift
//  EKGx
//
//  ┌──────────────────────────────────────────────────────┬──────┐
//  │  [← Back]  Patient info  ECG Analysis · Unconfirmed  🕐   │ ≡ │
//  ├──────────────────────────────────────────────────────┴──────┤
//  │  HR: 72  PR: 160  QRS: 88  QT: 380  …   Interpretation    │
//  ├─────────────────────────────────────────────────────────────┤
//  │                                                             │
//  │               Full-width 3×4 ECG waveform                  │
//  │                                                             │
//  └─────────────────────────────────────────────────────────────┘
//  Right-side slide menus: controls · visualization · diagnosis · reject
//

import SwiftUI

struct AnalysisView: View {

    @State private var viewModel: AnalysisViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    init(viewModel: AnalysisViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceCard.ignoresSafeArea()

            VStack(spacing: 0) {
                AnalysisNavBar(viewModel: viewModel)

                switch viewModel.state {
                case .analyzing: analyzingBody
                case .success:   successBody
                case .failed:    failedBody
                }
            }

            if viewModel.showDiagnosisPanel {
                AnalysisDiagnosisPanel(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(10)
            }
            if viewModel.showRejectConfirm {
                RejectConfirmSheet(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(10)
            }
            if viewModel.isUploading || viewModel.showUploadResult {
                UploadStatusOverlay(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(20)
            }
            if viewModel.showEmergencyPinSheet {
                EmergencyPinOverlay(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(30)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showControlsMenu)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showVisualizationMenu)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showRejectConfirm)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isUploading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showUploadResult)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showEmergencyPinSheet)
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .onAppear { viewModel.runAnalysis() }
        .sheet(isPresented: $viewModel.showAssignPatientSheet) {
            EmergencyAssignPatientSheet(viewModel: viewModel)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $viewModel.showExamHistory, onDismiss: {
            viewModel.openCompareIfPending()
        }) {
            ExamHistorySheet(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $viewModel.showCompareView) {
            ExamCompareView(viewModel: viewModel)
        }
    }

    // MARK: - Analyzing

    private var analyzingBody: some View {
        VStack(spacing: AppMetrics.spacing16) {
            Spacer()
            ProgressView().scaleEffect(1.4).tint(AppColors.brandPrimary)
            Text(L10n.Common.loading).font(AppTypography.callout).foregroundStyle(AppColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Success

    private var successBody: some View {
        VStack(spacing: 0) {
            if let m = viewModel.measurements {
                InfoStrip(
                    measurements: m,
                    diagnosisLines: viewModel.diagnosisLines,
                    isEmergency: viewModel.showEmergencyBanner,
                    performedBy: viewModel.performedBy
                )
            }
            Divider()

            ZStack {
                switch viewModel.visualizationMode {
                case .standard:
                    EKGStaticView(
                        templateData: viewModel.templateData,
                        fullData: viewModel.ecgData,
                        sampleRate: viewModel.sampleRate
                    )
                case .layers:
                    ECGLayersView(viewModel: viewModel)
                case .table:
                    LeadParamsTableOverlay(
                        leadNames: viewModel.leadNames,
                        leadParams: viewModel.orderedLeadParams
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Failed

    private var failedBody: some View {
        VStack(spacing: AppMetrics.spacing24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(AppColors.statusWarning)
            VStack(spacing: AppMetrics.spacing8) {
                Text(L10n.Analysis.Failed.title)
                    .font(isCompact ? AppTypography.phoneTitle : AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Analysis.Failed.subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppMetrics.spacing40)
            }
            Button(L10n.Analysis.Failed.redoButton) { viewModel.goBack() }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, AppMetrics.spacing32)
                .padding(.vertical, AppMetrics.spacing14)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Info Strip

private struct InfoStrip: View {

    let measurements: vhMeasurements
    let diagnosisLines: [String]
    var isEmergency: Bool = false
    var performedBy: String = ""
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        if isCompact { compactBody } else { regularBody }
    }

    private var regularBody: some View {
        HStack(alignment: .center, spacing: 0) {

            // HR
            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.Analysis.Measure.hr)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(measurements.merge.hr.isEmpty ? "—" : measurements.merge.hr)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .monospacedDigit()
                    Text(L10n.Analysis.Measure.unitBpm)
                        .font(.system(size: 9))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, AppMetrics.spacing14)
            .padding(.vertical, AppMetrics.spacing8)

            stripSeparator()

            HStack(spacing: AppMetrics.spacing14) {
                measureItem(L10n.Analysis.Measure.pr,      measurements.merge.pr,      L10n.Analysis.Measure.unitMs)
                measureItem(L10n.Analysis.Measure.qrs,     measurements.merge.qrs,     L10n.Analysis.Measure.unitMs)
                measureItem(L10n.Analysis.Measure.qt,      measurements.merge.qt,      L10n.Analysis.Measure.unitMs)
                measureItem(L10n.Analysis.Measure.qtc,     measurements.merge.qTc,     L10n.Analysis.Measure.unitMs)
                measureItem("P°",                          measurements.merge.paxis,   L10n.Analysis.Measure.unitDeg)
                measureItem("QRS°",                        measurements.merge.qrSaxis, L10n.Analysis.Measure.unitDeg)
                measureItem("T°",                          measurements.merge.taxis,   L10n.Analysis.Measure.unitDeg)
            }
            .padding(.horizontal, AppMetrics.spacing14)

            stripSeparator()

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Analysis.Section.interpretation.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .tracking(0.5)
                Text(diagnosisLines.isEmpty ? "—" : diagnosisLines.joined(separator: " · "))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppMetrics.spacing14)
            .padding(.vertical, AppMetrics.spacing8)

            if isEmergency {
                stripSeparator()
                Text(L10n.PatientExams.rapidEkg)
                    .font(AppTypography.calloutBold)
                    .foregroundStyle(AppColors.statusCritical)
                    .padding(.horizontal, AppMetrics.spacing16)
                    .padding(.vertical, AppMetrics.spacing6)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                            .stroke(AppColors.statusCritical, lineWidth: 1.5)
                    )
                    .padding(.horizontal, AppMetrics.spacing14)
            } else if !performedBy.isEmpty {
                stripSeparator()
                Text(L10n.Analysis.Nav.performedBy(performedBy))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, AppMetrics.spacing14)
            }
        }
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.6)).frame(height: 1), alignment: .bottom)
    }

    private var compactBody: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(L10n.Analysis.Measure.hr)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(measurements.merge.hr.isEmpty ? "—" : measurements.merge.hr)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)
                                .monospacedDigit()
                            Text(L10n.Analysis.Measure.unitBpm)
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppMetrics.spacing10)
                    .padding(.vertical, AppMetrics.spacing6)

                    stripSeparator()

                    HStack(spacing: AppMetrics.spacing12) {
                        measureItem(L10n.Analysis.Measure.pr,   measurements.merge.pr,      L10n.Analysis.Measure.unitMs)
                        measureItem(L10n.Analysis.Measure.qrs,  measurements.merge.qrs,     L10n.Analysis.Measure.unitMs)
                        measureItem(L10n.Analysis.Measure.qt,   measurements.merge.qt,      L10n.Analysis.Measure.unitMs)
                        measureItem(L10n.Analysis.Measure.qtc,  measurements.merge.qTc,     L10n.Analysis.Measure.unitMs)
                        measureItem("P°",                        measurements.merge.paxis,   L10n.Analysis.Measure.unitDeg)
                        measureItem("QRS°",                      measurements.merge.qrSaxis, L10n.Analysis.Measure.unitDeg)
                        measureItem("T°",                        measurements.merge.taxis,   L10n.Analysis.Measure.unitDeg)
                    }
                    .padding(.horizontal, AppMetrics.spacing10)
                }
            }

            Divider()

            HStack(spacing: AppMetrics.spacing8) {
                Text(diagnosisLines.isEmpty ? "—" : diagnosisLines.joined(separator: " · "))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isEmergency {
                    Text(L10n.PatientExams.rapidEkg)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.statusCritical)
                        .padding(.horizontal, AppMetrics.spacing6)
                        .padding(.vertical, 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(AppColors.statusCritical, lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, AppMetrics.spacing10)
            .padding(.vertical, AppMetrics.spacing6)
        }
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.6)).frame(height: 1), alignment: .bottom)
    }

    private func measureItem(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .center, spacing: 1) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 8))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func stripSeparator() -> some View {
        Rectangle()
            .fill(AppColors.borderSubtle)
            .frame(width: 1, height: 36)
    }
}

// MARK: - Lead Params Table Overlay

private struct LeadParamsTableOverlay: View {

    let leadNames: [String]
    let leadParams: [vhLeadParameter]

    private let colW: CGFloat   = 72
    private let labelW: CGFloat = 90
    private let rowH: CGFloat   = 36

    private typealias Row = (String, (vhLeadParameter) -> String)
    private var rows: [Row] {[
        (L10n.Analysis.LeadParam.morpho, { $0.morpho ?? "—" }),
        (L10n.Analysis.LeadParam.pa,     { String(format: "%.2f", $0.pa1) }),
        (L10n.Analysis.LeadParam.pd,     { "\($0.pd)" }),
        (L10n.Analysis.LeadParam.qa,     { String(format: "%.2f", $0.qa) }),
        (L10n.Analysis.LeadParam.qd,     { "\($0.qd)" }),
        (L10n.Analysis.LeadParam.ra,     { String(format: "%.2f", $0.ra1) }),
        (L10n.Analysis.LeadParam.rd,     { "\($0.rd1)" }),
        (L10n.Analysis.LeadParam.sa,     { String(format: "%.2f", $0.sa1) }),
        (L10n.Analysis.LeadParam.sd,     { "\($0.sd1)" }),
        (L10n.Analysis.LeadParam.td,     { "\($0.td)" }),
        (L10n.Analysis.LeadParam.qrsD,   { "\($0.qrs)" }),
        (L10n.Analysis.LeadParam.pr,     { "\($0.pr)" }),
        (L10n.Analysis.LeadParam.qt,     { "\($0.qt)" }),
        (L10n.Analysis.LeadParam.stj,    { String(format: "%.2f", $0.sTj) }),
    ]}

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    tableCell("", width: labelW, isHeader: true)
                    ForEach(leadNames, id: \.self) { tableCell($0, width: colW, isHeader: true) }
                }
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        labelCell(row.0)
                        ForEach(Array(leadParams.enumerated()), id: \.offset) { _, p in
                            dataCell(row.1(p))
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppColors.surfaceCard)
    }

    private func tableCell(_ text: String, width: CGFloat, isHeader: Bool) -> some View {
        Text(text)
            .font(.system(size: 13, weight: isHeader ? .bold : .regular))
            .foregroundStyle(isHeader ? AppColors.brandPrimary : AppColors.textPrimary)
            .frame(width: width, height: rowH)
            .background(isHeader ? AppColors.brandPrimary.opacity(0.08) : AppColors.surfaceCard)
            .overlay(Rectangle().stroke(AppColors.borderSubtle.opacity(0.5), lineWidth: 0.5))
    }

    private func labelCell(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, AppMetrics.spacing4)
            .frame(width: labelW, height: rowH, alignment: .leading)
            .background(AppColors.surfaceCard)
            .overlay(Rectangle().stroke(AppColors.borderSubtle.opacity(0.5), lineWidth: 0.5))
    }

    private func dataCell(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(AppColors.textPrimary)
            .monospacedDigit()
            .frame(width: colW, height: rowH)
            .background(AppColors.surfaceCard)
            .overlay(Rectangle().stroke(AppColors.borderSubtle.opacity(0.5), lineWidth: 0.5))
    }
}

// MARK: - Navigation Bar

private struct AnalysisNavBar: View {

    @Bindable var viewModel: AnalysisViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        Group {
            if isCompact { compactBody } else { regularBody }
        }
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle).frame(height: 1), alignment: .bottom)
    }

    private var regularBody: some View {
        HStack(alignment: .center, spacing: 0) {
            backButton
            patientInfo
            Spacer()
            titleBlock
            Spacer()
            LiveClockView()

            if viewModel.state == .success && !viewModel.patientExams.isEmpty {
                Button { viewModel.showExamHistory.toggle() } label: {
                    HStack(spacing: AppMetrics.spacing6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 23, weight: .semibold))
                        if viewModel.patientExams.count > 1 {
                            Text("\(viewModel.patientExams.count)")
                                .font(AppTypography.captionBold)
                        }
                    }
                    .foregroundStyle(AppColors.ecgBackground)
                    .padding(.horizontal, AppMetrics.spacing12)
                    .padding(.vertical, AppMetrics.spacing6)
                    .background(AppColors.accentTeal)
                    .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)
                .padding(.leading, AppMetrics.spacing8)
            }

            controlsMenu
                .padding(.leading, AppMetrics.spacing8)
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .frame(height: AppMetrics.navBarHeight)
    }

    @ViewBuilder private var compactHistoryButton: some View {
        if viewModel.state == .success && !viewModel.patientExams.isEmpty {
            Button { viewModel.showExamHistory.toggle() } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.ecgBackground)
                        .frame(width: 34, height: 34)
                        .background(AppColors.accentTeal)
                        .cornerRadius(AppMetrics.radiusMedium)
                    if viewModel.patientExams.count > 1 {
                        Text("\(viewModel.patientExams.count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.hapticPlain)
        }
    }

    private var compactBody: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing8) {
            Button { viewModel.goBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(AppColors.borderSubtle.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(.hapticPlain)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.patient.fullName)
                    .font(AppTypography.phoneBodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Text(L10n.Analysis.Nav.unconfirmed)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppColors.statusWarning)
            }

            Spacer()

            compactHistoryButton
            controlsMenu
        }
        .padding(.horizontal, AppMetrics.spacing16)
        .frame(height: 52)
    }

    private var backButton: some View {
        Button { viewModel.goBack() } label: {
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
        .buttonStyle(.hapticPlain)
    }

    private var patientInfo: some View {
        HStack(spacing: AppMetrics.spacing10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.patient.fullName)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: AppMetrics.spacing4) {
                    Text(viewModel.patient.age)
                    Text("·")
                    Text(viewModel.patient.genderDisplay)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.leading, AppMetrics.spacing8)
    }

    private var titleBlock: some View {
        VStack(spacing: 3) {
            Text(L10n.Analysis.Nav.title)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
            Text(L10n.Analysis.Nav.unconfirmed)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.statusWarning)
                .padding(.horizontal, AppMetrics.spacing6)
                .padding(.vertical, 2)
                .background(AppColors.statusWarning.opacity(0.1))
                .cornerRadius(AppMetrics.radiusSmall)
        }
    }

    private var controlsMenu: some View {
        Menu {
            Button {
                viewModel.uploadEKG()
            } label: {
                Label(
                    viewModel.isAlreadySynced ? L10n.Analysis.Nav.alreadySent : L10n.Analysis.Nav.sendToEmr,
                    systemImage: viewModel.isAlreadySynced ? "checkmark.circle" : "arrow.up.circle"
                )
            }
            .disabled(viewModel.isLocalMode || viewModel.isAlreadySynced)

            Button {
                viewModel.showDiagnosisPanel = true
            } label: {
                Label(L10n.Analysis.Nav.diagnosis, systemImage: "stethoscope")
            }
            .disabled(viewModel.isLocalMode || viewModel.isAlreadySynced)

            if viewModel.visualizationMode != .standard {
                Button { viewModel.visualizationMode = .standard } label: {
                    Label(L10n.Analysis.Viz.standard, systemImage: "arrow.left.arrow.right")
                }
                Button { viewModel.visualizationMode = .layers } label: {
                    Label(L10n.Analysis.Viz.layers, systemImage: viewModel.visualizationMode == .layers ? "checkmark" : "square.3.layers.3d")
                }
                Button { viewModel.visualizationMode = .table } label: {
                    Label(L10n.Analysis.Viz.table, systemImage: viewModel.visualizationMode == .table ? "checkmark" : "chart.bar.doc.horizontal")
                }
            } else {
                Menu {
                    Button { viewModel.visualizationMode = .standard } label: {
                        Label(L10n.Analysis.Viz.standard, systemImage: "checkmark")
                    }
                    Button { viewModel.visualizationMode = .layers } label: {
                        Label(L10n.Analysis.Viz.layers, systemImage: "square.3.layers.3d")
                    }
                    Button { viewModel.visualizationMode = .table } label: {
                        Label(L10n.Analysis.Viz.table, systemImage: "chart.bar.doc.horizontal")
                    }
                } label: {
                    Label(L10n.Analysis.Viz.visualization, systemImage: "eye")
                }
            }

            Button {
                printECG(
                    patient: viewModel.patient,
                    templateData: viewModel.templateData,
                    ecgData: viewModel.ecgData,
                    sampleRate: viewModel.sampleRate,
                    measurements: viewModel.measurements,
                    diagnosisLines: viewModel.diagnosisLines,
                    performedBy: viewModel.performedBy,
                    isEmergency: viewModel.showEmergencyBanner
                )
            } label: {
                Label(L10n.Analysis.Nav.print, systemImage: "printer")
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: isCompact ? 15 : 25, weight: .semibold))
                .foregroundStyle(AppColors.ecgBackground)
                .frame(width: isCompact ? 34 : nil, height: isCompact ? 34 : nil)
                .padding(.horizontal, isCompact ? 0 : AppMetrics.spacing12)
                .padding(.vertical, isCompact ? 0 : AppMetrics.spacing6)
                .background(AppColors.accentTeal)
                .cornerRadius(AppMetrics.radiusMedium)
        }
    }
}

// MARK: - Upload Status Overlay

private struct UploadStatusOverlay: View {

    @Bindable var viewModel: AnalysisViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing20) {
                if viewModel.isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                        .scaleEffect(1.6)
                    Text(L10n.Analysis.Upload.sending)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                } else if viewModel.uploadSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: isCompact ? 44 : 56, weight: .light))
                        .foregroundStyle(AppColors.statusSuccess)
                    Text(L10n.Analysis.Upload.successTitle)
                        .font(isCompact ? AppTypography.phoneTitle : AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.Analysis.Upload.successSubtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    successActions
                } else if let error = viewModel.uploadError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: isCompact ? 44 : 56, weight: .light))
                        .foregroundStyle(AppColors.statusCritical)
                    Text(L10n.Analysis.Upload.errorTitle)
                        .font(isCompact ? AppTypography.phoneTitle : AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(error)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppMetrics.spacing24)
                    errorActions
                }
            }
            .padding(AppMetrics.spacing32)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .shadow(color: .black.opacity(0.2), radius: 24)
            .padding(.horizontal, isCompact ? AppMetrics.spacing20 : AppMetrics.spacing48)
        }
    }

    @ViewBuilder private var successActions: some View {
        if isCompact {
            VStack(spacing: AppMetrics.spacing12) {
                Button(L10n.Analysis.Upload.doneButton) {
                    viewModel.showUploadResult = false; viewModel.goBack()
                }
                .font(AppTypography.phoneBodyMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppMetrics.buttonHeight)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)

                Button(L10n.Analysis.Upload.stayButton) { viewModel.showUploadResult = false }
                    .font(AppTypography.phoneBodyMedium)
                    .foregroundStyle(AppColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.brandPrimary.opacity(0.1))
                    .cornerRadius(AppMetrics.radiusMedium)
            }
        } else {
            HStack(spacing: AppMetrics.spacing12) {
                Button(L10n.Analysis.Upload.doneButton) {
                    viewModel.showUploadResult = false; viewModel.goBack()
                }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, AppMetrics.spacing32)
                .frame(height: AppMetrics.buttonHeight)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)

                Button(L10n.Analysis.Upload.stayButton) { viewModel.showUploadResult = false }
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.brandPrimary)
                    .padding(.horizontal, AppMetrics.spacing32)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.brandPrimary.opacity(0.1))
                    .cornerRadius(AppMetrics.radiusMedium)
            }
        }
    }

    @ViewBuilder private var errorActions: some View {
        if isCompact {
            VStack(spacing: AppMetrics.spacing12) {
                Button(L10n.Common.retry) {
                    viewModel.showUploadResult = false; viewModel.uploadEKG()
                }
                .font(AppTypography.phoneBodyMedium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppMetrics.buttonHeight)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)

                Button(L10n.Common.cancel) { viewModel.showUploadResult = false }
                    .font(AppTypography.phoneBodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.borderSubtle.opacity(0.4))
                    .cornerRadius(AppMetrics.radiusMedium)
            }
        } else {
            HStack(spacing: AppMetrics.spacing12) {
                Button(L10n.Common.retry) {
                    viewModel.showUploadResult = false; viewModel.uploadEKG()
                }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, AppMetrics.spacing32)
                .frame(height: AppMetrics.buttonHeight)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)

                Button(L10n.Common.cancel) { viewModel.showUploadResult = false }
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, AppMetrics.spacing32)
                    .frame(height: AppMetrics.buttonHeight)
                    .background(AppColors.borderSubtle.opacity(0.4))
                    .cornerRadius(AppMetrics.radiusMedium)
            }
        }
    }
}

// MARK: - Emergency PIN Overlay

private struct EmergencyPinOverlay: View {

    @Bindable var viewModel: AnalysisViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                        Text(L10n.Emergency.pinTitle)
                            .font(isCompact ? AppTypography.phoneTitle : AppTypography.title2)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(L10n.Emergency.pinSubtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Button {
                        viewModel.showEmergencyPinSheet = false
                        viewModel.emergencyPinInput = ""
                        viewModel.emergencyPinError = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.hapticPlain)
                }
                .padding(.bottom, AppMetrics.spacing24)

                HStack(spacing: AppMetrics.spacing20) {
                    ForEach(0..<6, id: \.self) { idx in
                        ZStack {
                            Circle()
                                .stroke(
                                    idx < viewModel.emergencyPinInput.count
                                        ? AppColors.brandPrimary : AppColors.borderSubtle,
                                    lineWidth: 2
                                )
                                .frame(width: 20, height: 20)
                            if idx < viewModel.emergencyPinInput.count {
                                Circle()
                                    .fill(AppColors.brandPrimary)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .animation(.easeInOut(duration: 0.15), value: viewModel.emergencyPinInput.count)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, AppMetrics.spacing8)

                Group {
                    if let err = viewModel.emergencyPinError {
                        Text(err)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.statusCritical)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 18)
                .padding(.bottom, AppMetrics.spacing16)

                PinNumericKeypad(
                    onDigit:  { viewModel.emergencyKeypadInput($0) },
                    onDelete: { viewModel.emergencyKeypadDelete() }
                )
            }
            .padding(AppMetrics.spacing28)
            .frame(maxWidth: 420)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .shadow(color: .black.opacity(0.25), radius: 28)
            .padding(.horizontal, isCompact ? AppMetrics.spacing16 : 0)
        }
    }
}

// MARK: - Emergency Assign Patient Sheet

private struct EmergencyAssignPatientSheet: View {

    @Bindable var viewModel: AnalysisViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(L10n.Emergency.assignSubtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppMetrics.spacing24)
                    .padding(.vertical, AppMetrics.spacing16)

                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.textSecondary)
                    TextField(L10n.Emergency.assignSearch, text: $viewModel.assignSearchQuery)
                        .font(AppTypography.body)
                        .autocorrectionDisabled()
                }
                .padding(AppMetrics.spacing12)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                )
                .padding(.horizontal, AppMetrics.spacing16)
                .padding(.bottom, AppMetrics.spacing8)

                Divider()

                if viewModel.isLoadingAssignPatients {
                    Spacer()
                    ProgressView().tint(AppColors.brandPrimary)
                    Spacer()
                } else if viewModel.filteredAssignPatients.isEmpty {
                    Spacer()
                    Text(L10n.Emergency.assignNoPatients)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredAssignPatients) { patient in
                            Button {
                                viewModel.confirmPatientAssignment(patient)
                            } label: {
                                HStack(spacing: AppMetrics.spacing12) {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.brandPrimary.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Text(patient.initials)
                                            .font(AppTypography.bodyMedium)
                                            .foregroundStyle(AppColors.brandPrimary)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(patient.fullName)
                                            .font(AppTypography.bodyMedium)
                                            .foregroundStyle(AppColors.textPrimary)
                                        HStack(spacing: AppMetrics.spacing6) {
                                            if !patient.mrn.isEmpty {
                                                Text(L10n.PatientExams.mrnLabel(patient.mrn))
                                            }
                                            Text("·")
                                            Text(patient.age)
                                            Text("·")
                                            Text(patient.genderDisplay)
                                        }
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppColors.borderSubtle)
                                }
                                .padding(.vertical, AppMetrics.spacing4)
                            }
                            .buttonStyle(.hapticPlain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(L10n.Emergency.assignTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        viewModel.showAssignPatientSheet = false
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(L10n.Emergency.createNew) {
                        viewModel.ecFirstName = ""
                        viewModel.ecLastName  = ""
                        viewModel.ecDob       = nil
                        viewModel.ecGender    = "Male"
                        viewModel.ecMRN       = ""
                        viewModel.emergencyCreateError = nil
                        viewModel.showEmergencyCreatePatient = true
                    }
                    .foregroundStyle(AppColors.brandPrimary)
                }
            }
        }
        .onAppear { viewModel.loadPatientsForAssignment() }
        .sheet(isPresented: $viewModel.showEmergencyCreatePatient) {
            EmergencyCreatePatientSheet(viewModel: viewModel)
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Emergency Create Patient Sheet

private struct EmergencyCreatePatientSheet: View {

    @Bindable var viewModel: AnalysisViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.PatientSelection.Create.title) {
                    TextField(L10n.PatientSelection.Create.firstName, text: $viewModel.ecFirstName)
                    TextField(L10n.PatientSelection.Create.lastName,  text: $viewModel.ecLastName)
                }

                Section {
                    DatePicker(
                        L10n.PatientSelection.Create.dob,
                        selection: Binding(
                            get: { viewModel.ecDob ?? Date() },
                            set: { viewModel.ecDob = $0 }
                        ),
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    Picker(L10n.PatientSelection.Create.gender, selection: $viewModel.ecGender) {
                        ForEach(["Male", "Female"], id: \.self) { Text($0).tag($0) }
                    }

                    TextField(L10n.PatientSelection.Create.mrn, text: $viewModel.ecMRN)
                        .keyboardType(.numberPad)
                }

                if let err = viewModel.emergencyCreateError {
                    Section {
                        Text(err)
                            .foregroundStyle(AppColors.statusCritical)
                            .font(AppTypography.caption)
                    }
                }
            }
            .navigationTitle(L10n.Emergency.createTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { viewModel.cancelEmergencyCreate() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isEmergencyCreating {
                        ProgressView().tint(AppColors.brandPrimary)
                    } else {
                        Button(L10n.Common.ok) { viewModel.submitEmergencyCreatePatient() }
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
