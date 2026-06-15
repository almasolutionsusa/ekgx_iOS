import SwiftUI

// MARK: - PatientExamsView

struct PatientExamsView: View {

    @State var viewModel: PatientExamsViewModel
    @State private var showCustomDatePicker = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

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
                dateFilterBar
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
                .font(isCompact ? .system(size: 17, weight: .semibold) : AppTypography.title2)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button(action: viewModel.navigateBack) {
                    if isCompact {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(AppColors.borderSubtle.opacity(0.5))
                            .cornerRadius(AppMetrics.radiusMedium)
                    } else {
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
                }
                .buttonStyle(.hapticPlain)
                Spacer()
                Text(L10n.PatientExams.examCountLabel(viewModel.examCount))
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.brandPrimary)
                    .padding(.horizontal, AppMetrics.spacing12)
                    .padding(.vertical, AppMetrics.spacing6)
                    .background(AppColors.brandPrimary.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing32)
        .frame(height: isCompact ? 52 : AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Patient Card

    private var patientCard: some View {
        HStack(spacing: isCompact ? AppMetrics.spacing12 : AppMetrics.spacing16) {
            let avatarSize: CGFloat = isCompact ? 40 : 52
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.18))
                    .frame(width: avatarSize, height: avatarSize)
                Text(viewModel.patient.initials)
                    .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.title3)
                    .foregroundStyle(AppColors.brandPrimary)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(viewModel.patient.fullName)
                    .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                if isCompact {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: AppMetrics.spacing10) {
                            if !viewModel.patient.birthDate.isEmpty {
                                Label("\(viewModel.patient.birthDate) · \(viewModel.patient.age)", systemImage: "calendar")
                                    .font(AppTypography.phoneCaption)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .labelStyle(ExamsCompactLabelStyle())
                            }
                            if !viewModel.patient.gender.isEmpty {
                                Label(viewModel.patient.genderDisplay, systemImage: "person.fill")
                                    .font(AppTypography.phoneCaption)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .labelStyle(ExamsCompactLabelStyle())
                            }
                        }
                        if let mrn = viewModel.patient.medicalRecordNumber, !mrn.isEmpty {
                            Label(L10n.PatientExams.mrnLabel(mrn), systemImage: "number")
                                .font(AppTypography.phoneCaption)
                                .foregroundStyle(AppColors.textSecondary)
                                .labelStyle(ExamsCompactLabelStyle())
                        }
                    }
                } else {
                    HStack(spacing: AppMetrics.spacing16) {
                        if !viewModel.patient.birthDate.isEmpty {
                            Label("\(viewModel.patient.birthDate) · \(viewModel.patient.age)", systemImage: "calendar")
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
                            Label(L10n.PatientExams.mrnLabel(mrn), systemImage: "number")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .labelStyle(ExamsCompactLabelStyle())
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing24)
        .padding(.vertical, isCompact ? AppMetrics.spacing10 : AppMetrics.spacing14)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Vital Filter Bar

    private var vitalFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppMetrics.spacing8) {
                ExamFilterPill(label: L10n.PatientExams.filterAll, icon: "square.grid.2x2.fill",
                               isSelected: viewModel.selectedVitalType == nil) {
                    viewModel.selectedVitalType = nil
                }
                ForEach(viewModel.availableVitalTypes) { type in
                    ExamFilterPill(label: type.title, icon: type.icon,
                                   isSelected: viewModel.selectedVitalType == type) {
                        viewModel.selectedVitalType = type
                    }
                }
            }
            .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing24)
            .padding(.vertical, AppMetrics.spacing10)
        }
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Date Filter Bar

    private var dateFilterBar: some View {
        @Bindable var vm = viewModel
        return VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppMetrics.spacing8) {
                    let presets: [DateRangeFilter] = [.all, .today, .last7Days, .last30Days]
                    ForEach(presets, id: \.label) { filter in
                        ExamFilterPill(label: filter.label, icon: filter.icon,
                                       isSelected: viewModel.dateFilter == filter) {
                            viewModel.dateFilter = filter
                            showCustomDatePicker = false
                        }
                    }
                    ExamFilterPill(
                        label: L10n.PatientExams.filterCustom,
                        icon: "slider.horizontal.3",
                        isSelected: { if case .custom = viewModel.dateFilter { return true }; return false }()
                    ) {
                        showCustomDatePicker.toggle()
                        if case .custom = viewModel.dateFilter { } else {
                            viewModel.dateFilter = .custom(from: viewModel.customFromDate, to: viewModel.customToDate)
                        }
                    }
                }
                .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing24)
                .padding(.vertical, AppMetrics.spacing10)
            }
            .background(AppColors.surfaceCard)
            .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.4)).frame(height: 1), alignment: .bottom)

            if showCustomDatePicker {
                DateRangePickerPanel(
                    fromDate: $vm.customFromDate,
                    toDate: $vm.customToDate
                ) {
                    viewModel.dateFilter = .custom(from: viewModel.customFromDate, to: viewModel.customToDate)
                    showCustomDatePicker = false
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCustomDatePicker)
    }

    // MARK: - Exam Content

    @ViewBuilder
    private var examContent: some View {
        let items = viewModel.filteredRecordings
        if items.isEmpty {
            emptyState
        } else if isCompact {
            compactExamList
        } else {
            regularExamList
        }
    }

    private var compactExamList: some View {
        let items = viewModel.filteredRecordings
        let total = items.count
        return List {
            ForEach(items.indices, id: \.self) { index in
                examCard(for: items[index], index: index, total: total)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive, action: deleteAction(for: items[index])) {
                            Label(L10n.PatientExams.Delete.confirm, systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.surfaceBackground)
    }

    private var regularExamList: some View {
        ScrollView {
            LazyVStack(spacing: AppMetrics.spacing12) {
                ForEach(Array(viewModel.filteredRecordings.enumerated()), id: \.element.id) { index, record in
                    examCard(for: record, index: index, total: viewModel.filteredRecordings.count)
                }
            }
            .padding(.horizontal, AppMetrics.spacing32)
            .padding(.vertical, AppMetrics.spacing24)
        }
    }

    private func deleteAction(for record: ExamRecord) -> () -> Void {
        switch record {
        case .ekg(let r):    return { viewModel.confirmDelete(r) }
        case .bp(let r):     return { viewModel.confirmDeleteBP(r) }
        case .spo2(let r):   return { viewModel.confirmDeleteSpO2(r) }
        case .temp(let r):   return { viewModel.confirmDeleteTemp(r) }
        case .rr(let r):     return { viewModel.confirmDeleteRR(r) }
        case .pain(let r):   return { viewModel.confirmDeletePain(r) }
        case .weight(let r): return { viewModel.confirmDeleteWeight(r) }
        case .height(let r): return { viewModel.confirmDeleteHeight(r) }
        }
    }

    @ViewBuilder
    private func examCard(for record: ExamRecord, index: Int, total: Int) -> some View {
        switch record {
        case .ekg(let r):
            EKGExamCard(
                recording:   r,
                examNumber:  total - index,
                isUploading: viewModel.uploadingIds.contains(r.id),
                isLocalMode: viewModel.isLocalMode,
                onTap:       { viewModel.openRecording(r) },
                onUpload:    (!viewModel.isLocalMode && r.status != .synced) ? { viewModel.uploadRecording(r) } : nil,
                onDelete:    { viewModel.confirmDelete(r) }
            )
        case .bp(let r):
            BPExamCard(recording: r, onDelete: { viewModel.confirmDeleteBP(r) })
        case .spo2(let r):
            SimpleVitalExamCard(type: .oxygenSaturation, value: r.displayValue,
                                date: r.formattedDate, time: r.formattedTime,
                                onDelete: { viewModel.confirmDeleteSpO2(r) })
        case .temp(let r):
            SimpleVitalExamCard(type: .temperature, value: r.displayValue,
                                date: r.formattedDate, time: r.formattedTime,
                                onDelete: { viewModel.confirmDeleteTemp(r) })
        case .rr(let r):
            SimpleVitalExamCard(type: .respirations, value: r.displayValue,
                                date: r.formattedDate, time: r.formattedTime,
                                onDelete: { viewModel.confirmDeleteRR(r) })
        case .pain(let r):
            SimpleVitalExamCard(type: .painLevel, value: r.displayValue,
                                date: r.formattedDate, time: r.formattedTime,
                                onDelete: { viewModel.confirmDeletePain(r) })
        case .weight(let r):
            SimpleVitalExamCard(type: .weight, value: r.displayValue,
                                date: r.formattedDate, time: r.formattedTime,
                                onDelete: { viewModel.confirmDeleteWeight(r) })
        case .height(let r):
            SimpleVitalExamCard(type: .height, value: r.displayValue,
                                date: r.formattedDate, time: r.formattedTime,
                                onDelete: { viewModel.confirmDeleteHeight(r) })
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppMetrics.spacing16) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: isCompact ? 48 : 56, weight: .light))
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
        .padding(isCompact ? AppMetrics.spacing32 : AppMetrics.spacing48)
    }
}

