import SwiftUI

// MARK: - Shared Sheet Helpers

func sheetHeader(title: String, icon: String, color: Color, onClose: @escaping () -> Void) -> some View {
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

func saveButton(label: String, action: @escaping () -> Void) -> some View {
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

// MARK: - Height Sheet

struct HeightSheet: View {

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

                sheetHeader(title: L10n.Vitals.Height.title, icon: "ruler.fill",
                            color: VitalType.height.iconColor, onClose: { dismiss() })

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

                saveButton(label: L10n.Vitals.Height.save, action: { onSave(valueInCm, displayString) })
            }
        }
    }
}

// MARK: - Weight Sheet

struct WeightSheet: View {

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

                sheetHeader(title: L10n.Vitals.Weight.title, icon: "scalemass",
                            color: VitalType.weight.iconColor, onClose: { dismiss() })

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

                saveButton(label: L10n.Vitals.Weight.save, action: { onSave(valueInKg, displayString) })
            }
        }
    }
}

// MARK: - Weight Scan Sheet (BLE + Manual combined)

struct WeightScanSheet: View {

    @State var viewModel: VitalsViewModel
    @State private var unit: WeightUnit = {
        if let raw = UserDefaults.standard.string(forKey: "app.weightUnit"),
           let v = WeightUnit(rawValue: raw) { return v }
        return .imperial
    }()
    @State private var weightText: String = ""
    @FocusState private var isWeightFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var state: DeviceConnectionState { viewModel.connectionState(for: .weight) }
    private var isBusy: Bool { state == .searching || state == .connecting }
    private var bleReading: VitalMeasurement? { viewModel.measurements[.weight] }

    private var weightValue: Double? {
        Double(weightText.filter { $0.isNumber || $0 == "." })
            .flatMap { $0 > 0 ? $0 : nil }
    }
    private var rawValue: Double  { weightValue ?? 0 }
    private var displayString: String {
        guard let v = weightValue else { return "" }
        return unit == .imperial ? String(format: "%.1f lbs", v) : String(format: "%.1f kg", v)
    }

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

                    // BLE Section
                    bleSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    Divider()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                    // Manual Entry Section
                    VStack(spacing: 16) {

                        // Weight input field
                        HStack(spacing: AppMetrics.spacing10) {
                            Image(systemName: "scalemass")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(isWeightFocused ? AppColors.brandPrimary : AppColors.textSecondary)

                            TextField("0", text: $weightText)
                                .keyboardType(.decimalPad)
                                .focused($isWeightFocused)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textPrimary)
                                .tint(AppColors.brandPrimary)

                            Text(unit == .imperial ? L10n.Vitals.Weight.unitImperial : L10n.Vitals.Weight.unitMetric)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)

