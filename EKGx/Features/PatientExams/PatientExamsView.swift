import SwiftUI

// MARK: - PatientExamsView

struct PatientExamsView: View {

    @State var viewModel: PatientExamsViewModel

    var body: some View {
        @Bindable var vm = viewModel
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                patientCard
                if !viewModel.availableVitalTypes.isEmpty {
                    vitalFilterBar
                }
                examContent
            }
        }
        .onAppear { viewModel.activate() }
        .alert(L10n.PatientExams.Delete.alertTitle, isPresented: $vm.showDeleteConfirm) {
            Button(L10n.PatientExams.Delete.confirm, role: .destructive) { viewModel.deleteConfirmed() }
            Button(L10n.Common.cancel, role: .cancel) { viewModel.cancelDelete() }
        } message: {
            Text(L10n.PatientExams.Delete.message)
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        ZStack {
            Text(L10n.PatientExams.navTitle)
                .font(AppTypography.title2)
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

                // Exam count chip
                Text(L10n.PatientExams.examCountLabel(viewModel.examCount))
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.brandPrimary)
                    .padding(.horizontal, AppMetrics.spacing12)
                    .padding(.vertical, AppMetrics.spacing6)
                    .background(AppColors.brandPrimary.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Patient Card

    private var patientCard: some View {
        HStack(spacing: AppMetrics.spacing16) {
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.18))
                    .frame(width: 52, height: 52)
                Text(viewModel.patient.initials)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.brandPrimary)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(viewModel.patient.fullName)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: AppMetrics.spacing16) {
                    if !viewModel.patient.birthDate.isEmpty {
                        Label("\(viewModel.patient.birthDate) · \(viewModel.patient.age)",
                              systemImage: "calendar")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .labelStyle(ExamsCompactLabelStyle())
                    }
                    if !viewModel.patient.gender.isEmpty {
                        Label(viewModel.patient.genderDisplay, systemImage: "person.fill")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .labelStyle(ExamsCompactLabelStyle())
                    }
                    if let mrn = viewModel.patient.medicalRecordNumber, !mrn.isEmpty {
                        Label("MRN \(mrn)", systemImage: "number")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .labelStyle(ExamsCompactLabelStyle())
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .padding(.vertical, AppMetrics.spacing14)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle()
            .fill(AppColors.borderSubtle.opacity(0.5))
            .frame(height: 1), alignment: .bottom)
    }

    // MARK: - Vital Filter Bar

    private var vitalFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppMetrics.spacing8) {
                FilterPill(label: L10n.PatientExams.filterAll, icon: "square.grid.2x2.fill",
                           isSelected: viewModel.selectedVitalType == nil) {
                    viewModel.selectedVitalType = nil
                }
                ForEach(viewModel.availableVitalTypes) { type in
                    FilterPill(label: type.title, icon: type.icon,
                               isSelected: viewModel.selectedVitalType == type) {
                        viewModel.selectedVitalType = type
                    }
                }
            }
            .padding(.horizontal, AppMetrics.spacing24)
            .padding(.vertical, AppMetrics.spacing10)
        }
        .background(AppColors.surfaceCard)
        .overlay(Rectangle()
            .fill(AppColors.borderSubtle.opacity(0.5))
            .frame(height: 1), alignment: .bottom)
    }

    // MARK: - Exam Content

    @ViewBuilder
    private var examContent: some View {
        let items = viewModel.filteredRecordings
        if items.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: AppMetrics.spacing12) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, record in
                        switch record {
                        case .ekg(let r):
                            EKGExamCard(
                                recording:   r,
                                examNumber:  items.count - index,
                                isUploading: viewModel.uploadingIds.contains(r.id),
                                isLocalMode: viewModel.isLocalMode,
                                onTap:       { viewModel.openRecording(r) },
                                onUpload:    (!viewModel.isLocalMode && r.status != .synced)
                                                 ? { viewModel.uploadRecording(r) }
                                                 : nil,
                                onDelete:    { viewModel.confirmDelete(r) }
                            )
                        case .bp(let r):
                            BPExamCard(
                                recording: r,
                                onDelete:  { viewModel.confirmDeleteBP(r) }
                            )
                        case .spo2(let r):
                            SimpleVitalExamCard(
                                icon: VitalType.oxygenSaturation.icon,
                                color: VitalType.oxygenSaturation.iconColor,
                                title: VitalType.oxygenSaturation.title,
                                value: r.displayValue,
                                date: r.formattedDate,
                                time: r.formattedTime,
                                onDelete: nil
                            )
                        case .temp(let r):
                            SimpleVitalExamCard(
                                icon: VitalType.temperature.icon,
                                color: VitalType.temperature.iconColor,
                                title: VitalType.temperature.title,
                                value: r.displayValue,
                                date: r.formattedDate,
                                time: r.formattedTime,
                                onDelete: nil
                            )
                        case .rr(let r):
                            SimpleVitalExamCard(
                                icon: VitalType.respirations.icon,
                                color: VitalType.respirations.iconColor,
                                title: VitalType.respirations.title,
                                value: r.displayValue,
                                date: r.formattedDate,
                                time: r.formattedTime,
                                onDelete: { viewModel.confirmDeleteRR(r) }
                            )
                        case .pain(let r):
                            SimpleVitalExamCard(
                                icon: VitalType.painLevel.icon,
                                color: VitalType.painLevel.iconColor,
                                title: VitalType.painLevel.title,
                                value: r.displayValue,
                                date: r.formattedDate,
                                time: r.formattedTime,
                                onDelete: { viewModel.confirmDeletePain(r) }
                            )
                        case .weight(let r):
                            SimpleVitalExamCard(
                                icon: VitalType.weight.icon,
                                color: VitalType.weight.iconColor,
                                title: VitalType.weight.title,
                                value: r.displayValue,
                                date: r.formattedDate,
                                time: r.formattedTime,
                                onDelete: { viewModel.confirmDeleteWeight(r) }
                            )
                        case .height(let r):
                            SimpleVitalExamCard(
                                icon: VitalType.height.icon,
                                color: VitalType.height.iconColor,
                                title: VitalType.height.title,
                                value: r.displayValue,
                                date: r.formattedDate,
                                time: r.formattedTime,
                                onDelete: { viewModel.confirmDeleteHeight(r) }
                            )
                        }
                    }
                }
                .padding(.horizontal, AppMetrics.spacing32)
                .padding(.vertical, AppMetrics.spacing24)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppMetrics.spacing16) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(AppColors.textSecondary.opacity(0.3))
            VStack(spacing: AppMetrics.spacing8) {
                Text(L10n.PatientExams.emptyTitle)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.PatientExams.emptySubtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(AppMetrics.spacing48)
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppMetrics.spacing6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(AppTypography.captionBold)
            }
            .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
            .padding(.horizontal, AppMetrics.spacing14)
            .padding(.vertical, AppMetrics.spacing8)
            .background(isSelected ? AppColors.brandPrimary : AppColors.borderSubtle.opacity(0.4))
            .clipShape(Capsule())
        }
        .buttonStyle(.hapticPlain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - EKG Exam Card

private struct EKGExamCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct EKGExamCard: View {

    let recording: ECGRecording
    let examNumber: Int
    let isUploading: Bool
    let isLocalMode: Bool
    let onTap: () -> Void
    let onUpload: (() -> Void)?
    let onDelete: () -> Void

    private var statusColor: Color {
        guard !isLocalMode else { return AppColors.textSecondary }
        switch recording.status {
        case .synced:  return AppColors.statusSuccess
        case .pending: return AppColors.statusWarning
        case .failed:  return AppColors.statusCritical
        }
    }

    private var statusIcon: String {
        isLocalMode ? "internaldrive" : recording.status.systemImage
    }

    private var statusLabel: String {
        isLocalMode ? "Local" : recording.status.label
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppMetrics.spacing20) {

                // Left: EKG icon block
                ZStack {
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .fill(AppColors.brandPrimary.opacity(0.08))
                        .frame(width: 52, height: 52)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppColors.brandPrimary)
                }

                // Center: details
                VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                    HStack(spacing: AppMetrics.spacing10) {
                        Text(L10n.PatientExams.ekgCardTitle)
                            .font(AppTypography.bodySemibold)
                            .foregroundStyle(AppColors.textPrimary)

                        // Status badge
                        HStack(spacing: AppMetrics.spacing4) {
                            Image(systemName: statusIcon)
                                .font(.system(size: 11, weight: .medium))
                            Text(statusLabel)
                                .font(AppTypography.caption)
                        }
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, AppMetrics.spacing8)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.10))
                        .clipShape(Capsule())

                        // Emergency badge
                        if recording.isEmergency {
                            HStack(spacing: 4) {
                                Image(systemName: "cross.case.fill")
                                    .font(.system(size: 9, weight: .medium))
                                Text("Rapid EKG")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(AppColors.statusCritical)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(AppColors.statusCritical.opacity(0.10))
                            .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: AppMetrics.spacing16) {
                        Label(recording.formattedDate, systemImage: "calendar")
                        Label(recording.formattedTime, systemImage: "clock")
                        Label(recording.formattedDuration, systemImage: "timer")
                        if let username = recording.username, !username.isEmpty {
                            Label(username, systemImage: "person")
                        }
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .labelStyle(ExamsCompactLabelStyle())

                    if let diagnosis = recording.diagnosis, !diagnosis.isEmpty {
                        Text(diagnosis)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                            .lineLimit(1)
                            .italic()
                    }
                }

                Spacer()

                // Right: upload button + file size + chevron
                HStack(spacing: AppMetrics.spacing12) {
                    if let onUpload {
                        Button(action: onUpload) {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(statusColor)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .buttonStyle(.hapticPlain)
                        .disabled(isUploading)
                    }

                    VStack(alignment: .trailing, spacing: AppMetrics.spacing6) {
                        Text(recording.formattedFileSize)
                            .font(AppTypography.captionBold)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(recording.appVersion.map { "v\($0)" } ?? "")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                            .lineLimit(1)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.borderSubtle)
                }
            }
            .padding(.horizontal, AppMetrics.spacing24)
            .padding(.vertical, AppMetrics.spacing18)
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(AppColors.borderSubtle.opacity(0.6), lineWidth: AppMetrics.borderWidth)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(EKGExamCardButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Recording", systemImage: "trash")
            }
        }
    }
}