// MARK: - Date Range Picker Panel

private struct DateRangePickerPanel: View {
    @Binding var fromDate: Date
    @Binding var toDate: Date
    let onApply: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        Group {
            if isCompact { compactLayout } else { regularLayout }
        }
        .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing24)
        .padding(.vertical, AppMetrics.spacing12)
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.4)).frame(height: 1), alignment: .bottom)
    }

    private var compactLayout: some View {
        VStack(spacing: AppMetrics.spacing10) {
            HStack(spacing: AppMetrics.spacing20) {
                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(L10n.PatientExams.Date.from)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    DatePicker("", selection: $fromDate, in: ...toDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(AppColors.brandPrimary)
                }
                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(L10n.PatientExams.Date.to)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    DatePicker("", selection: $toDate, in: fromDate..., displayedComponents: .date)
                        .labelsHidden()
                        .tint(AppColors.brandPrimary)
                }
                Spacer()
            }
            HStack {
                Spacer()
                Button(action: onApply) {
                    Text(L10n.PatientExams.Date.apply)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppMetrics.spacing16)
                        .padding(.vertical, AppMetrics.spacing8)
                        .background(AppColors.brandPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.hapticPlain)
            }
        }
    }

    private var regularLayout: some View {
        HStack(spacing: AppMetrics.spacing24) {
            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(L10n.PatientExams.Date.from)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                DatePicker("", selection: $fromDate, in: ...toDate, displayedComponents: .date)
                    .labelsHidden()
                    .tint(AppColors.brandPrimary)
            }
            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(L10n.PatientExams.Date.to)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                DatePicker("", selection: $toDate, in: fromDate..., displayedComponents: .date)
                    .labelsHidden()
                    .tint(AppColors.brandPrimary)
            }
            Spacer()
            Button(action: onApply) {
                Text(L10n.PatientExams.Date.apply)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppMetrics.spacing16)
                    .padding(.vertical, AppMetrics.spacing8)
                    .background(AppColors.brandPrimary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.hapticPlain)
        }
    }
}

