import SwiftUI

// MARK: - BP Arm & Position (defined here so VitalCard can reference them without cross-file scope issues)

enum BPArm: String, Codable, CaseIterable, Hashable {
    case right, left
    var label: String { self == .right ? L10n.Vitals.BP.armRight : L10n.Vitals.BP.armLeft }
    var fullLabel: String { self == .right ? L10n.Vitals.BP.armRightFull : L10n.Vitals.BP.armLeftFull }
}

enum BPPosition: String, Codable, CaseIterable, Hashable {
    case sitting, standing, lying
    var label: String {
        switch self {
        case .sitting:  return L10n.Vitals.BP.positionSitting
        case .standing: return L10n.Vitals.BP.positionStanding
        case .lying:    return L10n.Vitals.BP.positionLying
        }
    }
    var shortLabel: String {
        switch self {
        case .sitting:  return L10n.Vitals.BP.positionSit
        case .standing: return L10n.Vitals.BP.positionStand
        case .lying:    return L10n.Vitals.BP.positionLie
        }
    }
    var icon: String {
        switch self {
        case .sitting:  return "figure.seated.side"
        case .standing: return "figure.stand"
        case .lying:    return "bed.double.fill"
        }
    }
}

// MARK: - BP History Item (display model — keeps VitalCard free of cross-file type deps)

struct BPHistoryItem: Identifiable {
    let id: String
    let displayValue: String
    let riskColor: Color
    let riskLabel: String
    let pulseRate: Int?
    let formattedDate: String
    let formattedTime: String
    let armLabel: String?
    let positionLabel: String?
}

// MARK: - VitalsView

struct VitalsView: View {

    @State var viewModel: VitalsViewModel
    @State private var pendingRR: Int? = nil
    @State private var savedRR: Int? = nil

    var body: some View {
        @Bindable var vm = viewModel
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                patientCard
                content
            }
        }
