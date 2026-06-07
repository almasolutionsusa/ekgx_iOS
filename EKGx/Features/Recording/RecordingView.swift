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
                        .frame(width: 160)
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

            if viewModel.isReconnecting {
                ReconnectingOverlay(
                    attempt: viewModel.reconnectAttempt,
                    maxAttempts: viewModel.maxReconnectAttempts
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

            if viewModel.showConnectSheet {
                RecordingConnectOverlay(viewModel: viewModel)
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
        VStack(spacing: 0) {
            // Pickers
            VStack(spacing: AppMetrics.spacing12) {
                leadLayoutSection
                panelDivider
                durationSection
            }
            .padding(.horizontal, AppMetrics.spacing12)
            .padding(.top, AppMetrics.spacing14)

            Spacer()

            // Progress indicator
            if viewModel.recordingState == .recording {
                Group {
                    if viewModel.selectedDuration == .continuous {
                        continuousTimer
                    } else {
                        progressRing
                    }
                }
                .padding(.bottom, AppMetrics.spacing8)
            }

            Spacer()

            // Action buttons
            VStack(spacing: AppMetrics.spacing8) {
                resetButton
                recordButton
                if let name = viewModel.connectedDeviceName {
                    Text(name)
                        .font(.system(size: 9))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, AppMetrics.spacing12)
            .padding(.bottom, AppMetrics.spacing14)
        }
        .background(AppColors.surfaceCard)
        .overlay(Rectangle().fill(AppColors.borderSubtle.opacity(0.5)).frame(width: 1), alignment: .leading)
    }

    private var panelDivider: some View {
        Rectangle()
            .fill(AppColors.borderSubtle.opacity(0.6))
            .frame(height: 1)
    }

    private var leadLayoutSection: some View {
        controlSection(title: L10n.Recording.Controls.leadLayout) {
            VStack(spacing: AppMetrics.spacing6) {
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
            VStack(spacing: AppMetrics.spacing6) {
                ForEach(RecordingDuration.allCases, id: \.self) { duration in
                    controlChip(title: duration.rawValue, isSelected: viewModel.selectedDuration == duration) {
                        viewModel.selectedDuration = duration
                    }
                }
            }
        }
    }

    private var resetButton: some View {
        Button {
            viewModel.resetRecording()
            viewModel.startRecording()
        } label: {
            HStack(spacing: AppMetrics.spacing6) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 11, weight: .semibold))
                Text(L10n.Recording.Controls.reset)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(AppColors.surfaceBackground)
            .cornerRadius(AppMetrics.radiusSmall)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusSmall)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.recordingState == .idle)
        .opacity(viewModel.recordingState == .idle ? 0.4 : 1)
    }

    private var recordButton: some View {
        Button {
            switch viewModel.recordingState {
            case .idle:      viewModel.startRecording()
            case .recording: viewModel.stopRecording()
            case .done:      viewModel.showPreviewSheet = true
            }
        } label: {
            HStack(spacing: AppMetrics.spacing6) {
                Image(systemName: recordButtonIcon)
                    .font(.system(size: 11, weight: .semibold))
                Text(recordButtonLabel)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(recordButtonColor)
            .cornerRadius(AppMetrics.radiusSmall)
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

    private var continuousTimer: some View {
        VStack(spacing: AppMetrics.spacing2) {
            Text(viewModel.elapsedFormatted)
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
            Text(L10n.Recording.Controls.elapsed)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(width: 64, height: 64)
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(AppColors.borderSubtle, lineWidth: 3)
            Circle()
                .trim(from: 0, to: viewModel.progressFraction)
                .stroke(AppColors.brandPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.progressFraction)
            VStack(spacing: 1) {
                Text(viewModel.elapsedFormatted)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
                Text(L10n.Recording.Controls.elapsed)
                    .font(.system(size: 9))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(width: 64, height: 64)
    }

    private func controlSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.5)
                .textCase(.uppercase)
            content()
        }
    }

    private func controlChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppColors.brandPrimary : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(isSelected ? AppColors.brandPrimary.opacity(0.1) : Color.clear)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isSelected ? AppColors.brandPrimary.opacity(0.4) : AppColors.borderSubtle.opacity(0.6),
                            lineWidth: 1
                        )
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Reconnecting Overlay

private struct ReconnectingOverlay: View {

    let attempt: Int
    let maxAttempts: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing20) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.statusWarning)

                ProgressView()
                    .scaleEffect(1.4)
                    .tint(AppColors.brandPrimary)

                Text(L10n.Recording.Reconnecting.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)

                Text(L10n.Recording.Reconnecting.subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                if attempt > 0 {
                    Text(L10n.Recording.Reconnecting.attempt(attempt, of: maxAttempts))
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textSecondary)

                    HStack(spacing: AppMetrics.spacing8) {
                        ForEach(1...maxAttempts, id: \.self) { i in
                            Circle()
                                .fill(i <= attempt ? AppColors.brandPrimary : AppColors.borderSubtle)
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: attempt)
                        }
                    }
                }
            }
            .padding(AppMetrics.spacing24 + 4)
            .background(AppColors.surfaceCard)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.25), radius: 24)
            .padding(.horizontal, 60)
        }
    }
}

// MARK: - Device Disconnected Overlay

private struct DeviceDisconnectedOverlay: View {

    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing20) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.statusCritical)

                Text(L10n.Recording.DeviceDisconnected.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)

                Text(L10n.Recording.DeviceDisconnected.subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppMetrics.spacing8)

                Button(L10n.Recording.DeviceDisconnected.button, action: onDismiss)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textOnDark)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(AppColors.brandPrimary)
                    .cornerRadius(AppMetrics.radiusMedium)
            }
            .padding(28)
            .background(AppColors.surfaceCard)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Device Connect Overlay

private struct RecordingConnectOverlay: View {

    let viewModel: RecordingViewModel

    private var state: DeviceConnectionState { viewModel.connectSheetState }

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing32) {
                header
                statusBlock
            }
            .padding(AppMetrics.spacing32)
            .frame(width: 400)
            .background(AppColors.surfaceCard)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.25), radius: 24)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Connect Device")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Connect an EKG device to start recording.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button(action: viewModel.cancelConnect) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var statusBlock: some View {
        VStack(spacing: AppMetrics.spacing16) {
            DeviceConnectButton(state: state) {
                if state == .disconnected { viewModel.connectDevice() }
            }
            .frame(maxWidth: .infinity)

            if let name = viewModel.connectSheetDeviceName {
                Label(name, systemImage: "checkmark.seal.fill")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.statusSuccess)
            }

            Button(L10n.Common.cancel, action: viewModel.cancelConnect)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
                .buttonStyle(.plain)
                .padding(.top, AppMetrics.spacing4)
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