// MARK: - Filter Pill

private struct ExamFilterPill: View {
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

// MARK: - Shared Card Components

private struct ExamCardShell<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(AppColors.borderSubtle.opacity(0.6), lineWidth: AppMetrics.borderWidth)
            )
            .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

private struct ExamIconBlock: View {
    let systemImage: String
    let color: Color
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                .fill(color.opacity(0.10))
                .frame(width: size, height: size)
            Image(systemName: systemImage)
                .font(.system(size: size < 52 ? 18 : 22, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

private struct ExamMetaRow: View {
    let date: String
    let time: String
    let username: String?
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        HStack(spacing: sizeClass == .compact ? AppMetrics.spacing10 : AppMetrics.spacing16) {
            Label(date, systemImage: "calendar")
            Label(time, systemImage: "clock")
            if let username, !username.isEmpty, sizeClass != .compact {
                Label(username, systemImage: "person")
            }
        }
        .font(sizeClass == .compact ? AppTypography.phoneCaption : AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .labelStyle(ExamsCompactLabelStyle())
    }
}

private struct ExamDeleteButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "trash")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.statusCritical.opacity(0.65))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.hapticPlain)
    }
}

// MARK: - EKG Exam Card

private struct EKGExamCard: View {

    let recording: ECGRecording
    let examNumber: Int
    let isUploading: Bool
    let isLocalMode: Bool
    let onTap: () -> Void
    let onUpload: (() -> Void)?
    let onDelete: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    private var statusColor: Color {
        guard !isLocalMode else { return AppColors.textSecondary }
        switch recording.status {
        case .synced:  return AppColors.statusSuccess
        case .pending: return AppColors.statusWarning
        case .failed:  return AppColors.statusCritical
        }
    }

