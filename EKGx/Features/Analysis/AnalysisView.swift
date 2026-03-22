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

    init(viewModel: AnalysisViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                AnalysisNavBar(viewModel: viewModel)

                switch viewModel.state {
                case .analyzing: analyzingBody
                case .success:   successBody
                case .failed:    failedBody
                }
            }

            // Overlays
            if viewModel.showControlsMenu {
                AnalysisControlsMenu(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(10)
            }
            if viewModel.showVisualizationMenu {
                VisualizationMenuSheet(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(10)
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
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showControlsMenu)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showVisualizationMenu)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showRejectConfirm)
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .onAppear { viewModel.runAnalysis() }
    }

    // MARK: - Analyzing

    private var analyzingBody: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().scaleEffect(1.4).tint(AppColors.brandPrimary)
            Text(L10n.Common.loading).font(AppTypography.callout).foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Success

    private var successBody: some View {
        VStack(spacing: 0) {
            // Compact info strip
            if let m = viewModel.measurements {
                InfoStrip(measurements: m, diagnosisLines: viewModel.diagnosisLines)
            }
            Divider()

            // ECG area
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
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(AppColors.statusWarning)
            VStack(spacing: 8) {
                Text(L10n.Analysis.Failed.title).font(AppTypography.title2).foregroundStyle(.primary)
                Text(L10n.Analysis.Failed.subtitle)
                    .font(AppTypography.callout).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }
            Button(L10n.Analysis.Failed.redoButton) { viewModel.goBack() }
                .font(AppTypography.bodyMedium).foregroundStyle(.white)
                .padding(.horizontal, 32).padding(.vertical, 14)
                .background(AppColors.brandPrimary).cornerRadius(AppMetrics.radiusMedium)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Info Strip

private struct InfoStrip: View {

    let measurements: vhMeasurements
    let diagnosisLines: [String]

    var body: some View {
        HStack(alignment: .center, spacing: 0) {

            // HR
            VStack(alignment: .leading, spacing: 1) {
                Text("HR").font(.system(size: 9, weight: .medium)).foregroundColor(.gray)
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(measurements.merge.hr.isEmpty ? "—" : measurements.merge.hr)
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.black).monospacedDigit()
                    Text("bpm").font(.system(size: 9)).foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            separator()

            // Measurements row
            HStack(spacing: 14) {
                measureItem("PR",    measurements.merge.pr,     "ms")
                measureItem("QRS",   measurements.merge.qrs,    "ms")
                measureItem("QT",    measurements.merge.qt,     "ms")
                measureItem("QTc",   measurements.merge.qTc,    "ms")
                measureItem("P°",    measurements.merge.paxis,  "°")
                measureItem("QRS°",  measurements.merge.qrSaxis,"°")
                measureItem("T°",    measurements.merge.taxis,  "°")
            }
            .padding(.horizontal, 14)

            separator()

            // Diagnosis
            VStack(alignment: .leading, spacing: 2) {
                Text("INTERPRETATION")
                    .font(.system(size: 8, weight: .semibold)).foregroundColor(.gray).tracking(0.5)
                Text(diagnosisLines.isEmpty ? "—" : diagnosisLines.joined(separator: " · "))
                    .font(.system(size: 11)).foregroundColor(.black)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .overlay(Rectangle().fill(Color(UIColor.systemGray5)).frame(height: 1), alignment: .bottom)
    }

    private func measureItem(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .center, spacing: 1) {
            Text(label).font(.system(size: 8, weight: .medium)).foregroundColor(.gray)
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.black).monospacedDigit()
                Text(unit).font(.system(size: 8)).foregroundColor(.gray)
            }
        }
    }

    private func separator() -> some View {
        Rectangle()
            .fill(Color(UIColor.systemGray4))
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
    private let rows: [Row] = [
        ("Morpho",   { $0.morpho ?? "—" }),
        ("Pa (mV)",  { String(format: "%.2f", $0.pa1) }),
        ("Pd (ms)",  { "\($0.pd)" }),
        ("Qa (mV)",  { String(format: "%.2f", $0.qa) }),
        ("Qd (ms)",  { "\($0.qd)" }),
        ("Ra (mV)",  { String(format: "%.2f", $0.ra1) }),
        ("Rd (ms)",  { "\($0.rd1)" }),
        ("Sa (mV)",  { String(format: "%.2f", $0.sa1) }),
        ("Sd (ms)",  { "\($0.sd1)" }),
        ("Td (ms)",  { "\($0.td)" }),
        ("QRS (ms)", { "\($0.qrs)" }),
        ("PR (ms)",  { "\($0.pr)" }),
        ("QT (ms)",  { "\($0.qt)" }),
        ("STj (mV)", { String(format: "%.2f", $0.sTj) }),
    ]

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    cell("", w: labelW, isHeader: true)
                    ForEach(leadNames, id: \.self) { cell($0, w: colW, isHeader: true) }
                }
                // Rows
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    HStack(spacing: 0) {
                        labelCell(row.0, alt: idx.isMultiple(of: 2))
                        ForEach(Array(leadParams.enumerated()), id: \.offset) { _, p in
                            dataCell(row.1(p), alt: idx.isMultiple(of: 2))
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.white)
    }

    private func cell(_ text: String, w: CGFloat, isHeader: Bool) -> some View {
        Text(text)
            .font(.system(size: 13, weight: isHeader ? .bold : .regular))
            .foregroundStyle(isHeader ? AppColors.brandPrimary : Color.black)
            .frame(width: w, height: rowH)
            .background(isHeader ? AppColors.brandPrimary.opacity(0.08) : Color.white)
            .overlay(Rectangle().stroke(Color(UIColor.systemGray4), lineWidth: 0.5))
    }

    private func labelCell(_ text: String, alt: Bool) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Color(UIColor.darkGray))
            .padding(.horizontal, 4)
            .frame(width: labelW, height: rowH, alignment: .leading)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color(UIColor.systemGray4), lineWidth: 0.5))
    }

    private func dataCell(_ text: String, alt: Bool) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Color.black)
            .monospacedDigit()
            .frame(width: colW, height: rowH)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color(UIColor.systemGray4), lineWidth: 0.5))
    }
}

