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
            if viewModel.isUploading || viewModel.showUploadResult {
                UploadStatusOverlay(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(20)
            }
            // Emergency PIN gate — shown above everything when unauthenticated user taps upload
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
                    .font(.system(size: 9, weight: .semibold)).foregroundColor(.gray).tracking(0.5)
                Text(diagnosisLines.isEmpty ? "—" : diagnosisLines.joined(separator: " · "))
                    .font(.system(size: 12)).foregroundColor(.black)
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
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.gray)
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.black).monospacedDigit()
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
            VStack(spacing: 4) {
                LiveClockView()
                if viewModel.showEmergencyBanner {
                    EmergencyChip(
                        assignedPatient: viewModel.assignedPatient,
                        isPinVerified: viewModel.isPinVerified
                    )
                }
            }

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
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.statusWarning)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(AppColors.statusWarning.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

// MARK: - Upload Status Overlay

private struct UploadStatusOverlay: View {

    @Bindable var viewModel: AnalysisViewModel

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
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(AppColors.statusSuccess)
                    Text(L10n.Analysis.Upload.successTitle)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.Analysis.Upload.successSubtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: AppMetrics.spacing12) {
                        Button(L10n.Analysis.Upload.doneButton) {
                            viewModel.showUploadResult = false
                            viewModel.goBack()
                        }
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppMetrics.spacing32)
                        .frame(height: AppMetrics.buttonHeight)
                        .background(AppColors.brandPrimary)
                        .cornerRadius(AppMetrics.radiusMedium)

                        Button(L10n.Analysis.Upload.stayButton) {
                            viewModel.showUploadResult = false
                        }
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.brandPrimary)
                        .padding(.horizontal, AppMetrics.spacing32)
                        .frame(height: AppMetrics.buttonHeight)
                        .background(AppColors.brandPrimary.opacity(0.1))
                        .cornerRadius(AppMetrics.radiusMedium)
                    }
                } else if let error = viewModel.uploadError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(AppColors.statusCritical)
                    Text(L10n.Analysis.Upload.errorTitle)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(error)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppMetrics.spacing24)
                    HStack(spacing: AppMetrics.spacing12) {
                        Button(L10n.Common.retry) {
                            viewModel.showUploadResult = false
                            viewModel.uploadEKG()
                        }
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppMetrics.spacing32)
                        .frame(height: AppMetrics.buttonHeight)
                        .background(AppColors.brandPrimary)
                        .cornerRadius(AppMetrics.radiusMedium)

                        Button(L10n.Common.cancel) {
                            viewModel.showUploadResult = false
                        }
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, AppMetrics.spacing32)
                        .frame(height: AppMetrics.buttonHeight)
                        .background(AppColors.borderSubtle.opacity(0.4))
                        .cornerRadius(AppMetrics.radiusMedium)
                    }
                }
            }
            .padding(AppMetrics.spacing32)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .shadow(color: .black.opacity(0.2), radius: 24)
            .padding(.horizontal, AppMetrics.spacing48)
        }
    }
}

// MARK: - Emergency Chip (compact, sits inside the nav bar below the clock)

private struct EmergencyChip: View {
    let assignedPatient: Patient?
    let isPinVerified: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: assignedPatient != nil ? "checkmark.circle.fill" : "cross.case.fill")
                .font(.system(size: 9, weight: .semibold))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(assignedPatient != nil ? AppColors.statusSuccess : AppColors.statusCritical)
        .cornerRadius(20)
    }

    private var label: String {
        if let p = assignedPatient { return p.firstName + " " + p.lastName }
        return "Emergency"
    }
}

// MARK: - Emergency PIN Overlay

private struct EmergencyPinOverlay: View {

    @Bindable var viewModel: AnalysisViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                        Text(L10n.Emergency.pinTitle)
                            .font(AppTypography.title2)
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
                    .buttonStyle(.plain)
                }
                .padding(.bottom, AppMetrics.spacing24)

                // PIN dots
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

                // Error line
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
            .frame(width: 420)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .shadow(color: .black.opacity(0.25), radius: 28)
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

                // Search bar
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
                                        HStack(spacing: 6) {
                                            if !patient.mrn.isEmpty {
                                                Text("MRN: \(patient.mrn)")
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
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
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

// MARK: - Preview

//#Preview {
//    let router = AppRouter()
//    let patient = Patient.mockPatients[0]
//    let ecgData: ECGLeads = {
//        guard let path = Bundle.main.path(forResource: "ecg_demo", ofType: "plist"),
//              let raw = NSArray(contentsOfFile: path) as? [[NSNumber]] else { return [] }
//        return raw
//    }()
//    let checkin = AppCheckinService()
//    return AnalysisView(viewModel: AnalysisViewModel(
//        patient: patient,
//        ecgData: ecgData,
//        sampleRate: 660,
//        router: router,
//        uploadService: EKGUploadService(),
//        checkinService: checkin
//    ))
//
//    .environment(router)
//}
