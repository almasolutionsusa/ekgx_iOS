//
//  CloudView.swift
//  EKGx
//
//  Cloud & Reports — iPad landscape master-detail layout.
//
//  ┌────────────────┬───────────────────────────────────────────────────────┐
//  │  PATIENTS      │  ECG RECORDINGS — James Hartwell                      │
//  │  ─────────     │  ──────────────────────────────────────────────────── │
//  │  🔍 Search     │  REC-0001  ·  Jan 12 2025  ·  12-lead  ·  Synced ✓  │
//  │                │  REC-0002  ·  Dec 08 2024  ·  12-lead  ·  Pending    │
//  │  James H.   ▶  │  ...                                                  │
//  │  Margaret S.   │                                                        │
//  │  Robert N.     │                                                        │
//  └────────────────┴───────────────────────────────────────────────────────┘
//

import SwiftUI

// MARK: - CloudView

struct CloudView: View {

    @State private var viewModel: CloudViewModel

    init(viewModel: CloudViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                CloudNavBar(viewModel: viewModel)

                HStack(spacing: 0) {
                    // ── LEFT: Patient list panel
                    PatientPanel(viewModel: viewModel)
                        .frame(width: 300)

                    // Divider
                    Rectangle()
                        .fill(AppColors.borderSubtle.opacity(0.6))
                        .frame(width: 1)
                        .ignoresSafeArea(edges: .bottom)

                    // ── RIGHT: ECG recordings panel
                    RecordingsPanel(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { viewModel.activate() }
    }
}

// MARK: - Nav Bar

private struct CloudNavBar: View {

    let viewModel: CloudViewModel

    var body: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing16) {
            Button(action: { viewModel.navigateBack() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text(L10n.Home.Nav.menuButton)
                        .font(AppTypography.callout)
                }
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppMetrics.spacing16)
                .padding(.vertical, AppMetrics.spacing8)
                .background(AppColors.borderSubtle.opacity(0.5))
                .cornerRadius(AppMetrics.radiusMedium)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Cloud.Nav.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Cloud.Nav.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Cloud sync status / offline badge
            if viewModel.isLocalMode {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.statusWarning)
                    Text("Offline Mode")
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.statusWarning)
                }
                .padding(.horizontal, AppMetrics.spacing14)
                .padding(.vertical, AppMetrics.spacing8)
                .background(AppColors.statusWarning.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(AppColors.statusWarning.opacity(0.25), lineWidth: 1)
                )
            } else {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "checkmark.icloud.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppColors.statusSuccess)
                    Text(L10n.Cloud.Nav.allSynced)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.statusSuccess)
                }
                .padding(.horizontal, AppMetrics.spacing14)
                .padding(.vertical, AppMetrics.spacing8)
                .background(AppColors.statusSuccess.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(AppColors.statusSuccess.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Patient Panel (left)

private struct PatientPanel: View {

    @Bindable var viewModel: CloudViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            VStack(alignment: .leading, spacing: AppMetrics.spacing12) {
                Text(L10n.Cloud.Patients.header)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)

                // Search
                CloudSearchBar(
                    query: $viewModel.searchQuery,
                    onClear: { viewModel.clearSearch() }
                )
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.top, AppMetrics.spacing20)
            .padding(.bottom, AppMetrics.spacing16)

            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.5))
                .frame(height: 1)

            // Patient rows
            if viewModel.filteredPatients.isEmpty {
                Spacer()
                VStack(spacing: AppMetrics.spacing12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.4))
                    Text(L10n.Cloud.Patients.emptyTitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            } else {
                ScrollView { 
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.filteredPatients) { patient in
                            CloudPatientRow(
                                patient: patient,
                                isSelected: viewModel.selectedPatient?.patientId == patient.patientId
                            ) {
                                viewModel.selectPatient(patient)
                            }

                            Rectangle()
                                .fill(AppColors.borderSubtle.opacity(0.4))
                                .frame(height: 1)
                                .padding(.leading, AppMetrics.spacing20)
                        }
                    }
                }
            }
        }
        .background(AppColors.surfaceCard)
    }
}

// MARK: - Patient Row

private struct CloudPatientRow: View {

    let patient: Patient
    let isSelected: Bool
    let onTap: () -> Void