// MARK: - Navigation Bar

private struct AnalysisNavBar: View {

    @Bindable var viewModel: AnalysisViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            backButton
            Spacer()
            patientInfo
            Spacer()
            titleBlock
            Spacer()
            LiveClockView()

            // Controls toggle
            Button {
                viewModel.showControlsMenu.toggle()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.brandPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.brandPrimary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .frame(height: AppMetrics.navBarHeight)
        .background(Color.white)
        .overlay(Rectangle().fill(Color(UIColor.systemGray4)).frame(height: 1), alignment: .bottom)
    }

    private var backButton: some View {
        Button { viewModel.goBack() } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left").font(.system(size: 13, weight: .semibold))
                Text(L10n.Analysis.Nav.backButton).font(AppTypography.callout)
            }
            .foregroundStyle(AppColors.brandPrimary)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(AppColors.brandPrimary.opacity(0.1))
            .cornerRadius(AppMetrics.radiusMedium)
        }
        .buttonStyle(.plain)
    }

    private var patientInfo: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(AppColors.brandPrimary.opacity(0.12)).frame(width: 34, height: 34)
                Text(viewModel.patient.initials).font(AppTypography.captionBold).foregroundStyle(AppColors.brandPrimary)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.patient.fullName).font(AppTypography.bodyMedium).foregroundStyle(.black)
                HStack(spacing: 4) {
                    Text(viewModel.patient.age)
                    Text("·")
                    Text(viewModel.patient.genderDisplay)
                }
                .font(AppTypography.caption).foregroundStyle(.gray)
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 3) {
            Text(L10n.Analysis.Nav.title).font(AppTypography.bodyMedium).foregroundStyle(.black)
            Text(L10n.Analysis.Nav.unconfirmed)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.statusWarning)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(AppColors.statusWarning.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

// MARK: - Preview

#Preview {
    let router = AppRouter()
    let patient = Patient.mockPatients[0]
    let ecgData: ECGLeads = {
        guard let path = Bundle.main.path(forResource: "ecg_demo", ofType: "plist"),
              let raw = NSArray(contentsOfFile: path) as? [[NSNumber]] else { return [] }
        return raw
    }()
    return AnalysisView(viewModel: AnalysisViewModel(
        patient: patient, ecgData: ecgData, sampleRate: 660, router: router
    ))

    .environment(router)
}
