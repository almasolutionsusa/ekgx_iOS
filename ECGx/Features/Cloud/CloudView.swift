//
//  CloudView.swift
//  ECGx
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

            // Cloud sync status badge
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
                            PatientRow(
                                patient: patient,
                                isSelected: viewModel.selectedPatient?.id == patient.id
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

private struct PatientRow: View {

    let patient: Patient
    let isSelected: Bool
    let onTap: () -> Void

    private var avatarColor: Color {
        let colors: [Color] = [
            AppColors.brandPrimary, AppColors.brandSecondary,
            AppColors.statusInfo, AppColors.statusSuccess,
            Color(red: 0.45, green: 0.31, blue: 0.82),
            Color(red: 0.90, green: 0.45, blue: 0.20),
        ]
        return colors[abs(patient.id ?? 0) % colors.count]
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppMetrics.spacing12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(isSelected ? 0.25 : 0.12))
                        .frame(width: 40, height: 40)
                    Text(patient.initials)
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(avatarColor)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(patient.fullName)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(isSelected ? AppColors.brandPrimary : AppColors.textPrimary)
                        .lineLimit(1)
                    Text("\(patient.genderDisplay) · \(patient.age)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    if let mrn = patient.medicalRecordNumber {
                        Text(mrn)
                            .font(AppTypography.caption)
                            .foregroundStyle(isSelected ? AppColors.brandPrimary.opacity(0.7) : AppColors.textSecondary.opacity(0.7))
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary)
                }
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.vertical, AppMetrics.spacing14)
            .background(isSelected ? AppColors.brandPrimary.opacity(0.06) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                ForEach(viewModel.recordings) { recording in
                    RecordingRow(recording: recording)
                }
            }
            .padding(.horizontal, AppMetrics.spacing32)
            .padding(.vertical, AppMetrics.spacing24)
        }
    }
}

// MARK: - Recording Row

private struct RecordingRow: View {

    let recording: ECGRecording

    @State private var isPressed = false

    private var statusColor: Color {
        switch recording.status {
        case .synced:  return AppColors.statusSuccess
        case .pending: return AppColors.statusWarning
        case .failed:  return AppColors.statusCritical
        }
    }

    var body: some View {
        Button {
            // TODO: Navigate to ECG viewer
        } label: {
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
                        Text(recording.id)
                            .font(AppTypography.bodySemibold)
                            .foregroundStyle(AppColors.textPrimary)

                        // Status badge
                        HStack(spacing: AppMetrics.spacing4) {
                            Image(systemName: recording.status.systemImage)
                                .font(.system(size: 11, weight: .medium))
                            Text(recording.status.label)
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
                    .labelStyle(CompactLabelStyle())

                    if let notes = recording.notes {
                        Text(notes)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                            .lineLimit(1)
                            .italic()
                    }
                }

                Spacer()

                // Right: file size + chevron
                VStack(alignment: .trailing, spacing: AppMetrics.spacing6) {
                    Text(recording.formattedFileSize)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(recording.technicianName)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary.opacity(0.7))
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppColors.borderSubtle)
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
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
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

private struct CompactLabelStyle: LabelStyle {
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

#Preview {
    let router = AppRouter()
    CloudView(viewModel: CloudViewModel(router: router))
        .environment(router)
}
