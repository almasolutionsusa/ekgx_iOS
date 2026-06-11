import SwiftUI

// MARK: - BP Arm & Position

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

// MARK: - BP History Item

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

// MARK: - Save Capsule Button

struct SaveCapsuleButton: View {
    let isSaved: Bool
    let hasReading: Bool
    let saveText: String
    let savedText: String
    let action: () -> Void

    var body: some View {
        if hasReading || isSaved {
            Button(action: action) {
                HStack(spacing: 5) {
                    Image(systemName: isSaved ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(isSaved ? savedText : saveText)
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(AppColors.ecgBackground)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(isSaved ? AppColors.statusSuccess : AppColors.brandPrimary))
                .shadow(
                    color: (isSaved ? AppColors.statusSuccess : AppColors.brandPrimary).opacity(0.40),
                    radius: 6, x: 0, y: 3
                )
            }
            .buttonStyle(.hapticPlain)
            .disabled(isSaved)
            .padding(.bottom, 12)
            .padding(.trailing, 12)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity),
                removal:   .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity)
            ))
        }
    }
}

// MARK: - Vital Card

struct VitalCard: View {

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
        }
        .padding(.vertical, 6)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(duration: 0.35), value: bpHistory.count)
    }

    // MARK: - Dedicated BP card

    private var bpCardContent: some View {
        let parsed = bpParsed
        let vc = bpValueColor
        return ZStack(alignment: .topLeading) {
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
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(bpArm == arm ? .white : AppColors.textSecondary)
                                    .frame(width: 50, height: 50)
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
                                .frame(width: 50, height: 50)
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

            VStack {
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

            // Source text + manual entry pencil
            if let source, selectedValue != nil {
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 5) {
                        Text(L10n.Vitals.sourceLabel(source))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(type.iconColor.opacity(0.7))
                        if let onManualEntry {
                            Button(action: onManualEntry) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                            }
                            .buttonStyle(.hapticPlain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, AppMetrics.spacing8)
                }
            }
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
                            Text(L10n.Vitals.Device.tapToConnect)
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
                SaveCapsuleButton(
                    isSaved: bpSaveState == .saved,
                    hasReading: bpHasReading,
                    saveText: L10n.Vitals.BP.saveReading,
                    savedText: L10n.Vitals.BP.saved,
                    action: { onSave?() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .animation(.spring(response: 0.45, dampingFraction: 0.65), value: bpHasReading || bpSaveState == .saved)
                .animation(.spring(duration: 0.35), value: bpSaveState)
            }

            // SpO2 save button
            if type == .oxygenSaturation {
                SaveCapsuleButton(
                    isSaved: spo2SaveState == .saved,
                    hasReading: spo2HasReading,
                    saveText: L10n.Vitals.SpO2.saveReading,
                    savedText: L10n.Vitals.SpO2.saved,
                    action: { onSaveSpO2?() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .animation(.spring(response: 0.45, dampingFraction: 0.65), value: spo2HasReading || spo2SaveState == .saved)
                .animation(.spring(duration: 0.35), value: spo2SaveState)
            }

            // Temp save button
            if type == .temperature {
                SaveCapsuleButton(
                    isSaved: tempSaveState == .saved,
                    hasReading: tempHasReading,
                    saveText: L10n.Vitals.Temp.saveReading,
                    savedText: L10n.Vitals.Temp.saved,
                    action: { onSaveTemp?() }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .animation(.spring(response: 0.45, dampingFraction: 0.65), value: tempHasReading || tempSaveState == .saved)
                .animation(.spring(duration: 0.35), value: tempSaveState)
            }

            // Manual entry pencil — shown at bottom-center only when source row is not visible
            let sourceVisible = source != nil && selectedValue != nil && !(type == .weight && bodyFatPercent != nil)
            if let onManualEntry, !sourceVisible {
                Button(action: onManualEntry) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.hapticPlain)
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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

    // MARK: - Monitor Card (non-BP vitals)

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
                                Text(L10n.Vitals.Weight.bodyFat(fat))
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
                    HStack(spacing: 5) {
                        Text(L10n.Vitals.sourceLabel(source))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(type.iconColor.opacity(0.7))
                        if let onManualEntry {
                            Button(action: onManualEntry) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                            }
                            .buttonStyle(.hapticPlain)
                        }
                    }
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

    // MARK: - EKG Wide Card

    private var ekgCardContent: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(type.shortName)
                        .font(.system(size: 17, weight: .semibold))
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

    // MARK: - Echo Wide Card

    private var echoCardContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text(type.shortName)
                    .font(.system(size: 17, weight: .semibold))
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

            HStack(alignment: .bottom, spacing: 3) {
                Image("ELogo").resizable().scaledToFit().frame(height: 30)
                Text(type.shortName.dropFirst())
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.textPrimary)
                    .offset(y: 10)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Pain Level Card

    private var painCardContent: some View {
        VStack(spacing: 0) {
            // Header label
            HStack {
                Text(type.shortName)
                    .font(.system(size: 17, weight: .semibold))
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
            .padding(.bottom, 12)

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
