import SwiftUI

struct PhoneVitalsLayout: View {
    @Bindable var viewModel: VitalsViewModel
    @Binding var pendingRR: Int?
    @Binding var savedRR: Int?

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                phoneNavBar
                phonePatientCard
                phoneScrollContent
            }
        }
        .sheet(isPresented: $viewModel.showHeightPicker) {
            HeightSheet(currentCm: viewModel.heightCm) { cm, display in
                viewModel.saveHeight(cm, display: display)
            }
            .presentationBackground(AppColors.surfaceBackground)
            .presentationDetents([.large])
        }
        .sheet(isPresented: $viewModel.showWeightPopover) {
            WeightScanSheet(viewModel: viewModel)
                .presentationBackground(AppColors.surfaceBackground)
                .presentationDetents([.large])
        }
    }

    // MARK: - Nav Bar

    private var phoneNavBar: some View {
        ZStack {
            AppImages.logo
                .resizable()
                .scaledToFit()
                .frame(height: 25)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button(action: viewModel.navigateBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(AppColors.borderSubtle.opacity(0.5))
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)

                Spacer()

                Button(action: viewModel.openExams) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(AppColors.borderSubtle.opacity(0.5))
                            .cornerRadius(AppMetrics.radiusMedium)

                        if viewModel.examCount > 0 {
                            Text("\(viewModel.examCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(AppColors.brandPrimary)
                                .clipShape(Circle())
                                .offset(x: 5, y: -5)
                        }
                    }
                }
                .buttonStyle(.hapticPlain)
            }
        }
        .padding(.horizontal, AppMetrics.spacing16)
        .frame(height: 52)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Patient Card

    private var phonePatientCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.surfaceBackground)
                        .frame(width: 40, height: 40)
                    Text(viewModel.patient.initials)
                        .font(AppTypography.phoneBodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.patient.fullName)
                        .font(AppTypography.phoneBodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        if !viewModel.patient.birthDate.isEmpty {
                            Text("\(viewModel.patient.birthDate) · \(viewModel.patient.age)")
                                .font(AppTypography.phoneCaption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if !viewModel.patient.gender.isEmpty {
                            Label(viewModel.patient.genderDisplay, systemImage: viewModel.patient.genderIcon)
                                .font(AppTypography.phoneCaption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if let mrn = viewModel.patient.medicalRecordNumber, !mrn.isEmpty {
                            Label(L10n.Vitals.mrnLabel(mrn), systemImage: "number")
                                .font(AppTypography.phoneCaption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .lineLimit(1)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                phoneMetricPill(
                    icon: VitalType.height.icon,
                    value: viewModel.heightDisplay,
                    placeholder: L10n.Vitals.Height.title,
                    color: VitalType.height.iconColor,
                    action: viewModel.openHeight
                )
                phoneMetricPill(
                    icon: VitalType.weight.icon,
                    value: viewModel.weightDisplay,
                    placeholder: L10n.Vitals.Weight.title,
                    color: VitalType.weight.iconColor,
                    action: viewModel.openWeightScanSheet
                )
                Spacer()
            }
        }
        .padding(.horizontal, AppMetrics.spacing16)
        .padding(.vertical, AppMetrics.spacing10)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)
    }

    private func phoneMetricPill(
        icon: String,
        value: String?,
        placeholder: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                Text(value ?? placeholder)
                    .font(.system(size: 14, weight: value != nil ? .semibold : .regular))
                    .foregroundStyle(value != nil ? AppColors.textPrimary : AppColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppColors.surfaceBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.hapticPlain)
    }

    // MARK: - Scroll Content

    private var phoneScrollContent: some View {
        ScrollView {
            VStack(spacing: AppMetrics.spacing8) {
                // EKG — hero card, full width, prominent
                VitalCard(
                    type: .ekg,
                    state: viewModel.connectionState(for: .ekg),
                    isDemoMode: viewModel.isDemoMode,
                    source: nil,
                    onTap: { viewModel.startEKG() },
                    onConnectTap: { viewModel.startConnect(for: .ekg) },
                    onLongPress: { viewModel.startConnect(for: .ekg) }
                )
                .frame(height: 200)

                // BP — full width, clinically critical
                bpCard
                    .frame(height: 210)

                // SpO2 | HR
                HStack(spacing: AppMetrics.spacing8) {
                    phoneGridCard(for: .oxygenSaturation)
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                    phoneGridCard(for: .heartRate)
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                }

                // Temp | RR
                HStack(spacing: AppMetrics.spacing8) {
                    phoneGridCard(for: .temperature)
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                    phoneGridCard(for: .respirations)
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .overlay { rrOverlay }
                }

                // Pain Level | Echo
                HStack(spacing: AppMetrics.spacing8) {
                    phoneGridCard(for: .painLevel)
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                    VitalCard(
                        type: .echo,
                        state: viewModel.connectionState(for: .echo),
                        source: cardSource(for: .echo),
                        onTap: { handleTap(.echo) },
                        onConnectTap: { viewModel.startConnect(for: .echo) },
                        onLongPress: { viewModel.startConnect(for: .echo) }
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 190)
                }
            }
            .padding(AppMetrics.spacing8)
        }
    }

    // MARK: - BP Card

    private var bpCard: some View {
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
    }

    // MARK: - Grid Card

    @ViewBuilder
    private func phoneGridCard(for type: VitalType) -> some View {
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
            onSaveSpO2:    type == .oxygenSaturation ? { viewModel.saveSpO2Reading() } : nil,
            spo2SaveState: viewModel.spo2SaveState,
            spo2HasReading: type == .oxygenSaturation && viewModel.hasCompleteSpO2Reading,
            onSaveTemp:    type == .temperature ? { viewModel.saveTempReading() } : nil,
            tempSaveState: viewModel.tempSaveState,
            tempHasReading: type == .temperature && viewModel.hasCompleteTempReading,
            onManualEntry: [.oxygenSaturation, .temperature, .heartRate].contains(type)
                ? { viewModel.openManualEntry(for: type) } : nil
        )
    }

    // MARK: - RR Overlay

    private var rrOverlay: some View {
        ZStack(alignment: .bottomTrailing) {
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

            if let pending = pendingRR {
                let isSaved = pending == savedRR
                let bgColor = isSaved ? AppColors.statusSuccess : AppColors.brandPrimary
                Button {
                    viewModel.saveRR(pending)
                    savedRR = pending
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isSaved ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(isSaved ? L10n.Vitals.rrSaved : L10n.Vitals.rrSave)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(AppColors.ecgBackground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(bgColor))
                    .shadow(color: bgColor.opacity(0.40), radius: 6, x: 0, y: 3)
                    .animation(.easeInOut(duration: 0.2), value: isSaved)
                }
                .buttonStyle(.hapticPlain)
                .disabled(isSaved)
                .padding(.bottom, 8)
                .padding(.trailing, 8)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity),
                    removal:   .scale(scale: 0.6, anchor: .bottomTrailing).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.2), value: isSaved)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func handleTap(_ type: VitalType) {
        switch type {
        case .ekg:       viewModel.startEKG()
        case .painLevel: break
        case .height:    viewModel.openHeight()
        case .weight:    break
        default:
            if type.requiresDevice, viewModel.connectionState(for: type) == .disconnected {
                viewModel.startConnect(for: type)
            }
        }
    }

    private func cardValue(for type: VitalType) -> String? {
        switch type {
        case .height:           return viewModel.heightDisplay
        case .weight:           return viewModel.measurements[.weight]?.displayValue
        case .oxygenSaturation: return viewModel.measurements[.oxygenSaturation].map { $0.displayValue + "%" }
        case .respirations:     return pendingRR.map { "\($0)" } ?? viewModel.measurements[.respirations]?.displayValue
        default:                return viewModel.measurements[type]?.displayValue
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
            if let fat = m.bodyFatPercent { return L10n.Vitals.Weight.bodyFat(fat) }
            return viewModel.connectedDeviceName(for: .weight) ?? "Scale"
        default:
            guard viewModel.measurements[type] != nil else { return nil }
            if viewModel.manualEntryVitals.contains(type) { return L10n.Vitals.sourceManual }
            return type.shortName
        }
    }
}