                            if !weightText.isEmpty {
                                Button { weightText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                .buttonStyle(.hapticPlain)
                            }
                        }
                        .padding(.horizontal, AppMetrics.spacing14)
                        .frame(height: AppMetrics.buttonHeight)
                        .background(AppColors.surfaceCard)
                        .cornerRadius(AppMetrics.radiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                                .strokeBorder(
                                    isWeightFocused ? AppColors.borderFocused : AppColors.borderSubtle,
                                    lineWidth: isWeightFocused ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                                )
                        )
                        .animation(.easeInOut(duration: 0.15), value: isWeightFocused)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    saveButton(label: L10n.Vitals.Weight.save) {
                        guard weightValue != nil else { return }
                        viewModel.saveWeight(rawValue, unit: unit.rawValue, display: displayString)
                        dismiss()
                    }
                }
            }
        }
        // BLE measurement auto-populates the field
        .onChange(of: viewModel.measurements[.weight]?.displayValue) { _, newValue in
            guard let str = newValue, let measured = Double(str) else { return }
            let inUnit = unit == .imperial ? measured * 2.2046 : measured
            weightText = String(format: "%.1f", inUnit)
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
        case .connected:    return L10n.Vitals.Device.connected
        case .searching:    return L10n.Vitals.Device.scanning
        case .connecting:   return L10n.Vitals.Device.connecting
        case .disconnected: return L10n.Vitals.Device.searchingScale
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

struct ManualBPSheet: View {
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
                sheetHeader(title: L10n.Vitals.BP.title, icon: VitalType.bloodPressure.icon,
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
                    Text(L10n.Vitals.BP.unit)
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
                                .background(arm == a
                                    ? VitalType.bloodPressure.iconColor.opacity(0.8)
                                    : AppColors.borderSubtle.opacity(0.4))
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
                                .background(position == p
                                    ? VitalType.bloodPressure.iconColor.opacity(0.8)
                                    : AppColors.borderSubtle.opacity(0.4))
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
                        Text(L10n.Vitals.BP.sys)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.textSecondary)
                            .tracking(1)
                        Picker(L10n.Vitals.BP.sys, selection: $systolic) {
                            ForEach(60...250, id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                    }
                    VStack(spacing: 2) {
                        Text(L10n.Vitals.BP.dia)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppColors.textSecondary)
                            .tracking(1)
                        Picker(L10n.Vitals.BP.dia, selection: $diastolic) {
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
                    Label(L10n.Vitals.BP.includePulseRate, systemImage: "heart.fill")
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
                saveButton(label: L10n.Vitals.BP.saveReading) {
                    onSave(systolic, diastolic, includePR ? pulseRate : nil)
                }
            }
        }
    }
}

// MARK: - Manual SpO2 Sheet

struct ManualSpO2Sheet: View {
    @State private var spo2:      Int = 98
    @State private var includePR: Bool = false
    @State private var pulseRate: Int = 72
    @Environment(\.dismiss) private var dismiss
    let onSave: (Int, Int?) -> Void

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                sheetHeader(title: L10n.Vitals.SpO2.title, icon: VitalType.oxygenSaturation.icon,
                            color: VitalType.oxygenSaturation.iconColor, onClose: { dismiss() })

                Text("\(spo2)%")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(VitalType.oxygenSaturation.iconColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: spo2)
                    .padding(.vertical, 10)

                Picker(L10n.Vitals.SpO2.title, selection: $spo2) {
                    ForEach(50...100, id: \.self) { Text("\($0) %").font(.system(size: 33)).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 140)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusLarge)
                .padding(.horizontal, 24)

                Toggle(isOn: $includePR.animation()) {
                    Label(L10n.Vitals.BP.includePulseRate, systemImage: "heart.fill")
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
                saveButton(label: L10n.Vitals.SpO2.saveReading) {
                    onSave(spo2, includePR ? pulseRate : nil)
                }
            }
        }
    }
}

// MARK: - Manual Temp Sheet

struct ManualTempSheet: View {

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
                sheetHeader(title: L10n.Vitals.Temp.title, icon: VitalType.temperature.icon,
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
                saveButton(label: L10n.Vitals.Temp.saveReading) {
                    onSave(displayValue, displayUnit)
                }
            }
        }
    }
}

// MARK: - Manual PR Sheet

struct ManualPRSheet: View {
    @State private var bpm: Int = 72
    @Environment(\.dismiss) private var dismiss
    let onSave: (Int) -> Void

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                sheetHeader(title: L10n.Vitals.HR.title, icon: VitalType.heartRate.icon,
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
                    Text(L10n.Vitals.BP.bpm.uppercased())
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.vertical, 10)

                Picker(L10n.Vitals.HR.title, selection: $bpm) {
                    ForEach(30...250, id: \.self) { Text("\($0) bpm").font(.system(size: 33)).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusLarge)
                .padding(.horizontal, 24)

                Spacer(minLength: 16)
                saveButton(label: L10n.Vitals.HR.saveReading) {
                    onSave(bpm)
                }
            }
        }
    }
}