//        .sheet(isPresented: $vm.showConnectSheet) {
//            if let vital = viewModel.selectedVital {
//                DeviceConnectSheet(vital: vital, viewModel: viewModel)
//            }
//        }
        .sheet(isPresented: $vm.showManualBPEntry) {
            ManualBPSheet(arm: viewModel.bpArm, position: viewModel.bpPosition) { sys, dia, pr in
                viewModel.saveManualBP(systolic: sys, diastolic: dia, pulseRate: pr)
            }
            .presentationBackground(AppColors.surfaceBackground)
            .presentationDetents([.large])
        }
        .sheet(isPresented: $vm.showManualSpO2Entry) {
            ManualSpO2Sheet { spo2, pr in
                viewModel.saveManualSpO2(value: spo2, pulseRate: pr)
            }
            .presentationBackground(AppColors.surfaceBackground)
            .presentationDetents([.large])
        }
        .sheet(isPresented: $vm.showManualTempEntry) {
            ManualTempSheet { value, unit in
                viewModel.saveManualTemp(value: value, unit: unit)
            }
            .presentationBackground(AppColors.surfaceBackground)
            .presentationDetents([.large])
        }
        .sheet(isPresented: $vm.showManualPREntry) {
            ManualPRSheet { bpm in
                viewModel.saveManualPR(bpm: bpm)
            }
            .presentationBackground(AppColors.surfaceBackground)
            .presentationDetents([.large])
        }
        .onAppear {
            viewModel.activate()
            let saved = viewModel.measurements[.respirations].flatMap { Int($0.displayValue) }
            savedRR   = saved
            pendingRR = saved
        }
        .onDisappear { viewModel.deactivate() }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        ZStack {
            Text(viewModel.facilityName)
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button(action: viewModel.navigateBack) {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text(L10n.Common.back)
                            .font(AppTypography.callout)
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppMetrics.spacing16)
                    .padding(.vertical, AppMetrics.spacing8)
                    .background(AppColors.borderSubtle.opacity(0.5))
                    .cornerRadius(AppMetrics.radiusMedium)
                }

                Spacer()

                Button(action: viewModel.openExams) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 54, height: 54)
                            .background(AppColors.borderSubtle.opacity(0.5))
                            .cornerRadius(AppMetrics.radiusMedium)

                        if viewModel.examCount > 0 {
                            Text("\(viewModel.examCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(AppColors.brandPrimary)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .buttonStyle(.hapticPlain)
            }
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Patient Card

    private var patientCard: some View {
        @Bindable var vm = viewModel
        return HStack(spacing: AppMetrics.spacing16) {
            ZStack {
                Circle()
                    .fill(AppColors.surfaceBackground)
                    .frame(width: 56, height: 56)
                Text(viewModel.patient.initials)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                Text(viewModel.patient.fullName)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: AppMetrics.spacing16) {
                    if !viewModel.patient.birthDate.isEmpty {
                        Label("\(viewModel.patient.birthDate) · \(viewModel.patient.age)", systemImage: "calendar")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if !viewModel.patient.gender.isEmpty {
                        Label(viewModel.patient.genderDisplay, systemImage: viewModel.patient.genderIcon)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    if let mrn = viewModel.patient.medicalRecordNumber, !mrn.isEmpty {
                        Label(L10n.Vitals.mrnLabel(mrn), systemImage: "number")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                patientMetricPill(
                    icon: VitalType.height.icon,
                    value: viewModel.heightDisplay,
                    placeholder: L10n.Vitals.Height.title,
                    color: VitalType.height.iconColor,
                    action: viewModel.openHeight
                )
                .popover(isPresented: $vm.showHeightPicker, arrowEdge: .top) {
                    HeightSheet(currentCm: viewModel.heightCm) { cm, display in
                        viewModel.saveHeight(cm, display: display)
                    }
                    .frame(width: 380)
                    .presentationBackground(AppColors.surfaceBackground)
                }

                patientMetricPill(
                    icon: VitalType.weight.icon,
                    value: viewModel.weightDisplay,
                    placeholder: L10n.Vitals.Weight.title,
                    color: VitalType.weight.iconColor,
                    action: viewModel.openWeightScanSheet
                )
                .popover(isPresented: $vm.showWeightPopover, arrowEdge: .top) {
                    WeightScanSheet(viewModel: viewModel)
                        .frame(width: 400)
                        .presentationBackground(AppColors.surfaceBackground)
                }
            }
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .padding(.vertical, AppMetrics.spacing12)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)
    }

    private func patientMetricPill(
        icon: String,
        value: String?,
        placeholder: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(color)
                Text(value ?? placeholder)
                    .font(.system(size: 20, weight: value != nil ? .semibold : .regular))
                    .foregroundStyle(value != nil ? AppColors.textPrimary : AppColors.textSecondary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: value)
            }
            .padding(.horizontal, 19)
            .padding(.vertical, 12)
            .background(AppColors.surfaceBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.hapticPlain)
    }

    // MARK: - Content

    private var content: some View {
        @Bindable var vm = viewModel
        let wideVitals = VitalType.allCases.filter(\.isWideCard)
        let gridVitals = VitalType.allCases.filter {
            !$0.isWideCard && $0 != .height && $0 != .weight && $0 != .bloodSugar && $0 != .bloodPressure
        }
        let gridRows = stride(from: 0, to: gridVitals.count, by: 3)
                        .map { Array(gridVitals[$0 ..< min($0 + 3, gridVitals.count)]) }

        return VStack(spacing: AppMetrics.spacing4) {
            // Wide row (EKG + Echo)
            HStack(spacing: AppMetrics.spacing4) {
                ForEach(wideVitals) { type in
                    VitalCard(
                        type: type,
                        state: viewModel.connectionState(for: type),
                        source: cardSource(for: type),
                        onTap: { handleTap(type) },
                        onConnectTap: { viewModel.startConnect(for: type) },
                        onLongPress: type.requiresDevice ? { viewModel.startConnect(for: type) } : nil
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Full-width BP row
            VitalCard(
                type: .bloodPressure,
                state: viewModel.connectionState(for: .bloodPressure),
                selectedValue: cardValue(for: .bloodPressure),
                source: cardSource(for: .bloodPressure),
                onTap: { handleTap(.bloodPressure) },
                onConnectTap: { viewModel.startConnect(for: .bloodPressure) },
                onLongPress: { viewModel.startConnect(for: .bloodPressure) },
                onSave: { viewModel.saveBPReading() },
                bpSaveState: viewModel.bpSaveState,
                bpHasReading: viewModel.hasCompleteBPReading,
                bpSensorError: viewModel.bpSensorError,
                bpHistory: viewModel.bpHistory,
                bpArm: viewModel.bpArm,
                bpPosition: viewModel.bpPosition,
                onArmChange: { viewModel.bpArm = $0 },
                onPositionChange: { viewModel.bpPosition = $0 },
                bpPulseRate: viewModel.measurements[.bloodPressure]?.pulseRate,
                onManualEntry: { viewModel.openManualEntry(for: .bloodPressure) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Grid rows
            ForEach(Array(gridRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: AppMetrics.spacing4) {
                    ForEach(row) { type in
                        VitalCard(
                            type: type,
                            state: viewModel.connectionState(for: type),
                            selectedPainLevel: type == .painLevel ? viewModel.painLevel : nil,
                            selectedValue: cardValue(for: type),
                            source: cardSource(for: type),
                            onTap: { handleTap(type) },
                            onConnectTap: { viewModel.startConnect(for: type) },
                            onSelectPainLevel: type == .painLevel ? { level in viewModel.savePainLevel(level) } : nil,
                            onLongPress: type.requiresDevice ? { viewModel.startConnect(for: type) } : nil,
                            bodyFatPercent: type == .weight ? viewModel.measurements[.weight]?.bodyFatPercent : nil,
                            onSaveSpO2:    type == .oxygenSaturation ? { viewModel.saveSpO2Reading() } : nil,
                            spo2SaveState: viewModel.spo2SaveState,
                            spo2HasReading: type == .oxygenSaturation && viewModel.hasCompleteSpO2Reading,
                            onSaveTemp:    type == .temperature ? { viewModel.saveTempReading() } : nil,
                            tempSaveState: viewModel.tempSaveState,
                            tempHasReading: type == .temperature && viewModel.hasCompleteTempReading,
                            onManualEntry: [.oxygenSaturation, .temperature, .heartRate].contains(type)
                                ? { viewModel.openManualEntry(for: type) } : nil
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay {
                            if type == .respirations {
                                Menu {
                                    Picker(
                                        L10n.Vitals.rrPickerTitle,
                                        selection: Binding(
                                            get: { pendingRR ?? viewModel.measurements[.respirations].flatMap { Int($0.displayValue) } ?? 16 },
                                            set: { pendingRR = $0 }
                                        )
                                    ) {
                                        ForEach(4...60, id: \.self) { v in
                                            Text(L10n.Vitals.rrBpm(v)).tag(v)
                                        }
                                    }
                                } label: {
                                    Color.clear.contentShape(Rectangle())
                                }
                            }
                        }
                        .overlay {
                            if type == .respirations, let pending = pendingRR {
                                let isSaved = pending == savedRR
                                let bgColor = isSaved ? AppColors.statusSuccess : AppColors.brandPrimary
                                Button {
                                    viewModel.saveRR(pending)
                                    savedRR = pending
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: isSaved
                                              ? "checkmark.circle.fill"
                                              : "arrow.down.circle.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text(isSaved ? L10n.Vitals.rrSaved : L10n.Vitals.rrSave)
                                            .font(.system(size: 15, weight: .bold))
                                    }
                                    .foregroundStyle(AppColors.ecgBackground)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(bgColor))
                                    .shadow(color: bgColor.opacity(0.40), radius: 6, x: 0, y: 3)
                                    .animation(.easeInOut(duration: 0.2), value: isSaved)
                                }
                                .buttonStyle(.hapticPlain)
                                .disabled(isSaved)
                                .padding(.bottom, 12)
                                .padding(.trailing, 12)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity),
                                    removal:   .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity)
                                ))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                .animation(.easeInOut(duration: 0.2), value: isSaved)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(AppMetrics.spacing4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    // Shown above the Menu overlay after RR is picked — non-interactive, auto-dismisses
    @ViewBuilder
    private var rrSavedFlash: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
            Text(L10n.Vitals.rrSaved)
                .font(.system(size: 15, weight: .bold))
        }
        .foregroundStyle(AppColors.ecgBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(AppColors.statusSuccess))
        .shadow(color: AppColors.statusSuccess.opacity(0.40), radius: 6, x: 0, y: 3)
        .padding(.bottom, 12)
        .padding(.trailing, 12)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity),
            removal:   .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity)
        ))
    }

    private func handleTap(_ type: VitalType) {
        switch type {
        case .ekg:          viewModel.startEKG()
        case .painLevel:    break
        case .height:       viewModel.openHeight()
        case .weight:       break  // weight is not in the grid; pill uses openWeightScanSheet
        default:
            // Only initiate connection on tap — never disconnect (long press handles disconnect)
            if type.requiresDevice, viewModel.connectionState(for: type) == .disconnected {
                viewModel.startConnect(for: type)
            }
        }
    }

    private func cardValue(for type: VitalType) -> String? {
        switch type {
        case .height: return viewModel.heightDisplay
        case .weight: return viewModel.measurements[.weight]?.displayValue
        default:      return viewModel.measurements[type]?.displayValue
        }
    }

    private func cardSource(for type: VitalType) -> String? {
        switch type {
        case .painLevel:
            return viewModel.painLevel != nil ? L10n.Vitals.sourceManual : nil
        case .respirations:
            return viewModel.measurements[.respirations] != nil ? L10n.Vitals.sourceManual : nil
        case .heartRate:
            if viewModel.measurements[.heartRate] == nil { return nil }
            if viewModel.manualEntryVitals.contains(.heartRate) { return L10n.Vitals.sourceManual }
            if viewModel.connectedDeviceName(for: .bloodPressure) != nil { return "BP" }
            if viewModel.connectedDeviceName(for: .oxygenSaturation) != nil { return "SpO2" }
            return nil
        case .height:
            return nil
        case .weight:
            guard let m = viewModel.measurements[.weight] else { return nil }
            if let fat = m.bodyFatPercent { return String(format: "%.1f%% fat", fat) }
            return viewModel.connectedDeviceName(for: .weight) ?? "Scale"
        default:
            guard viewModel.measurements[type] != nil else { return nil }
            if viewModel.manualEntryVitals.contains(type) { return L10n.Vitals.sourceManual }
            return type.shortName
        }
    }
}

// MARK: - Pain Scale

private let painScale: [(score: Int, emoji: String, label: String, color: Color)] = [
    (0,  "😊", L10n.Vitals.Pain.noPain,        Color(red: 0.20, green: 0.74, blue: 0.40)),
    (2,  "🙂", L10n.Vitals.Pain.mild,          Color(red: 0.50, green: 0.78, blue: 0.28)),
    (4,  "😐", L10n.Vitals.Pain.moderate,      Color(red: 0.86, green: 0.72, blue: 0.10)),
    (6,  "😟", L10n.Vitals.Pain.uncomfortable, Color(red: 0.95, green: 0.50, blue: 0.10)),
    (8,  "😣", L10n.Vitals.Pain.severe,        Color(red: 0.88, green: 0.28, blue: 0.14)),
    (10, "😭", L10n.Vitals.Pain.worst,         Color(red: 0.78, green: 0.08, blue: 0.08))
]

private func painStep(for score: Int) -> (score: Int, emoji: String, label: String, color: Color) {
    painScale.last { $0.score <= score } ?? painScale[0]
}

// MARK: - Vital Card

private struct VitalCard: View {

    let type: VitalType
    let state: DeviceConnectionState
    var selectedPainLevel: Int? = nil
    var selectedValue: String? = nil
    var source: String? = nil
    let onTap: () -> Void
    let onConnectTap: () -> Void
    var onSelectPainLevel: ((Int) -> Void)? = nil
    var onLongPress: (() -> Void)? = nil
    @State private var pendingPainLevel: Int? = nil
    @State private var savedPainLevel: Int? = nil
    // Weight
    var bodyFatPercent: Double? = nil
    // BP save
    var onSave: (() -> Void)? = nil
    var bpSaveState: BPSaveState = .idle
    var bpHasReading: Bool = false
    var bpSensorError: Bool = false
    var bpHistory: [BPHistoryItem] = []
    // BP arm & position
    var bpArm: BPArm = .right
    var bpPosition: BPPosition = .sitting
    var onArmChange: ((BPArm) -> Void)? = nil
    var onPositionChange: ((BPPosition) -> Void)? = nil
    // BP pulse rate (live from device)
    var bpPulseRate: Int? = nil
    // SpO2 save
    var onSaveSpO2: (() -> Void)? = nil
    var spo2SaveState: SpO2SaveState = .idle
    var spo2HasReading: Bool = false
    // Temp save
    var onSaveTemp: (() -> Void)? = nil
    var tempSaveState: TempSaveState = .idle
    var tempHasReading: Bool = false
    // Manual entry
    var onManualEntry: (() -> Void)? = nil

    // Parsed SYS/DIA from "120/80"
    private var bpParsed: (sys: Int, dia: Int)? {
        guard let v = selectedValue else { return nil }
        let p = v.split(separator: "/")
        guard p.count == 2, let s = Int(p[0]), let d = Int(p[1]) else { return nil }
        return (s, d)
    }

    // Live cuff pressure from "160/--" (inflation phase — dia not yet measured)
    private var bpCuffPressure: Int? {
        guard let v = selectedValue else { return nil }
        let p = v.split(separator: "/")
        guard p.count == 2, String(p[1]) == "--", let sys = Int(p[0]), sys > 0 else { return nil }
        return sys
    }

    // Risk-based color for the live reading (thresholds inline — no cross-file type dep)
    private var bpValueColor: Color {
        guard let r = bpParsed else { return type.iconColor.opacity(0.35) }
        if r.sys > 180 || r.dia > 120 { return Color(red: 0.65, green: 0.05, blue: 0.05) }
        if r.sys >= 140 || r.dia >= 90 { return AppColors.statusCritical }
        if r.sys >= 130 || r.dia >= 80 { return Color(red: 0.95, green: 0.50, blue: 0.10) }
        if r.sys >= 120                { return Color(red: 0.86, green: 0.72, blue: 0.10) }
        return AppColors.statusSuccess
    }

    private var badgeLabel: String {
        switch state {
        case .connected:    return "Connected"
        case .searching:    return "Searching..."
        case .connecting:   return "Connecting..."
        case .disconnected: return "Connect"
        }
    }

    private var badgeColor: Color {
        switch state {
        case .connected:              return AppColors.statusSuccess
        case .searching, .connecting: return AppColors.statusWarning
        case .disconnected:           return AppColors.statusCritical
        }
    }

    // MARK: - BP History Strip

    private var bpHistoryStrip: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 5) {
                    ForEach(bpHistory, id: \.id) { item in
                        HStack(spacing: 7) {
                            Circle()
                                .fill(item.riskColor)
                                .frame(width: 7, height: 7)
                            
                            Text(item.displayValue)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                            
                            Text(L10n.Vitals.BP.unit)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(AppColors.textSecondary)
                            
                            if let arm = item.armLabel, let pos = item.positionLabel {
                                Text("\(arm) · \(pos)")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(AppColors.textSecondary.opacity(0.65))
                            }
                            
                            Text("\(item.formattedDate) · \(item.formattedTime)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(AppColors.textSecondary)
                            
                            Spacer(minLength: 0)
                            
                            
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 7)
            }
        }.padding(.vertical,6)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(duration: 0.35), value: bpHistory.count)
    }

    // MARK: - Dedicated BP card (replaces generic monitorCardContent for .bloodPressure)

    private var bpCardContent: some View {
        let parsed = bpParsed
        let vc = bpValueColor
        return ZStack(alignment: .topLeading) {
            // Subtle accent tint
//            LinearGradient(
//                colors: [type.iconColor.opacity(0.08), Color.clear],
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
            VStack(spacing: 0) {
                // Header: NIBP label + arm & position circle buttons
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.shortName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                        Text(type.unitLabel)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    // Arm: R / L circles
                    HStack(spacing: 10) {
                        ForEach(BPArm.allCases, id: \.self) { arm in
                            Button { onArmChange?(arm) } label: {
                                Text(arm.label)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(bpArm == arm ? .white : AppColors.textSecondary)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(bpArm == arm ? AppColors.textPrimary.opacity(0.25) : Color.clear))
                                    .overlay(Circle().stroke(bpArm == arm ? AppColors.textPrimary.opacity(0.6) : AppColors.borderSubtle, lineWidth: 1.5))
                            }
                            .buttonStyle(.hapticPlain)
                            .animation(.easeInOut(duration: 0.15), value: bpArm)
                        }
                    }.padding(.leading)

                    // Divider
                    Rectangle()
                        .fill(AppColors.borderSubtle)
                        .frame(width: 1, height: 20)

                    // Position: Sit / Stand / Lie circles
                    HStack(spacing: 10) {
                        ForEach(BPPosition.allCases, id: \.self) { pos in
                            Button { onPositionChange?(pos) } label: {
                                Group {
                                    if pos == .lying {
                                        Image("layingPerson")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22)
                                    } else {
                                        Image(systemName: pos.icon)
                                            .font(.system(size: 17, weight: .medium))
                                    }
                                }
                                .foregroundStyle(bpPosition == pos ? .white : AppColors.textSecondary)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(bpPosition == pos ? AppColors.textPrimary.opacity(0.25) : Color.clear))
                                .overlay(Circle().stroke(bpPosition == pos ? AppColors.textPrimary.opacity(0.6) : AppColors.borderSubtle, lineWidth: 1.5))
                            }
                            .buttonStyle(.hapticPlain)
                            .animation(.easeInOut(duration: 0.15), value: bpPosition)
                        }
                    }.padding(.trailing)

                    Spacer()
                }
                .padding(.top, 10)
                .padding(.leading, 12)

                Spacer(minLength: 10)


                // History strip
                if !bpHistory.isEmpty {
                    bpHistoryStrip
                }
            }
            
            VStack{
                Spacer(minLength: 0)

                if bpSensorError {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColors.statusCritical)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.Vitals.BP.sensorError)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppColors.statusCritical)
                            Text(L10n.Vitals.BP.sensorErrorMessage)
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.statusCritical.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if let r = parsed {
                    // Complete reading — split SYS / DIA columns
                    HStack(spacing: 0) {
                        Spacer()

                        // SYS column
                        VStack(alignment: .center, spacing: 3) {
                            Text("\(r.sys)")
                                .font(.system(size: 100, weight: .medium))
                                .foregroundStyle(type.iconColor.opacity(0.9))
                                .contentTransition(.numericText())
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                            Text(L10n.Vitals.BP.sys)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(type.iconColor.opacity(0.55))
                                .tracking(2)
                        }
                        .frame(minWidth: 80)

                        // Slash
                        Text("/")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(type.iconColor.opacity(0.8))
                            .padding(.horizontal, 6)
                            .offset(y: -14)

                        // DIA column
                        VStack(alignment: .center, spacing: 3) {
                            Text("\(r.dia)")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundStyle(type.iconColor.opacity(0.9))
                                .contentTransition(.numericText())
                                .minimumScaleFactor(0.45)
                                .lineLimit(1)
                            Text(L10n.Vitals.BP.dia)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(type.iconColor.opacity(0.55))
                                .tracking(2)
                        }
                        .frame(minWidth: 80)

                        Spacer()
                        
                    }
                    .animation(.easeInOut(duration: 0.3), value: selectedValue)
                } else if let cuff = bpCuffPressure {
                    // Inflation phase — live cuff pressure, DIA not yet measured
                    HStack(spacing: 0) {
                        Spacer()

                        VStack(alignment: .center, spacing: 3) {
                            Text("\(cuff)")
                                .font(.system(size: 100, weight: .medium))
                                .foregroundStyle(type.iconColor.opacity(0.9))
                                .contentTransition(.numericText())
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                            Text(L10n.Vitals.BP.sys)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(type.iconColor.opacity(0.45))
                                .tracking(2)
                        }
                        .frame(minWidth: 80)

                        Text("/")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(type.iconColor.opacity(0.9))
                            .padding(.horizontal, 6)
                            .offset(y: -14)

                        VStack(alignment: .center, spacing: 3) {
                            Text("--")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundStyle(type.iconColor.opacity(0.25))
                            Text(L10n.Vitals.BP.dia)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(type.iconColor.opacity(0.25))
                                .tracking(2)
                        }
                        .frame(minWidth: 80)

                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.15), value: cuff)
                } else {
                    // No reading — show placeholder
                    Text("––/––")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(type.iconColor.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Spacer(minLength: 0)

            }
        }
    }

    // Arm (L/R) + position (Sitting/Standing/Lying) selector strip shown on the BP card
    private var bpArmPositionSelector: some View {
        HStack(spacing: 8) {
            // Arm toggle
            HStack(spacing: 1) {
                ForEach(BPArm.allCases, id: \.self) { arm in
                    Button { onArmChange?(arm) } label: {
                        Text(arm.label)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(bpArm == arm ? AppColors.ecgBackground : AppColors.textSecondary)
                            .frame(width: 28, height: 24)
                            .background(bpArm == arm ? type.iconColor.opacity(0.85) : Color.clear)
                    }
                    .buttonStyle(.hapticPlain)
                }
            }
            .background(AppColors.borderSubtle.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer()

            // Position picker
            HStack(spacing: 1) {
                ForEach(BPPosition.allCases, id: \.self) { pos in
                    Button { onPositionChange?(pos) } label: {
                        HStack(spacing: 3) {
                            Image(systemName: pos.icon)
                                .font(.system(size: 10, weight: .medium))
                            Text(pos.shortLabel)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(bpPosition == pos ? AppColors.ecgBackground : AppColors.textSecondary)
                        .padding(.horizontal, 7)
                        .frame(height: 24)
                        .background(bpPosition == pos ? type.iconColor.opacity(0.85) : Color.clear)
                    }
                    .buttonStyle(.hapticPlain)
                }
            }
            .background(AppColors.borderSubtle.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .animation(.easeInOut(duration: 0.15), value: bpArm)
        .animation(.easeInOut(duration: 0.15), value: bpPosition)
    }
    
    // Floating save capsule — appears when BP reading is complete
    @ViewBuilder
    private var bpSaveOverlay: some View {
        if bpHasReading || bpSaveState == .saved {
            Button { onSave?() } label: {
                HStack(spacing: 5) {
                    Image(systemName: bpSaveState == .saved
                          ? "checkmark.circle.fill"
                          : "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(bpSaveState == .saved ? L10n.Vitals.BP.saved : L10n.Vitals.BP.saveReading)
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(AppColors.ecgBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(bpSaveState == .saved
                        ? AppColors.statusSuccess
                        : AppColors.brandPrimary)
                )
                .shadow(
                    color: (bpSaveState == .saved
                        ? AppColors.statusSuccess
                        : AppColors.brandPrimary).opacity(0.40),
                    radius: 6, x: 0, y: 3
                )
            }
            .buttonStyle(.hapticPlain)
            .disabled(bpSaveState == .saved)
            .padding(.bottom, 12)
            .padding(.trailing, 12)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.6, anchor: .bottomTrailing)
                    .combined(with: .opacity),
                removal:   .scale(scale: 0.6, anchor: .bottomTrailing)
                    .combined(with: .opacity)
            ))
        }
    }
    
    @ViewBuilder
    private var spo2SaveOverlay: some View {
        if spo2HasReading || spo2SaveState == .saved {
            Button { onSaveSpO2?() } label: {
                HStack(spacing: 5) {
                    Image(systemName: spo2SaveState == .saved
                          ? "checkmark.circle.fill"
                          : "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(spo2SaveState == .saved ? L10n.Vitals.SpO2.saved : L10n.Vitals.SpO2.saveReading)
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(AppColors.ecgBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(spo2SaveState == .saved
                        ? AppColors.statusSuccess
                        : AppColors.brandPrimary)
                )
                .shadow(
                    color: (spo2SaveState == .saved
                        ? AppColors.statusSuccess
                        : AppColors.brandPrimary).opacity(0.40),
                    radius: 6, x: 0, y: 3
                )
            }
            .buttonStyle(.hapticPlain)
            .disabled(spo2SaveState == .saved)
            .padding(.bottom, 12)
            .padding(.trailing, 12)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.6, anchor: .bottomTrailing)
                    .combined(with: .opacity),
                removal:   .scale(scale: 0.6, anchor: .bottomTrailing)
                    .combined(with: .opacity)
            ))
        }
    }

    @ViewBuilder
    private var tempSaveOverlay: some View {
        if tempHasReading || tempSaveState == .saved {
            Button { onSaveTemp?() } label: {
                HStack(spacing: 5) {
                    Image(systemName: tempSaveState == .saved
                          ? "checkmark.circle.fill"
                          : "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(tempSaveState == .saved ? L10n.Vitals.Temp.saved : L10n.Vitals.Temp.saveReading)
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(AppColors.ecgBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(tempSaveState == .saved
                        ? AppColors.statusSuccess
                        : AppColors.brandPrimary)
                )
                .shadow(
                    color: (tempSaveState == .saved
                        ? AppColors.statusSuccess
                        : AppColors.brandPrimary).opacity(0.40),
                    radius: 6, x: 0, y: 3
                )
            }
            .buttonStyle(.hapticPlain)
            .disabled(tempSaveState == .saved)
            .padding(.bottom, 12)
            .padding(.trailing, 12)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.6, anchor: .bottomTrailing)
                    .combined(with: .opacity),
                removal:   .scale(scale: 0.6, anchor: .bottomTrailing)
                    .combined(with: .opacity)
            ))
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                AppColors.surfaceCard

                if type == .ekg {
                    ekgCardContent
                } else if type == .echo {
                    echoCardContent
                } else if type == .painLevel {
                    painCardContent
                } else if type == .bloodPressure {
                    bpCardContent
                } else {
                    monitorCardContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                ExclusiveGesture(
                    LongPressGesture(minimumDuration: 0.5),
                    TapGesture()
                )
                .onEnded { value in
                    switch value {
                    case .first:
                        guard let onLongPress else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onLongPress()
                    case .second:
                        onTap()
                    }
                }
            )
            .animation(.easeInOut(duration: 0.25), value: selectedValue)

            // Connection dot + state label — top-right corner
            if type.requiresDevice {
                Button(action: onConnectTap) {
                    HStack(spacing: 4) {
                        if state == .searching || state == .connecting {
                            Text(state == .searching ? L10n.Vitals.Device.scanning : L10n.Vitals.Device.connecting)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(badgeColor)
                        } else if state == .disconnected {
                            Text("Tap to connect")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Circle()
                            .fill(badgeColor)
                            .frame(width: 9, height: 9)
                    }
                    .padding(AppMetrics.spacing10)
                }
                .buttonStyle(.hapticPlain)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            // BP save button — slides in when a complete reading is ready
            if type == .bloodPressure {
                bpSaveOverlay
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .animation(.spring(response: 0.45, dampingFraction: 0.65), value: bpHasReading || bpSaveState == .saved)
                    .animation(.spring(duration: 0.35), value: bpSaveState)
            }

            // SpO2 save button
            if type == .oxygenSaturation {
                spo2SaveOverlay
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .animation(.spring(response: 0.45, dampingFraction: 0.65), value: spo2HasReading || spo2SaveState == .saved)
                    .animation(.spring(duration: 0.35), value: spo2SaveState)
            }

            // Temp save button
            if type == .temperature {
                tempSaveOverlay
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .animation(.spring(response: 0.45, dampingFraction: 0.65), value: tempHasReading || tempSaveState == .saved)
                    .animation(.spring(duration: 0.35), value: tempSaveState)
            }

            // Manual entry pencil — bottom-left on BP/SpO2/Temp/HR
            if let onManualEntry {
                Button(action: onManualEntry) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.hapticPlain)
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .background(AppColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusSmall)
                .stroke(type.iconColor.opacity(0.18), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: state)
    }

    // Monitor-style layout for non-BP vitals
    private var monitorCardContent: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(type.shortName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(type.iconColor)
                        if !type.unitLabel.isEmpty {
                            Text(type.unitLabel)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(type.iconColor.opacity(0.65))
                        }
                    }
                    .padding(.top, 8)
                    .padding(.leading, 10)
                    Spacer()
                }
                Spacer(minLength: 0)
            }

            VStack {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    if let value = selectedValue {
                        VStack(spacing: 2) {
                            valueText(value)
                            if type == .weight, let fat = bodyFatPercent {
                                Text(String(format: "%.1f%% fat", fat))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(type.iconColor.opacity(0.8))
                                    .contentTransition(.numericText())
                                    .animation(.spring(duration: 0.35), value: fat)
                            }
                        }
                    } else {
                        Text("––")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(type.iconColor)
                    }
                    Spacer(minLength: 0)
                }
                .animation(.easeInOut(duration: 0.25), value: selectedValue)
                Spacer(minLength: 0)
            }

            VStack(spacing: 0) {
                Spacer()
                if let source, selectedValue != nil, !(type == .weight && bodyFatPercent != nil) {
                    Text(L10n.Vitals.sourceLabel(source))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(type.iconColor.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical)
                }
            }
        }
    }

    @ViewBuilder
    private func valueText(_ value: String) -> some View {
        if type == .heartRate {
            HStack(alignment: .center, spacing: 5) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.red)
                Text(value)
                    .font(.system(size: 100, weight: .medium))
                    .foregroundStyle(type.iconColor)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            }
        } else {
            Text(value)
                .font(.system(size: 100, weight: .medium))
                .foregroundStyle(type.iconColor)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.35), value: value)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .padding(.horizontal, 6)
        }
    }

    // EKG wide card
    private var ekgCardContent: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(type.shortName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(type.iconColor)
                }
                .padding(.top, 8)
                .padding(.leading, 10)
                Spacer()
            }
            Spacer(minLength: 0)
            ZStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(type.iconColor)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(AppColors.surfaceCard)
                    .offset(y: -2)
            }
            AppImages.logo
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .padding(.top, 6)
            Spacer(minLength: 0)
        }
    }

    // Echo wide card
    private var echoCardContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text(type.shortName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(type.iconColor)
                    .padding(.top, 8)
                    .padding(.leading, 10)
                Spacer()
            }
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(type.iconColor.opacity(0.10))
                    .frame(width: 72, height: 72)
                Image(systemName: "waveform.path.badge.plus")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(type.iconColor)
            }
            
            HStack(alignment: .bottom,spacing: 3) {
                Image("ELogo").resizable().scaledToFit().frame(height: 30)
                Text(type.shortName)
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.textPrimary)
                    .offset(y:10)
            }
            
            Spacer(minLength: 0)

        }
    }

    // Pain level card — always shows all states for direct selection
    private var painCardContent: some View {
        VStack(spacing: 0) {
            // Header label
            HStack {
                Text(type.shortName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(type.iconColor)
                    .padding(.top, 8)
                    .padding(.leading, 10)
                Spacer()
            }

            Spacer(minLength: 0)

            // Selected state summary
            if let score = pendingPainLevel {
                let s = painStep(for: score)
                HStack(spacing: 6) {
                    Image("painLevel\(s.score)")
                        .resizable().scaledToFit()
                        .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(score) / 10")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(s.color)
                        Text(s.label)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(s.color.opacity(0.7))
                    }
                }
                .animation(.spring(duration: 0.3), value: score)
                .padding(.bottom, 4)
            }

            Spacer(minLength: 0)

            // Inline image picker — all 6 levels
            HStack(spacing: 0) {
                ForEach(painScale, id: \.score) { s in
                    let isSel = s.score == pendingPainLevel
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            pendingPainLevel = s.score
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image("painLevel\(s.score)")
                                .resizable().scaledToFit()
                                .frame(width: isSel ? 52 : 40, height: isSel ? 52 : 40)
                                .frame(width: 64, height: 64)
                                .background(Circle().fill(isSel ? s.color.opacity(0.15) : Color.clear))
                                .overlay(Circle().stroke(isSel ? s.color.opacity(0.5) : Color.clear, lineWidth: 1.5))
                                .animation(.spring(duration: 0.25), value: isSel)
                            Text("\(s.score)")
                                .font(.system(size: 14, weight: isSel ? .bold : .regular))
                                .foregroundStyle(isSel ? s.color : AppColors.textSecondary)
                        }
                    }
                    .buttonStyle(.hapticPlain)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            .padding(.bottom,12)

            // Save button
            if let pending = pendingPainLevel {
                let isSaved = pending == savedPainLevel
                let color   = isSaved ? AppColors.statusSuccess : painStep(for: pending).color
                Button {
                    onSelectPainLevel?(pending)
                    savedPainLevel = pending
                } label: {
                    HStack(spacing: 5) {
                        if isSaved {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text(isSaved ? L10n.Vitals.Pain.saved : L10n.Vitals.Pain.save)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(color)
                    .cornerRadius(AppMetrics.radiusMedium)
                    .animation(.easeInOut(duration: 0.2), value: isSaved)
                }
                .buttonStyle(.hapticPlain)
                .disabled(isSaved)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear {
            pendingPainLevel = selectedPainLevel
            savedPainLevel   = selectedPainLevel
        }
        .onChange(of: selectedPainLevel) {
            pendingPainLevel = selectedPainLevel
            savedPainLevel   = selectedPainLevel
        }
    }
}

// MARK: - Height Sheet

private struct HeightSheet: View {

    enum HeightUnit: CaseIterable {
        case imperial, metric
        var displayName: String {
            switch self {
            case .imperial: return L10n.Vitals.Height.unitImperial
            case .metric:   return L10n.Vitals.Height.unitMetric
            }
        }
    }

    @State private var unit: HeightUnit = .imperial
    @State private var feet: Int
    @State private var inches: Int
    @State private var cm: Int
    @Environment(\.dismiss) private var dismiss
    let onSave: (Double, String) -> Void

    init(currentCm: Double?, onSave: @escaping (Double, String) -> Void) {
        let c = currentCm ?? 170.0
        let totalIn = Int(c / 2.54)
        _feet   = State(wrappedValue: max(3, min(8, totalIn / 12)))
        _inches = State(wrappedValue: totalIn % 12)
        _cm     = State(wrappedValue: Int(c))
        self.onSave = onSave
    }

    private var valueInCm: Double {
        unit == .imperial ? Double(feet) * 30.48 + Double(inches) * 2.54 : Double(cm)
    }
    private var displayString: String {
        unit == .imperial ? "\(feet)' \(inches)\"" : "\(cm) cm"
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                sheetHeader(title: L10n.Vitals.Height.title, icon: "ruler.fill", color: VitalType.height.iconColor, onClose: { dismiss() })


                Text(displayString)
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: displayString)
                    .padding(.top, 14)
                    .padding(.bottom, 20)

                // Unit toggle
                Picker("", selection: $unit) {
                    ForEach(HeightUnit.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 36)
                .padding(.bottom, 8)
                .onChange(of: unit) { _, newUnit in
                    if newUnit == .metric {
                        cm = Int(valueInCm.rounded())
                    } else {
                        let totalIn = Int(Double(cm) / 2.54)
                        feet   = max(3, min(8, totalIn / 12))
                        inches = totalIn % 12
                    }
                }

                // Wheel pickers
                HStack(spacing: 0) {
                    if unit == .imperial {
                        Picker("Feet", selection: $feet) {
                            ForEach(3...8, id: \.self) { Text("\($0) ft").font(.system(size: 33)).tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Inches", selection: $inches) {
                            ForEach(0...11, id: \.self) { Text("\($0) in").font(.system(size: 33)).tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    } else {
                        Picker("cm", selection: $cm) {
                            ForEach(100...250, id: \.self) { Text("\($0) cm").font(.system(size: 33)).tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 160)
                .padding(.horizontal, 20)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusLarge)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Save
                saveButton(label: L10n.Vitals.Height.save, action: { onSave(valueInCm, displayString) })
            }
        }
    }
}

// MARK: - Weight Sheet

private struct WeightSheet: View {

    enum WeightUnit: CaseIterable {
        case imperial, metric
        var displayName: String {
            switch self {
            case .imperial: return L10n.Vitals.Weight.unitImperial
            case .metric:   return L10n.Vitals.Weight.unitMetric
            }
        }
    }

    @State private var unit: WeightUnit = .imperial
    @State private var lbs: Int
    @State private var kg: Int
    @Environment(\.dismiss) private var dismiss
    let onSave: (Double, String) -> Void

    init(currentKg: Double?, onSave: @escaping (Double, String) -> Void) {
        let k = currentKg ?? 70.0
        _kg  = State(wrappedValue: Int(k.rounded()))
        _lbs = State(wrappedValue: Int((k * 2.2046).rounded()))
        self.onSave = onSave
    }

    private var valueInKg: Double {
        unit == .imperial ? Double(lbs) / 2.2046 : Double(kg)
    }
    private var displayString: String {
        unit == .imperial ? "\(lbs) lbs" : "\(kg) kg"
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                sheetHeader(title: L10n.Vitals.Weight.title, icon: "scalemass", color: VitalType.weight.iconColor, onClose: { dismiss() })

                Text(displayString)
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: displayString)
                    .padding(.top, 14)
                    .padding(.bottom, 20)

                // Unit toggle
                Picker("", selection: $unit) {
                    ForEach(WeightUnit.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 36)
                .padding(.bottom, 8)
                .onChange(of: unit) { _, newUnit in
                    if newUnit == .metric {
                        kg = Int((Double(lbs) / 2.2046).rounded())
                    } else {
                        lbs = Int((Double(kg) * 2.2046).rounded())
                    }
                }

                // Wheel picker
                Group {
                    if unit == .imperial {
                        Picker("lbs", selection: $lbs) {
                            ForEach(50...700, id: \.self) { Text("\($0) lbs").font(.system(size: 33)).tag($0) }
                        }
                        .pickerStyle(.wheel)
                    } else {
                        Picker("kg", selection: $kg) {
                            ForEach(20...300, id: \.self) { Text("\($0) kg").font(.system(size: 33)).tag($0) }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                .frame(height: 160)
                .padding(.horizontal, 20)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusLarge)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Save
                saveButton(label: L10n.Vitals.Weight.save, action: { onSave(valueInKg, displayString) })
            }
        }
    }
}

// MARK: - Shared sheet helpers

private func sheetHeader(title: String, icon: String, color: Color, onClose: @escaping () -> Void) -> some View {
    HStack {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
            Text(title)
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.textPrimary)
        }
        Spacer()
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(AppColors.borderSubtle.opacity(0.5))
                .clipShape(Circle())
        }
        .buttonStyle(.hapticPlain)
    }
    .padding(.horizontal, 36)
    .padding(.top, 32)
    .padding(.bottom, 8)
}

private func saveButton(label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(AppTypography.bodyMedium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppMetrics.buttonHeight)
            .background(AppColors.brandPrimary)
            .cornerRadius(AppMetrics.radiusMedium)
    }
    .buttonStyle(.hapticPlain)
    .padding(.horizontal, 36)
    .padding(.bottom, 32)
}

// MARK: - Weight Scan Sheet (BLE + Manual combined)

private struct WeightScanSheet: View {

    @State var viewModel: VitalsViewModel
    @State private var unit: WeightUnit = {
        if let raw = UserDefaults.standard.string(forKey: "app.weightUnit"),
           let v = WeightUnit(rawValue: raw) { return v }
        return .imperial
    }()
    @State private var lbs: Int = 154
    @State private var kg: Int  = 70
    @Environment(\.dismiss) private var dismiss

    private var state: DeviceConnectionState { viewModel.connectionState(for: .weight) }
    private var scanDevices: [WeightDeviceInfo] { viewModel.weightScanDevices }
    private var isBusy: Bool { state == .searching || state == .connecting }
    private var bleReading: VitalMeasurement? { viewModel.measurements[.weight] }

    private var rawValue: Double  { unit == .imperial ? Double(lbs) : Double(kg) }
    private var displayString: String { unit == .imperial ? "\(lbs) lbs" : "\(kg) kg" }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {

                    sheetHeader(
                        title: L10n.Vitals.Weight.title,
                        icon: VitalType.weight.icon,
                        color: VitalType.weight.iconColor,
                        onClose: { dismiss() }
                    )

                    // ── BLE Section ──────────────────────────────────────
                    bleSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    Divider()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                    // ── Manual Entry Section ─────────────────────────────
                    Text(displayString)
                        .font(AppTypography.title1)
                        .foregroundStyle(AppColors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.15), value: displayString)
                        .padding(.bottom, 16)

                    Group {
                        if unit == .imperial {
                            Picker("lbs", selection: $lbs) {
                                ForEach(50...700, id: \.self) { Text("\($0) lbs").font(.system(size: 33)).tag($0) }
                            }
                            .pickerStyle(.wheel)
                        } else {
                            Picker("kg", selection: $kg) {
                                ForEach(20...300, id: \.self) { Text("\($0) kg").font(.system(size: 33)).tag($0) }
                            }
                            .pickerStyle(.wheel)
                        }
                    }
                    .frame(height: 160)
                    .padding(.horizontal, 20)
                    .background(AppColors.surfaceCard)
                    .cornerRadius(AppMetrics.radiusLarge)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    saveButton(label: L10n.Vitals.Weight.save) {
                        viewModel.saveWeight(rawValue, unit: unit.rawValue, display: displayString)
                        dismiss()
                    }
                }
            }
        }
        // BLE measurement auto-populates the picker
        .onChange(of: viewModel.measurements[.weight]?.displayValue) { _, newValue in
            guard let str = newValue, let measured = Double(str) else { return }
            kg  = Int(measured.rounded())
            lbs = Int((measured * 2.2046).rounded())
        }
    }

    // MARK: - BLE Section

    @ViewBuilder
    private var bleSection: some View {
        VStack(spacing: AppMetrics.spacing10) {

            // Status row
            HStack(spacing: 6) {
                if isBusy {
                    ProgressView().scaleEffect(0.7).tint(stateColor)
                } else {
                    Circle().fill(stateColor).frame(width: 7, height: 7)
                }
                Text(stateLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(stateColor)
                if let reading = bleReading {
                    Text("·")
                        .foregroundStyle(AppColors.textSecondary)
                        .font(.system(size: 12))
                    Text("\(reading.displayValue) kg" + (reading.bodyFatPercent.map { String(format: " · %.1f%% fat", $0) } ?? ""))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(VitalType.weight.iconColor)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.3), value: reading.displayValue)
                }
                if state == .connected {
                    Text("·")
                        .foregroundStyle(AppColors.textSecondary)
                        .font(.system(size: 12))
                    Button {
                        viewModel.disconnect()
                    } label: {
                        Text(L10n.Vitals.Device.disconnect)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.statusCritical)
                    }
                    .buttonStyle(.hapticPlain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppMetrics.spacing12)
            .padding(.vertical, 6)
            .background(stateColor.opacity(0.08))
            .cornerRadius(AppMetrics.radiusMedium)
        }
    }

    private var stateLabel: String {
        switch state {
        case .connected:              return "Connected"
        case .searching:              return "Scanning..."
        case .connecting:             return "Connecting..."
        case .disconnected:           return "Searching for scale..."
        }
    }
    private var stateIcon: String {
        switch state {
        case .connected:              return "checkmark.circle.fill"
        case .searching, .connecting: return "antenna.radiowaves.left.and.right"
        case .disconnected:           return VitalType.weight.icon
        }
    }
    private var stateColor: Color {
        switch state {
        case .connected:              return AppColors.statusSuccess
        case .searching, .connecting: return AppColors.statusWarning
        case .disconnected:           return VitalType.weight.iconColor
        }
    }
}