    private var avatarColor: Color {
        let colors: [Color] = [
            AppColors.brandPrimary, AppColors.brandSecondary,
            AppColors.statusInfo, AppColors.statusSuccess,
            AppColors.accentViolet,
            AppColors.statusWarning,
        ]
        return colors[abs(patient.id ?? 0) % colors.count]
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Left accent bar
                Rectangle()
                    .fill(isSelected ? AppColors.brandPrimary : Color.clear)
                    .frame(width: 4)

                HStack(spacing: AppMetrics.spacing12) {
                    // Avatar — filled when selected
                    ZStack {
                        Circle()
                            .fill(isSelected ? avatarColor : avatarColor.opacity(0.12))
                            .frame(width: 42, height: 42)
                        Text(patient.initials)
                            .font(.custom("Montserrat-SemiBold", size: 15))
                            .foregroundStyle(isSelected ? .white : avatarColor)
                    }

                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                        Text(patient.fullName)
                            .font(isSelected ? AppTypography.bodySemibold : AppTypography.bodyMedium)
                            .foregroundStyle(isSelected ? AppColors.brandPrimary : AppColors.textPrimary)
                            .lineLimit(1)
                        Text("\(patient.genderDisplay) · \(patient.age)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        if let mrn = patient.medicalRecordNumber {
                            Text("# \(mrn)")
                                .font(AppTypography.caption)
                                .foregroundStyle(isSelected ? AppColors.brandPrimary.opacity(0.8) : AppColors.textSecondary.opacity(0.7))
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? AppColors.brandPrimary : AppColors.borderSubtle)
                }
                .padding(.horizontal, AppMetrics.spacing16)
                .padding(.vertical, AppMetrics.spacing14)
            }
            .background(isSelected ? AppColors.brandPrimary.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.hapticPlain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Recordings Panel (right)

private struct RecordingsPanel: View {

    let viewModel: CloudViewModel

    var body: some View {
        Group {
            if let patient = viewModel.selectedPatient {
                selectedPatientRecordings(patient: patient)
            } else {
                emptySelectionState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surfaceBackground)
    }

    // MARK: - No selection

    private var emptySelectionState: some View {
        VStack(spacing: AppMetrics.spacing20) {
            Image(systemName: "person.crop.rectangle.stack")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(AppColors.brandPrimary.opacity(0.25))

            VStack(spacing: AppMetrics.spacing8) {
                Text(L10n.Cloud.Recordings.selectTitle)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Cloud.Recordings.selectSubtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }
        }
    }

    // MARK: - Patient recordings

    @ViewBuilder
    private func selectedPatientRecordings(patient: Patient) -> some View {
        VStack(spacing: 0) {
            // Sub-header
            HStack(alignment: .center, spacing: AppMetrics.spacing16) {
                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(patient.fullName)
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.textPrimary)
                    HStack(spacing: AppMetrics.spacing8) {
                        if let mrn = patient.medicalRecordNumber {
                            Text(mrn)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Text("·")
                            .foregroundStyle(AppColors.borderSubtle)
                        Text("\(patient.genderDisplay) · \(patient.age)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                Spacer()

                // Recording count badge
                if !viewModel.isLoadingRecordings {
                    Text("\(viewModel.recordings.count) \(viewModel.recordings.count == 1 ? L10n.Cloud.Recordings.examSingular : L10n.Cloud.Recordings.examPlural)")
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.brandPrimary)
                        .padding(.horizontal, AppMetrics.spacing12)
                        .padding(.vertical, AppMetrics.spacing6)
                        .background(AppColors.brandPrimary.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, AppMetrics.spacing32)
            .padding(.vertical, AppMetrics.spacing20)
            .background(AppColors.surfaceCard)

            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.5))
                .frame(height: 1)

            // Content
            if viewModel.isLoadingRecordings {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                    .scaleEffect(1.3)
                Spacer()
            } else if viewModel.recordings.isEmpty {
                Spacer()
                VStack(spacing: AppMetrics.spacing16) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.3))
                    Text(L10n.Cloud.Recordings.emptyTitle)
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.Cloud.Recordings.emptySubtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
            } else {
                recordingsList
            }
        }
    }

    // MARK: - Recordings list

    private var recordingsList: some View {
        ScrollView {
            LazyVStack(spacing: AppMetrics.spacing12) {
                ForEach(Array(viewModel.recordings.enumerated()), id: \.element.id) { index, recording in
                    RecordingRow(
                        recording: recording,
                        examNumber: viewModel.recordings.count - index,
                        isUploading: viewModel.uploadingIds.contains(recording.id),
                        isLocalMode: viewModel.isLocalMode,
                        onTap: { viewModel.openRecording(recording) },
                        onUpload: (!viewModel.isLocalMode && recording.status != .synced)
                            ? { viewModel.uploadRecording(recording) }
                            : nil,
                        onDelete: { viewModel.deleteRecording(recording) }
                    )
                }
            }
            .padding(.horizontal, AppMetrics.spacing32)
            .padding(.vertical, AppMetrics.spacing24)
        }
    }
}

// MARK: - Recording Row

private struct RecordingRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct RecordingRow: View {

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

                // Left: ECG icon
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
                        Text("Exam #\(examNumber)")
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
                        .background(statusColor.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    HStack(spacing: AppMetrics.spacing16) {
                        Label(recording.formattedDate, systemImage: "calendar")
                        Label(recording.formattedTime, systemImage: "clock")
                        Label(recording.formattedDuration, systemImage: "timer")
                        Label("\(recording.leadCount)-lead", systemImage: "waveform")
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .labelStyle(CloudCompactLabelStyle())

                    HStack(spacing: AppMetrics.spacing16) {
                        if let diagnosis = recording.diagnosis {
                            Text(diagnosis)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                                .lineLimit(1)
                                .italic()
                        }
                        if let username = recording.username {
                            Label(username, systemImage: "person")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                                .labelStyle(CloudCompactLabelStyle())
                        }
                    }
                }

                Spacer()

                // Right: upload button (pending/failed) + file size + chevron
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
        }
        .buttonStyle(RecordingRowButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Recording", systemImage: "trash")
            }
        }
    }
}

// MARK: - Cloud Search Bar

private struct CloudSearchBar: View {

    @Binding var query: String
    let onClear: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AppMetrics.spacing8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isFocused ? AppColors.brandPrimary : AppColors.textSecondary)

            TextField(L10n.Cloud.Patients.searchPH, text: $query)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textPrimary)
                .focused($isFocused)
                .submitLabel(.search)

            if !query.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppMetrics.spacing12)
        .frame(height: 40)
        .background(AppColors.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                .strokeBorder(
                    isFocused ? AppColors.borderFocused : AppColors.borderSubtle,
                    lineWidth: isFocused ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Compact Label Style

private struct CloudCompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: - AppMetrics extension

private extension AppMetrics {
    static let spacing18: CGFloat = 18
}

// MARK: - Preview
//
//#Preview {
//    let router = AppRouter()
//    CloudView(viewModel: CloudViewModel(router: router))
//        .environment(router)
//}