// MARK: - BP Exam Card

private struct BPExamCard: View {

    let recording: BPRecording
    let onDelete:  () -> Void

    private var riskColor: Color {
        switch recording.riskLevel {
        case .normal:      return AppColors.statusSuccess
        case .elevated:    return Color(red: 0.86, green: 0.72, blue: 0.10)
        case .highStage1:  return Color(red: 0.95, green: 0.50, blue: 0.10)
        case .highStage2:  return AppColors.statusCritical
        case .crisis:      return Color(red: 0.65, green: 0.05, blue: 0.05)
        }
    }

    var body: some View {
        HStack(spacing: AppMetrics.spacing20) {

            // Left: icon block with risk-tinted background
            ZStack {
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .fill(riskColor.opacity(0.10))
                    .frame(width: 52, height: 52)
                VStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(riskColor)
                    Text("BP")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(riskColor.opacity(0.9))
                }
            }

            // Center: readings
            VStack(alignment: .leading, spacing: AppMetrics.spacing6) {

                // Main reading + risk badge
                HStack(spacing: AppMetrics.spacing10) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(recording.displayValue)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .contentTransition(.numericText())
                        Text("mmHg")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    HStack(spacing: AppMetrics.spacing4) {
                        Image(systemName: recording.riskLevel.systemImage)
                            .font(.system(size: 11, weight: .medium))
                        Text(recording.riskLevel.label)
                            .font(AppTypography.caption)
                    }
                    .foregroundStyle(riskColor)
                    .padding(.horizontal, AppMetrics.spacing8)
                    .padding(.vertical, 3)
                    .background(riskColor.opacity(0.10))
                    .clipShape(Capsule())
                }

                // Sys / Dia / PR row
                HStack(spacing: AppMetrics.spacing16) {
                    Label("Sys \(recording.systolic)", systemImage: "arrow.up.circle")
                    Label("Dia \(recording.diastolic)", systemImage: "arrow.down.circle")
                    if let pr = recording.pulseRate {
                        Label("\(pr) bpm", systemImage: "waveform.path")
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .labelStyle(ExamsCompactLabelStyle())

                // Arm / Position row
                if recording.arm != nil || recording.position != nil {
                    HStack(spacing: AppMetrics.spacing16) {
                        if let arm = recording.arm {
                            Label("\(arm.fullLabel) Arm", systemImage: "hand.raised")
                        }
                        if let pos = recording.position {
                            Label(pos.label, systemImage: pos.icon)
                        }
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .labelStyle(ExamsCompactLabelStyle())
                }

                // Date / time / user
                HStack(spacing: AppMetrics.spacing16) {
                    Label(recording.formattedDate, systemImage: "calendar")
                    Label(recording.formattedTime, systemImage: "clock")
                    if let username = recording.username, !username.isEmpty {
                        Label(username, systemImage: "person")
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .labelStyle(ExamsCompactLabelStyle())
            }

            Spacer()

            // Right: delete
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.statusCritical.opacity(0.65))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.hapticPlain)
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .padding(.vertical, AppMetrics.spacing18)
        .background(AppColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .strokeBorder(AppColors.borderSubtle.opacity(0.6), lineWidth: AppMetrics.borderWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete BP Reading", systemImage: "trash")
            }
        }
    }
}

// MARK: - Compact Label Style

private struct ExamsCompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: - Simple Vital Exam Card (SpO2, Temp, RR, Pain)

private struct SimpleVitalExamCard: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let date: String
    let time: String
    let onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: AppMetrics.spacing20) {
            ZStack {
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .fill(color.opacity(0.10))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                Text(title)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(value)
                    .font(AppTypography.title3)
                    .foregroundStyle(color)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppMetrics.spacing4) {
                Text(date)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(time)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.statusCritical)
                        .padding(AppMetrics.spacing8)
                        .background(AppColors.statusCritical.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.hapticPlain)
            }
        }
        .padding(.horizontal, AppMetrics.spacing20)
        .padding(.vertical, AppMetrics.spacing14)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppMetrics.radiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .stroke(AppColors.borderSubtle.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Local spacing extension

private extension AppMetrics {
    static let spacing18: CGFloat = 18
}