// MARK: - Manual BP Sheet

private struct ManualBPSheet: View {
    @State private var systolic:  Int = 120
    @State private var diastolic: Int = 80
    @State private var includePR: Bool = false
    @State private var pulseRate: Int = 72
    @State private var arm: BPArm
    @State private var position: BPPosition
    @Environment(\.dismiss) private var dismiss
    let onSave: (Int, Int, Int?) -> Void

    init(arm: BPArm, position: BPPosition, onSave: @escaping (Int, Int, Int?) -> Void) {
        _arm = State(wrappedValue: arm)
        _position = State(wrappedValue: position)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                sheetHeader(title: "Blood Pressure", icon: VitalType.bloodPressure.icon,
                            color: VitalType.bloodPressure.iconColor, onClose: { dismiss() })

                // Live preview
                HStack(spacing: 4) {
                    Text("\(systolic)")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(VitalType.bloodPressure.iconColor)
                        .contentTransition(.numericText())
                    Text("/")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(VitalType.bloodPressure.iconColor.opacity(0.6))
                    Text("\(diastolic)")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(VitalType.bloodPressure.iconColor)
                        .contentTransition(.numericText())
                    Text("mmHg")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.leading, 4)
                        .alignmentGuide(.bottom) { d in d[.bottom] }
                }
                .animation(.easeInOut(duration: 0.15), value: systolic)
                .animation(.easeInOut(duration: 0.15), value: diastolic)
                .padding(.vertical, 10)

