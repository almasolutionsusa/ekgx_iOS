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
import AVFoundation
import AVKit

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

                ZStack {
                    waveformPanel
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    RecordingControlsPanel(viewModel: viewModel)
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
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        if isCompact { compactLayout } else { regularLayout }
    }

    // MARK: Regular (iPad) layout

    private var regularLayout: some View {
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

    // MARK: Compact (iPhone) layout

    private var compactLayout: some View {
        HStack(alignment: .center, spacing: 8) {
            backButton

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.patient.fullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text(viewModel.patient.age)
                    Text("·")
                    Text(viewModel.patient.genderDisplay)
                }
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            compactHeartPill
            compactTimerPill
            if let battery = viewModel.batteryLevel {
                compactBatteryPill(battery)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(AppColors.surfaceCard)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var compactHeartPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.statusCritical)
                .opacity(pulseHeart ? 1 : 0.4)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulseHeart)
                .onAppear { pulseHeart = viewModel.recordingState == .recording }
                .onChange(of: viewModel.recordingState) { _, state in pulseHeart = state == .recording }
            Text("\(viewModel.heartRate)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(AppColors.borderSubtle.opacity(0.4))
        .clipShape(Capsule())
    }

    private var compactTimerPill: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.recordingState == .recording ? AppColors.statusCritical : AppColors.textSecondary)
                .frame(width: 6, height: 6)
                .opacity(pulseHeart ? 1 : 0.3)
            Text(viewModel.elapsedFormatted)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
            if viewModel.selectedDuration != .continuous {
                Text("/ \(viewModel.durationFormatted)")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(AppColors.borderSubtle.opacity(0.4))
        .clipShape(Capsule())
    }

    private func compactBatteryPill(_ level: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: batteryIcon(level))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(level <= 20 ? AppColors.statusCritical : AppColors.statusSuccess)
            Text("\(level)%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(AppColors.borderSubtle.opacity(0.4))
        .clipShape(Capsule())
    }

    // MARK: Shared back button

    private var backButton: some View {
        Button {
            if viewModel.recordingState == .recording {
                viewModel.showExitConfirmation = true
            } else {
                viewModel.confirmExit()
            }
        } label: {
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
        }
        .buttonStyle(.hapticPlain)
    }

    // MARK: iPad-only subviews

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

    @State private var showLayoutPicker   = false
    @State private var showDurationPicker = false
    @State private var showVideoSheet     = false

    // Beep
    @State private var isBeeping:  Bool = false
    @State private var beepPlayer: AVAudioPlayer?
    @State private var beepTimer:  Timer?
    private let beepGap: TimeInterval = 1.5

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    // Adaptive frosted-glass surface: white tint on dark canvas, dark tint on light canvas.
    private var floatingSurface: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.25)
    }
    private var floatingBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.18)
    }

    // Adaptive sizing for compact (iPhone) vs regular (iPad)
    private var iconFont:       Font    { isCompact ? .system(size: 14)                : .title3 }
    private var ctrlFont:       Font    { isCompact ? .system(size: 13, weight: .bold) : .title3.weight(.bold) }
    private var btnCornerLarge: CGFloat { isCompact ? 10 : 14 }
    private var btnCornerSmall: CGFloat { isCompact ? 9  : 12 }
    private var outerPad:       CGFloat { isCompact ? 10 : 14 }
    private var topPad:         CGFloat { isCompact ? 12 : 20 }

    var body: some View {
        GeometryReader { geo in
            let shortSide  = min(geo.size.width, geo.size.height)
            let btnSize    = min(shortSide * 0.12, isCompact ? 40.0 : 60.0)
            let createW    = max(shortSide * 0.15, btnSize * 2.2)
            // Divide by actual duration count so chips never underflow on narrow screens
            let durCount   = CGFloat(RecordingDuration.allCases.count)
            let chipW      = max(0.0, (shortSide * 0.30 - (durCount - 1) * 4.0) / durCount)

            ZStack {
                // ── TOP-RIGHT: layout picker + beep + reset ──────────────
                VStack(alignment: .trailing, spacing: isCompact ? 6 : 12) {
                    layoutGroup(size: btnSize)
                    beepBtn(size: btnSize)
                    resetBtn(size: btnSize)
                }
                .padding(.top, topPad)
                .padding(.trailing, outerPad)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                // ── BOTTOM-RIGHT: video + duration + record/stop ─────────
                VStack(alignment: .trailing, spacing: isCompact ? 6 : 8) {
                    videoBtn(size: btnSize)
                    durationGroup(btnSize: btnSize, chipW: chipW)
                    createButton(size: btnSize, width: createW)
                }
                .padding(.bottom, outerPad)
                .padding(.trailing, outerPad)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Force dark appearance: the waveform canvas is always black,
        // so all AppColors tokens must resolve their dark variants here.
        .environment(\.colorScheme, .dark)
        .animation(.easeInOut(duration: 0.25), value: viewModel.recordingState)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showLayoutPicker)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDurationPicker)
        .onChange(of: viewModel.selectedDuration) { _, _ in
            viewModel.resetRecording()
            viewModel.startRecording()
        }
        .onDisappear { stopBeep() }
        .sheet(isPresented: $showVideoSheet) {
            LeadInstructionsVideoModal(gender: viewModel.patient.gender)
        }
    }

    // MARK: - Layout group

    private func layoutGroup(size: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            iconBtn(icon: "square.grid.3x3", size: size) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showLayoutPicker.toggle()
                    if showLayoutPicker { showDurationPicker = false }
                }
            }

            if showLayoutPicker {
                VStack(spacing: 4) {
                    ForEach(ECGLeadLayout.allCases, id: \.self) { layout in
                        let sel = viewModel.selectedLayout == layout
                        Button {
                            viewModel.selectedLayout = layout
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showLayoutPicker = false
                            }
                        } label: {
                            Text(layoutShort(layout))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.primary)
                                .frame(width: size, height: size)
                                .background(
                                    RoundedRectangle(cornerRadius: btnCornerSmall)
                                        .fill(sel ? AnyShapeStyle(AppColors.brandPrimary) : AnyShapeStyle(floatingSurface))
                                )
                                .overlay(RoundedRectangle(cornerRadius: btnCornerSmall).stroke(floatingBorder, lineWidth: 0.5))
                        }
                        .buttonStyle(.hapticPlain)
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Beep toggle

    private func beepBtn(size: CGFloat) -> some View {
        Button { toggleBeep() } label: {
            Image(systemName: isBeeping ? "speaker.slash.fill" : "speaker.fill")
                .font(iconFont)
                .foregroundStyle(Color.primary)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: btnCornerLarge).fill(floatingSurface))
                .overlay(RoundedRectangle(cornerRadius: btnCornerLarge).stroke(floatingBorder, lineWidth: 0.5))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.hapticPlain)
    }

    // MARK: - Video instructions

    private func videoBtn(size: CGFloat) -> some View {
        iconBtn(icon: "play.rectangle.fill", size: size) {
            showVideoSheet = true
        }
    }

    // MARK: - Reset

    private func resetBtn(size: CGFloat) -> some View {
        iconBtn(icon: "arrow.counterclockwise.circle.fill", size: size) {
            viewModel.resetRecording()
            viewModel.startRecording()
        }
    }

    // MARK: - Duration group

    private func durationGroup(btnSize: CGFloat, chipW: CGFloat) -> some View {
        Group {
            if showDurationPicker {
                HStack(spacing: 4) {
                    ForEach(RecordingDuration.allCases, id: \.self) { dur in
                        let sel = viewModel.selectedDuration == dur
                        Button {
                            viewModel.selectedDuration = dur
                            withAnimation { showDurationPicker = false }
                        } label: {
                            Text(durationShort(dur))
                                .font(ctrlFont)
                                .foregroundStyle(Color.primary)
                                .frame(width: chipW, height: btnSize)
                                .background(
                                    RoundedRectangle(cornerRadius: btnCornerSmall)
                                        .fill(sel ? AnyShapeStyle(AppColors.brandPrimary) : AnyShapeStyle(floatingSurface))
                                )
                                .overlay(RoundedRectangle(cornerRadius: btnCornerSmall).stroke(floatingBorder, lineWidth: 0.5))
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.hapticPlain)
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                Button {
                    withAnimation { showDurationPicker = true; showLayoutPicker = false }
                } label: {
                    Text(durationShort(viewModel.selectedDuration))
                        .font(ctrlFont)
                        .foregroundStyle(Color.primary)
                        .frame(width: btnSize, height: btnSize)
                        .background(RoundedRectangle(cornerRadius: btnCornerSmall).fill(floatingSurface))
                        .overlay(RoundedRectangle(cornerRadius: btnCornerSmall).stroke(floatingBorder, lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.hapticPlain)
            }
        }
    }

    // MARK: - Create / Stop button (with progress fill)

    private func createButton(size: CGFloat, width: CGFloat) -> some View {
        Button {
            switch viewModel.recordingState {
            case .idle:      viewModel.startRecording()
            case .recording: viewModel.stopRecording()
            case .done:      viewModel.showPreviewSheet = true
            }
        } label: {
            ZStack(alignment: .leading) {
                // Frosted base
                RoundedRectangle(cornerRadius: btnCornerSmall)
                    .fill(floatingSurface)

                // Accent / success fill growing left→right
                GeometryReader { g in
                    RoundedRectangle(cornerRadius: btnCornerSmall)
                        .fill(createFillColor)
                        .frame(width: g.size.width * createFillFraction)
                        .animation(.linear(duration: 1.0), value: viewModel.elapsedSeconds)
                }
                .clipShape(RoundedRectangle(cornerRadius: btnCornerSmall))

                Text(createLabel)
                    .font(ctrlFont)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: width, height: size)
            .clipShape(RoundedRectangle(cornerRadius: btnCornerSmall))
            .overlay(RoundedRectangle(cornerRadius: btnCornerSmall).stroke(floatingBorder, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.hapticPlain)
        .disabled(!viewModel.canStopOrView)
        .opacity(viewModel.canStopOrView ? 1 : 0.45)
        .animation(.easeInOut(duration: 0.2), value: viewModel.recordingState)
        .animation(.easeInOut(duration: 0.3), value: viewModel.canStopOrView)
    }

    // MARK: - Icon button helper

    private func iconBtn(icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(iconFont)
                .foregroundStyle(Color.primary)
                .frame(width: size, height: size)
                .background(RoundedRectangle(cornerRadius: btnCornerLarge).fill(floatingSurface))
                .overlay(RoundedRectangle(cornerRadius: btnCornerLarge).stroke(floatingBorder, lineWidth: 0.5))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.hapticPlain)
    }

    // MARK: - Helpers

    private func layoutShort(_ l: ECGLeadLayout) -> String {
        l.rawValue.filter { !$0.isWhitespace }
    }

    private func durationShort(_ d: RecordingDuration) -> String {
        d == .continuous ? "∞" : d.rawValue.filter { !$0.isWhitespace }
    }

    private var createFillColor: Color {
        viewModel.isBufferReady ? AppColors.statusSuccess : AppColors.brandPrimary
    }

    private var createFillFraction: Double {
        switch viewModel.recordingState {
        case .idle:
            return 0.0
        case .recording:
            return viewModel.selectedDuration == .continuous ? 1.0 : viewModel.progressFraction
        case .done:
            return 1.0
        }
    }

    private var createLabel: String {
        switch viewModel.recordingState {
        case .idle:      return L10n.Recording.Controls.record
        case .recording:
            if !viewModel.canStopOrView { return "\(viewModel.secondsUntilCanStop)s" }
            return viewModel.isBufferReady ? L10n.Recording.Controls.viewResult : L10n.Recording.Controls.stop
        case .done:      return L10n.Recording.Controls.viewResult
        }
    }

    // MARK: - Beep logic

    private func toggleBeep() {
        if isBeeping { stopBeep(); return }
        if beepPlayer == nil, let p = makeBeepPlayer() { beepPlayer = p }
        playBeepOnce()
        beepTimer = Timer.scheduledTimer(withTimeInterval: beepGap, repeats: true) { _ in
            playBeepOnce()
        }
        isBeeping = true
    }

    private func stopBeep() {
        beepTimer?.invalidate()
        beepTimer = nil
        beepPlayer?.stop()
        isBeeping = false
    }

    private func playBeepOnce() {
        beepPlayer?.currentTime = 0
        beepPlayer?.play()
    }

    private func makeBeepPlayer() -> AVAudioPlayer? {
        guard let asset = NSDataAsset(name: "BeepSound") else { return nil }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            let player = try AVAudioPlayer(data: asset.data)
            player.numberOfLoops = 0
            player.volume = 0.5
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
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
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    private var state: DeviceConnectionState { viewModel.connectSheetState }

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing32) {
                header
                statusBlock
            }
            .padding(isCompact ? AppMetrics.spacing20 : AppMetrics.spacing32)
            .frame(width: isCompact ? nil : 400)
            .frame(maxWidth: isCompact ? .infinity : nil)
            .padding(.horizontal, isCompact ? AppMetrics.spacing20 : 0)
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
            .buttonStyle(.hapticPlain)
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
                .buttonStyle(.hapticPlain)
                .padding(.top, AppMetrics.spacing4)
        }
    }
}

// MARK: - Lead Instructions Video Modal

private struct LeadInstructionsVideoModal: View {

    @Environment(\.dismiss) private var dismiss
    let gender: String

    private var assetName: String {
        gender.lowercased() == "female" ? "LeadPlacementFemale" : "LeadPlacementMale"
    }

    @State private var aspectRatio: CGFloat = 16.0 / 9.0

    private var detentHeight: CGFloat {
        max(120, UIScreen.main.bounds.width / aspectRatio)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            LocalAssetVideoPlayer(assetName: assetName) { ratio in
                aspectRatio = ratio
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.6))
            }
            .padding(12)
        }
        .presentationDetents([.height(detentHeight)])
        .presentationDragIndicator(.hidden)
    }
}

private struct LocalAssetVideoPlayer: View {

    let assetName: String
    var onAspectRatio: ((CGFloat) -> Void)? = nil

    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player).onAppear { player.play() }
            } else {
                ProgressView()
            }
        }
        .onAppear { loadIfNeeded() }
    }

    private func loadIfNeeded() {
        guard player == nil,
              let asset = NSDataAsset(name: assetName) else { return }
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(assetName).mp4")
        do {
            if !FileManager.default.fileExists(atPath: tempURL.path) {
                try asset.data.write(to: tempURL)
            }
            let urlAsset = AVURLAsset(url: tempURL)
            player = AVPlayer(playerItem: AVPlayerItem(asset: urlAsset))
            Task {
                do {
                    let tracks = try await urlAsset.loadTracks(withMediaType: .video)
                    guard let track = tracks.first else { return }
                    let size = try await track.load(.naturalSize)
                    let transform = try await track.load(.preferredTransform)
                    let oriented = size.applying(transform)
                    let w = abs(oriented.width), h = abs(oriented.height)
                    guard h > 0 else { return }
                    await MainActor.run { onAspectRatio?(w / h) }
                } catch {}
            }
        } catch {}
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