    private var statusIcon: String  { isLocalMode ? "internaldrive" : recording.status.systemImage }
    private var statusLabel: String { isLocalMode ? L10n.PatientExams.statusLocal : recording.status.label }

    var body: some View {
        Button(action: onTap) {
            ExamCardShell {
                if isCompact { compactContent } else { regularContent }
            }
        }
        .buttonStyle(ExamCardButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label(L10n.PatientExams.Delete.contextMenu, systemImage: "trash")
            }
        }
    }

    private var regularContent: some View {
        HStack(spacing: AppMetrics.spacing20) {
            ExamIconBlock(systemImage: "waveform.path.ecg", color: AppColors.brandPrimary)

            VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                HStack(spacing: AppMetrics.spacing8) {
                    Text(L10n.PatientExams.ekgCardTitle)
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.textPrimary)
                    ExamStatusBadge(icon: statusIcon, label: statusLabel, color: statusColor)
                    if recording.isEmergency {
                        ExamStatusBadge(icon: "cross.case.fill", label: L10n.PatientExams.rapidEkg, color: AppColors.statusCritical)
                    }
                }
                ExamMetaRow(date: recording.formattedDate, time: recording.formattedTime, username: recording.username)
                if let diagnosis = recording.diagnosis, !diagnosis.isEmpty {
                    Text(diagnosis)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                        .lineLimit(1)
                        .italic()
                }
            }

            Spacer()

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
                VStack(alignment: .trailing, spacing: AppMetrics.spacing4) {
                    Text(recording.formattedFileSize)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textSecondary)
                    if let v = recording.appVersion {
                        Text(L10n.PatientExams.ekgVersion(v))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.borderSubtle)
            }
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .padding(.vertical, AppMetrics.spacing18)
    }

    private var compactEmergencyDot: some View {
        ExamStatusDot(color: AppColors.statusCritical)
            .opacity(recording.isEmergency ? 1 : 0)
    }

    private var compactContent: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing12) {
            ExamIconBlock(systemImage: "waveform.path.ecg", color: AppColors.brandPrimary, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppMetrics.spacing6) {
                    Text(L10n.PatientExams.ekgCardTitle)
                        .font(AppTypography.phoneBodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    ExamStatusDot(color: statusColor)
                    compactEmergencyDot
                }

                if let diagnosis = recording.diagnosis, !diagnosis.isEmpty {
                    Text(diagnosis)
                        .font(AppTypography.phoneCaption)
                        .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                        .lineLimit(1)
                        .italic()
                }

                HStack(spacing: AppMetrics.spacing8) {
                    if let onUpload {
                        Button(action: onUpload) {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                                    .frame(width: 18, height: 18)
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(statusColor)
                            }
                        }
                        .buttonStyle(.hapticPlain)
                        .disabled(isUploading)
                    }
                    Text(recording.formattedFileSize)
                        .font(AppTypography.phoneCaption)
                        .foregroundStyle(AppColors.textSecondary)
                    if let v = recording.appVersion {
                        Text(L10n.PatientExams.ekgVersion(v))
                            .font(AppTypography.phoneCaption)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(recording.formattedDate)
                    .font(AppTypography.phoneCaption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(recording.formattedTime)
                    .font(AppTypography.phoneCaption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.borderSubtle)
        }
        .padding(.horizontal, AppMetrics.spacing16)
        .padding(.vertical, AppMetrics.spacing14)
    }
}

// MARK: - BP Exam Card

private struct BPExamCard: View {

    let recording: BPRecording
    let onDelete: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    private var riskColor: Color {
        switch recording.riskLevel {
        case .normal:      return AppColors.statusSuccess
        case .elevated:    return AppColors.statusWarning
        case .highStage1:  return Color(red: 0.95, green: 0.50, blue: 0.10)
        case .highStage2:  return AppColors.statusCritical
        case .crisis:      return Color(red: 0.65, green: 0.05, blue: 0.05)
        }
    }

    var body: some View {
        ExamCardShell {
            Group {
                if isCompact { compactContent } else { regularContent }
            }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label(L10n.PatientExams.Delete.bpReading, systemImage: "trash")
            }
        }
    }

    private var compactContent: some View {
        HStack(spacing: AppMetrics.spacing12) {
            ExamIconBlock(systemImage: "heart.fill", color: riskColor, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppMetrics.spacing6) {
                    Text(VitalType.bloodPressure.title)
                        .font(AppTypography.phoneBodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    ExamStatusDot(color: riskColor)
                }
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(recording.displayValue)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .contentTransition(.numericText())
                    Text(L10n.PatientExams.BP.unit)
                        .font(AppTypography.phoneCaption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                if recording.arm != nil || recording.position != nil {
                    HStack(spacing: AppMetrics.spacing8) {
                        if let arm = recording.arm { Label(arm.fullLabel, systemImage: "hand.raised") }
                        if let pos = recording.position { Label(pos.label, systemImage: pos.icon) }
                    }
                    .font(AppTypography.phoneCaption)
                    .foregroundStyle(AppColors.textSecondary)
                    .labelStyle(ExamsCompactLabelStyle())
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(recording.formattedDate)
                    .font(AppTypography.phoneCaption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(recording.formattedTime)
                    .font(AppTypography.phoneCaption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppMetrics.spacing16)
        .padding(.vertical, AppMetrics.spacing14)
    }

    private var regularContent: some View {
        HStack(spacing: AppMetrics.spacing20) {
            ExamIconBlock(systemImage: "heart.fill", color: riskColor, size: 52)

            VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                Text(VitalType.bloodPressure.title)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: AppMetrics.spacing10) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(recording.displayValue)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .contentTransition(.numericText())
                        Text(L10n.PatientExams.BP.unit)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    ExamStatusBadge(icon: recording.riskLevel.systemImage,
                                    label: recording.riskLevel.label,
                                    color: riskColor)
                }
                if recording.arm != nil || recording.position != nil {
                    HStack(spacing: AppMetrics.spacing16) {
                        if let arm = recording.arm {
                            Label(L10n.PatientExams.BP.arm(arm.fullLabel), systemImage: "hand.raised")
                        }
                        if let pos = recording.position { Label(pos.label, systemImage: pos.icon) }
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .labelStyle(ExamsCompactLabelStyle())
                }
                ExamMetaRow(date: recording.formattedDate,
                            time: recording.formattedTime,
                            username: recording.username)
            }

            Spacer()

            ExamDeleteButton(action: onDelete)
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .padding(.vertical, AppMetrics.spacing18)
    }
}

// MARK: - Simple Vital Exam Card

private struct SimpleVitalExamCard: View {
    let type: VitalType
    let value: String
    let date: String
    let time: String
    let onDelete: (() -> Void)?
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        ExamCardShell {
            HStack(spacing: isCompact ? AppMetrics.spacing12 : AppMetrics.spacing20) {
                ExamIconBlock(systemImage: type.icon, color: type.iconColor, size: isCompact ? 44 : 52)

                VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                    Text(type.title)
                        .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(isCompact ? 0.85 : 1.0)
                    Text(value)
                        .font(isCompact ? .system(size: 18, weight: .bold) : AppTypography.title3)
                        .foregroundStyle(type.iconColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppMetrics.spacing4) {
                    Text(date)
                        .font(isCompact ? AppTypography.phoneCaption : AppTypography.captionBold)
                        .fontWeight(isCompact ? .semibold : nil)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(time)
                        .font(AppTypography.phoneCaption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                if let onDelete, !isCompact {
                    ExamDeleteButton(action: onDelete)
                }
            }
            .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing20)
            .padding(.vertical, isCompact ? AppMetrics.spacing12 : AppMetrics.spacing14)
        }
    }
}

// MARK: - Status Badge

private struct ExamStatusBadge: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: AppMetrics.spacing4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(label)
                .font(AppTypography.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppMetrics.spacing8)
        .padding(.vertical, 3)
        .background(color.opacity(0.10))
        .clipShape(Capsule())
    }
}

private struct ExamStatusDot: View {
    let color: Color
    var body: some View {
        Circle().fill(color).frame(width: 8, height: 8)
    }
}

// MARK: - Supporting Styles

private struct ExamsCompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

private struct ExamCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Local spacing extension

private extension AppMetrics {
    static let spacing18: CGFloat = 18
}