                // Arm & position
                HStack(spacing: 12) {
                    ForEach(BPArm.allCases, id: \.self) { a in
                        Button { arm = a } label: {
                            Text(a.label)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(arm == a ? .white : AppColors.textSecondary)
                                .frame(width: 44, height: 36)
                                .background(arm == a ? VitalType.bloodPressure.iconColor.opacity(0.8) : AppColors.borderSubtle.opacity(0.4))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.hapticPlain)
                    }
                    Divider().frame(height: 24)
                    ForEach(BPPosition.allCases, id: \.self) { p in
                        Button { position = p } label: {
                            Text(p.shortLabel)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(position == p ? .white : AppColors.textSecondary)
                                .padding(.horizontal, 10)
                                .frame(height: 36)
                                .background(position == p ? VitalType.bloodPressure.iconColor.opacity(0.8) : AppColors.borderSubtle.opacity(0.4))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.hapticPlain)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: arm)
                .animation(.easeInOut(duration: 0.15), value: position)
                .padding(.bottom, 10)

                // Pickers
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text("SYS").font(.system(size: 11, weight: .bold)).foregroundStyle(AppColors.textSecondary).tracking(1)
                        Picker("SYS", selection: $systolic) {
                            ForEach(60...250, id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                    }
                    VStack(spacing: 2) {
                        Text("DIA").font(.system(size: 11, weight: .bold)).foregroundStyle(AppColors.textSecondary).tracking(1)
                        Picker("DIA", selection: $diastolic) {
                            ForEach(40...150, id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                    }
                }
                .frame(height: 150)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusLarge)
                .padding(.horizontal, 24)

                // Optional PR toggle
                Toggle(isOn: $includePR.animation()) {
                    Label("Include Pulse Rate", systemImage: "heart.fill")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .tint(AppColors.brandPrimary)
                .padding(.horizontal, 36)
                .padding(.top, 12)

                if includePR {
                    HStack(spacing: 0) {
                        Picker("PR", selection: $pulseRate) {
                            ForEach(30...200, id: \.self) { Text("\($0) bpm").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)
                    .background(AppColors.surfaceCard)
                    .cornerRadius(AppMetrics.radiusLarge)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 16)
                saveButton(label: "Save BP") {
                    onSave(systolic, diastolic, includePR ? pulseRate : nil)
                }
            }
        }
    }
}

// MARK: - Manual SpO2 Sheet

private struct ManualSpO2Sheet: View {
    @State private var spo2:      Int = 98
    @State private var includePR: Bool = false
    @State private var pulseRate: Int = 72
    @Environment(\.dismiss) private var dismiss
    let onSave: (Int, Int?) -> Void

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                sheetHeader(title: "SpO2", icon: VitalType.oxygenSaturation.icon,
                            color: VitalType.oxygenSaturation.iconColor, onClose: { dismiss() })

                Text("\(spo2)%")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(VitalType.oxygenSaturation.iconColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: spo2)
                    .padding(.vertical, 10)

                Picker("SpO2", selection: $spo2) {
                    ForEach(50...100, id: \.self) { Text("\($0) %").font(.system(size: 33)).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 140)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusLarge)
                .padding(.horizontal, 24)

                Toggle(isOn: $includePR.animation()) {
                    Label("Include Pulse Rate", systemImage: "heart.fill")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .tint(AppColors.brandPrimary)
                .padding(.horizontal, 36)
                .padding(.top, 12)

                if includePR {
                    Picker("PR", selection: $pulseRate) {
                        ForEach(30...200, id: \.self) { Text("\($0) bpm").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)
                    .background(AppColors.surfaceCard)
                    .cornerRadius(AppMetrics.radiusLarge)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 16)
                saveButton(label: "Save SpO2") {
                    onSave(spo2, includePR ? pulseRate : nil)
                }
            }
        }
    }
}

// MARK: - Manual Temp Sheet

private struct ManualTempSheet: View {

