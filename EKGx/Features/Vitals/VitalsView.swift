import SwiftUI

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

    // MARK: - Helpers

    private func handleTap(_ type: VitalType) {
        switch type {
        case .ekg:          viewModel.startEKG()
        case .painLevel:    break
        case .height:       viewModel.openHeight()
        case .weight:       break
        default:
            if type.requiresDevice, viewModel.connectionState(for: type) == .disconnected {
                viewModel.startConnect(for: type)
            }
        }
    }

    private func cardValue(for type: VitalType) -> String? {
        switch type {
        case .height:            return viewModel.heightDisplay
        case .weight:            return viewModel.measurements[.weight]?.displayValue
        case .oxygenSaturation:  return viewModel.measurements[.oxygenSaturation].map { $0.displayValue + "%" }
        default:                 return viewModel.measurements[type]?.displayValue
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
