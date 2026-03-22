//
//  RecordingView.swift
//  EKGx
//
//  Full-screen ECG recording screen — landscape iPad kiosk layout.
//
//  ┌──────────────────────────────────────────────────────────────────────────┐
//  │  [← Back]  [Patient Info]  [HR ♥]  [Timer]          [Date/Time]         │
//  ├────────────────────────────────────────────┬─────────────────────────────┤
//  │                                            │  Layout picker              │
//  │           ECG Waveform View                │  Duration picker            │
//  │                                            │  ─────────────────          │
//  │                                            │  [Reset]  [● Record/Stop]   │
//  └────────────────────────────────────────────┴─────────────────────────────┘
//

import SwiftUI

// MARK: - RecordingView

struct RecordingView: View {

    @State private var viewModel: RecordingViewModel

    init(viewModel: RecordingViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RecordingNavBar(viewModel: viewModel)
                    .zIndex(1)

                HStack(spacing: 0) {
                    waveformPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    RecordingControlsPanel(viewModel: viewModel)
                        .frame(width: 220)
                }
            }

            if viewModel.showExitConfirmation {
                ExitConfirmationOverlay(
                    onKeep: { viewModel.showExitConfirmation = false },
                    onDiscard: { viewModel.confirmExit() }
                )
            }

            if viewModel.showPreviewSheet {
                RecordingDoneOverlay(
                    patient: viewModel.patient,
                    elapsedFormatted: viewModel.elapsedFormatted,
                    onRedo: {
                        viewModel.resetRecording()
                        viewModel.startRecording()
                    },
                    onAnalysis: { viewModel.proceedToAnalysis() }
                )
            }

            if viewModel.showDeviceDisconnected {
                DeviceDisconnectedOverlay(
                    onDismiss: {
                        viewModel.showDeviceDisconnected = false
                        viewModel.confirmExit()
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.activate() }
        .onDisappear { viewModel.deactivate() }
    }

    private var waveformPanel: some View {
        ZStack {
            Color.black
            EKGRealtimeView(viewModel: viewModel)
        }
    }
}

// MARK: - Navigation Bar

private struct RecordingNavBar: View {

    let viewModel: RecordingViewModel
    @State private var pulseHeart = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            backButton
            Spacer()
            patientInfo
            Spacer()
            statsRow
            Spacer()
            LiveClockView()
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var backButton: some View {
        Button {
            if viewModel.recordingState == .recording {
                viewModel.showExitConfirmation = true
            } else {
                viewModel.confirmExit()
            }
        } label: {
            HStack(spacing: AppMetrics.spacing8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text(L10n.Recording.Nav.backButton)
                    .font(AppTypography.callout)
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppMetrics.spacing16)
            .padding(.vertical, AppMetrics.spacing8)
            .background(AppColors.borderSubtle.opacity(0.5))
            .cornerRadius(AppMetrics.radiusMedium)
        }
        .buttonStyle(.plain)
    }

    private var patientInfo: some View {
        HStack(spacing: AppMetrics.spacing12) {
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(viewModel.patient.initials)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.brandPrimary)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing2) {
                Text(viewModel.patient.fullName)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                HStack(spacing: AppMetrics.spacing8) {
                    Text(viewModel.patient.age)
                    Text("·")
                    Text(viewModel.patient.genderDisplay)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: AppMetrics.spacing24) {
            heartRateStat
            timerStat
            if let battery = viewModel.batteryLevel {
                batteryStat(battery)
            }
        }
    }