    private let isFahrenheit: Bool = {
        (UserDefaults.standard.string(forKey: "app.temperatureUnit") ?? "°F") == "°F"
    }()

    @State private var whole: Int
    @State private var tenth: Int = 6
    @Environment(\.dismiss) private var dismiss
    let onSave: (Double, String) -> Void

    init(onSave: @escaping (Double, String) -> Void) {
        let isFahrenheit = (UserDefaults.standard.string(forKey: "app.temperatureUnit") ?? "°F") == "°F"
        _whole = State(wrappedValue: isFahrenheit ? 98 : 36)
        self.onSave = onSave
    }

    private var displayValue: Double { Double(whole) + Double(tenth) / 10 }
    private var displayUnit: String  { isFahrenheit ? "°F" : "°C" }
    private var wholeRange: ClosedRange<Int> { isFahrenheit ? 95...110 : 34...42 }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                sheetHeader(title: "Temperature", icon: VitalType.temperature.icon,
                            color: VitalType.temperature.iconColor, onClose: { dismiss() })

                Text(String(format: "%.1f %@", displayValue, displayUnit))
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(VitalType.temperature.iconColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: displayValue)
                    .padding(.vertical, 10)

                HStack(spacing: 0) {
                    Picker(displayUnit, selection: $whole) {
                        ForEach(wholeRange, id: \.self) { Text("\($0)").font(.system(size: 30)).tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Text(".")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 20)

                    Picker("tenths", selection: $tenth) {
                        ForEach(0...9, id: \.self) { Text("\($0)").font(.system(size: 30)).tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 140)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusLarge)
                .padding(.horizontal, 24)

                Spacer(minLength: 16)
                saveButton(label: "Save Temperature") {
                    onSave(displayValue, displayUnit)
                }
            }
        }
    }
}