    private var heartRateStat: some View {
        HStack(spacing: AppMetrics.spacing6) {
            Image(systemName: "heart.fill")
                .foregroundStyle(AppColors.statusCritical)
                .opacity(pulseHeart ? 1 : 0.4)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                           value: pulseHeart)
                .onAppear { pulseHeart = viewModel.recordingState == .recording }
                .onChange(of: viewModel.recordingState) { _, state in
                    pulseHeart = state == .recording
                }

            Text("\(viewModel.heartRate)")
                .font(AppTypography.bodySemibold)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
            Text(L10n.Recording.Stats.bpm)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func batteryStat(_ level: Int) -> some View {
        HStack(spacing: AppMetrics.spacing6) {
            Image(systemName: batteryIcon(level))
                .foregroundStyle(level <= 20 ? AppColors.statusCritical : AppColors.statusSuccess)
            Text("\(level)%")
                .font(AppTypography.bodySemibold)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
        }
    }

    private func batteryIcon(_ level: Int) -> String {
        switch level {
        case 0..<15:  return "battery.0percent"
        case 15..<40: return "battery.25percent"
        case 40..<65: return "battery.50percent"
        case 65..<90: return "battery.75percent"
        default:      return "battery.100percent"
        }
    }

    private var timerStat: some View {
        HStack(spacing: AppMetrics.spacing6) {
            Circle()
                .fill(viewModel.recordingState == .recording
                      ? AppColors.statusCritical
                      : AppColors.textSecondary)
                .frame(width: 8, height: 8)
                .opacity(pulseHeart ? 1 : 0.3)

            Text(viewModel.elapsedFormatted)
                .font(AppTypography.bodySemibold)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()

            if viewModel.selectedDuration != .continuous {
                Text("/ \(viewModel.durationFormatted)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Controls Panel

private struct RecordingControlsPanel: View {

    let viewModel: RecordingViewModel

    var body: some View {
        VStack(spacing: AppMetrics.spacing20) {
            leadLayoutSection
            durationSection
            Spacer()
            if viewModel.recordingState == .recording,
               viewModel.selectedDuration != .continuous {
                progressRing
            }
            Spacer()
            actionButtons
        }
        .padding(AppMetrics.spacing16)
        .background(AppColors.surfaceCard)
    }

    private var leadLayoutSection: some View {
        controlSection(title: L10n.Recording.Controls.leadLayout) {
            VStack(spacing: AppMetrics.spacing8) {
                ForEach(ECGLeadLayout.allCases, id: \.self) { layout in
                    controlChip(title: layout.rawValue, isSelected: viewModel.selectedLayout == layout) {
                        viewModel.selectedLayout = layout
                    }
                }
            }
        }
    }

    private var durationSection: some View {
        controlSection(title: L10n.Recording.Controls.duration) {
            VStack(spacing: AppMetrics.spacing8) {
                ForEach(RecordingDuration.allCases.filter { $0 != .continuous }, id: \.self) { duration in
                    controlChip(title: duration.rawValue, isSelected: viewModel.selectedDuration == duration) {
                        viewModel.selectedDuration = duration
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: AppMetrics.spacing12) {
            resetButton
            recordButton
        }
    }

    private var resetButton: some View {
        Button {
            viewModel.resetRecording()
            viewModel.startRecording()
        } label: {
            Label(L10n.Recording.Controls.reset, systemImage: "arrow.counterclockwise")
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppColors.surfaceCard)
                .cornerRadius(AppMetrics.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.recordingState == .idle)
    }

    private var recordButton: some View {
        Button {
            switch viewModel.recordingState {
            case .idle:      viewModel.startRecording()
            case .recording: viewModel.stopRecording()
            case .done:      viewModel.showPreviewSheet = true
            }
        } label: {
            HStack(spacing: AppMetrics.spacing8) {
                Image(systemName: recordButtonIcon)
                    .font(.system(size: 14, weight: .semibold))
                Text(recordButtonLabel)
                    .font(AppTypography.captionBold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(recordButtonColor)
            .cornerRadius(AppMetrics.radiusMedium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: viewModel.recordingState)
    }

    private var recordButtonIcon: String {
        switch viewModel.recordingState {
        case .idle:      return "record.circle"
        case .recording: return "stop.circle.fill"
        case .done:      return "eye.fill"
        }
    }

    private var recordButtonLabel: String {
        switch viewModel.recordingState {
        case .idle:      return L10n.Recording.Controls.record
        case .recording: return L10n.Recording.Controls.stop
        case .done:      return L10n.Recording.Controls.viewResult
        }
    }

    private var recordButtonColor: Color {
        switch viewModel.recordingState {
        case .idle:      return AppColors.brandPrimary
        case .recording: return AppColors.statusCritical
        case .done:      return AppColors.statusSuccess
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(AppColors.borderSubtle, lineWidth: 4)
            Circle()
                .trim(from: 0, to: viewModel.progressFraction)
                .stroke(AppColors.brandPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.progressFraction)
            VStack(spacing: AppMetrics.spacing2) {
                Text(viewModel.elapsedFormatted)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
                Text(L10n.Recording.Controls.elapsed)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(width: 80, height: 80)
    }

    private func controlSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
            Text(title)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
            content()
        }
    }

    private func controlChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.captionBold)
                .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isSelected ? AppColors.brandPrimary : AppColors.surfaceBackground)
                .cornerRadius(AppMetrics.radiusSmall)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Device Disconnected Overlay

private struct DeviceDisconnectedOverlay: View {

    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.statusCritical)

                Text(L10n.Recording.DeviceDisconnected.title)
                    .font(AppTypography.title2)
                    .foregroundColor(.black)

                Text(L10n.Recording.DeviceDisconnected.subtitle)
                    .font(AppTypography.callout)
                    .foregroundColor(Color(UIColor.darkGray))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Button(L10n.Recording.DeviceDisconnected.button, action: onDismiss)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppColors.brandPrimary)
                    .cornerRadius(AppMetrics.radiusMedium)
            }
            .padding(28)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Preview

#Preview {
    let router = AppRouter()
    let container = AppDIContainer()
    let patient = Patient.mockPatients[0]
    let service = DemoDeviceService()
    service.connect()
    return RecordingView(viewModel: RecordingViewModel(
        patient: patient,
        deviceService: service,
        router: router,
        diContainer: container
    ))
    .environment(router)
}