// MARK: - Manual PR Sheet

private struct ManualPRSheet: View {
    @State private var bpm: Int = 72
    @Environment(\.dismiss) private var dismiss
    let onSave: (Int) -> Void

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                sheetHeader(title: "Pulse Rate", icon: VitalType.heartRate.icon,
                            color: VitalType.heartRate.iconColor, onClose: { dismiss() })

                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.red)
                    Text("\(bpm)")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(VitalType.heartRate.iconColor)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.15), value: bpm)
                    Text("BPM")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.vertical, 10)

                Picker("BPM", selection: $bpm) {
                    ForEach(30...250, id: \.self) { Text("\($0) bpm").font(.system(size: 33)).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusLarge)
                .padding(.horizontal, 24)

                Spacer(minLength: 16)
                saveButton(label: "Save Pulse Rate") {
                    onSave(bpm)
                }
            }
        }
    }
}

// MARK: - Device Connect Sheet

//private struct DeviceConnectSheet: View {
//
//    let vital: VitalType
//    @State var viewModel: VitalsViewModel
//    @Environment(\.dismiss) private var dismiss
//
//    private var supportsManualEntry: Bool {
//        [VitalType.bloodPressure, .oxygenSaturation, .temperature, .heartRate].contains(vital)
//    }
//
//    private var state: DeviceConnectionState { viewModel.connectionState(for: vital) }
//
//    var body: some View {
//        ZStack {
//            AppColors.surfaceBackground.ignoresSafeArea()
//
//            VStack(spacing: AppMetrics.spacing32) {
//                header
//                statusBlock
//                actionButtons
//                Spacer()
//            }
//            .padding(AppMetrics.spacing32)
//        }
//        .onAppear {
//            if state == .disconnected { viewModel.connect() }
//        }
//    }
//
//    private var header: some View {
//        HStack(alignment: .top) {
//            VStack(alignment: .leading, spacing: 4) {
//                Text(L10n.Vitals.Device.connectTitle)
//                    .font(AppTypography.title2)
//                    .foregroundStyle(AppColors.textPrimary)
//                Text(vital.connectDescription)
//                    .font(AppTypography.caption)
//                    .foregroundStyle(AppColors.textSecondary)
//            }
//            Spacer()
//            Button { dismiss() } label: {
//                Image(systemName: "xmark.circle.fill")
//                    .font(.system(size: 28))
//                    .foregroundStyle(AppColors.textSecondary)
//            }
//            .buttonStyle(.hapticPlain)
//        }
//    }
//
//    private var statusBlock: some View {
//        VStack(spacing: AppMetrics.spacing16) {
//            DeviceConnectButton(state: state) {
//                state == .disconnected ? viewModel.connect() : viewModel.disconnect()
//            }
//            .frame(maxWidth: .infinity)
//
//            if let name = viewModel.connectedDeviceName(for: vital) {
//                Label(name, systemImage: "checkmark.seal.fill")
//                    .font(AppTypography.callout)
//                    .foregroundStyle(AppColors.statusSuccess)
//            }
//        }
//    }
//
//    private var isBusy: Bool { state == .searching || state == .connecting }
//
//    private var actionButtons: some View {
//        VStack(spacing: AppMetrics.spacing12) {
//            Button(action: viewModel.connect) {
//                HStack(spacing: AppMetrics.spacing10) {
//                    Image(systemName: "antenna.radiowaves.left.and.right")
//                        .font(.system(size: 16, weight: .semibold))
//                    Text(L10n.Vitals.Device.connectDevice(vital.title))
//                        .font(AppTypography.bodyMedium)
//                }
//                .foregroundStyle(.white)
//                .frame(maxWidth: .infinity)
//                .frame(height: AppMetrics.buttonHeight)
//                .background(isBusy ? AppColors.brandPrimary.opacity(0.4) : AppColors.brandPrimary)
//                .cornerRadius(AppMetrics.radiusMedium)
//            }
//            .buttonStyle(.hapticPlain)
//            .disabled(isBusy)
//
//            Button(action: viewModel.connectDemo) {
//                HStack(spacing: AppMetrics.spacing10) {
//                    Image(systemName: "waveform.path.ecg")
//                        .font(.system(size: 16, weight: .semibold))
//                    Text(L10n.Vitals.Device.useDemo)
//                        .font(AppTypography.bodyMedium)
//                }
//                .foregroundStyle(AppColors.brandPrimary)
//                .frame(maxWidth: .infinity)
//                .frame(height: AppMetrics.buttonHeight)
//                .background(AppColors.brandPrimary.opacity(0.10))
//                .cornerRadius(AppMetrics.radiusMedium)
//                .overlay(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
//                    .strokeBorder(AppColors.brandPrimary.opacity(0.3), lineWidth: 1))
//            }
//            .buttonStyle(.hapticPlain)
//            .disabled(isBusy)
//
//            if supportsManualEntry {
//                Button(action: { viewModel.openManualEntry(for: vital); dismiss() }) {
//                    HStack(spacing: AppMetrics.spacing10) {
//                        Image(systemName: "pencil.circle.fill")
//                            .font(.system(size: 20, weight: .semibold))
//                        Text("Enter Manually")
//                            .font(AppTypography.bodyMedium)
//                    }
//                    .foregroundStyle(AppColors.textPrimary)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: AppMetrics.buttonHeight)
//                    .background(AppColors.borderSubtle.opacity(0.4))
//                    .cornerRadius(AppMetrics.radiusMedium)
//                }
//                .buttonStyle(.hapticPlain)
//            }
//
//            if state != .disconnected {
//                Button(action: { viewModel.disconnect(); dismiss() }) {
//                    Text(L10n.Vitals.Device.disconnect)
//                        .font(AppTypography.bodyMedium)
//                        .foregroundStyle(AppColors.statusCritical)
//                }
//                .buttonStyle(.hapticPlain)
//            }
//        }
//    }
//}
