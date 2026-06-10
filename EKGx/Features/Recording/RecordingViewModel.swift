//
//  RecordingViewModel.swift
//  EKGx
//
//  Drives all state for the ECG Recording screen.
//  Owns the device service, ECG data buffer, recording timer,
//  and all UI state transitions.
//

import Foundation
import SwiftUI
import vhECGSTFilters   // filtersECGsData used in setupDeviceCallbacks

// MARK: - Supporting Types

enum ECGLeadLayout: String, CaseIterable {
    case threeByFour = "3 × 4"
    case sixByTwo    = "6 × 2"
    case twelveByOne = "12 × 1"
}

enum RecordingDuration: String, CaseIterable {
    case ten        = "10 s"
    case thirty     = "30 s"
    case continuous = "Continuous"

    var seconds: Int {
        switch self {
        case .ten:        return 10
        case .thirty:     return 30
        case .continuous: return Int.max
        }
    }

    // Extra buffer second so the last data batch arrives before analysis runs
    var recordSeconds: Int {
        seconds == Int.max ? Int.max : seconds + 1
    }
}

enum RecordingState {
    case idle
    case recording
    case done
}

// MARK: - RecordingViewModel

@Observable
@MainActor
final class RecordingViewModel {

    // MARK: - UI State

    var recordingState: RecordingState = .idle
    var selectedLayout: ECGLeadLayout = .threeByFour
    var selectedDuration: RecordingDuration = .ten
    var elapsedSeconds: Int = 0
    var heartRate: Int = 0
    var batteryLevel: Int? = nil
    var showExitConfirmation: Bool = false
    var showPreviewSheet: Bool = false
    var showDeviceDisconnected: Bool = false
    var showConnectSheet: Bool = false
    var connectSheetState: DeviceConnectionState = .disconnected
    var connectSheetDeviceName: String? = nil
    var isFiltersEnabled: Bool = true

    // MARK: - Reconnect State

    private(set) var isReconnecting: Bool = false
    private(set) var reconnectAttempt: Int = 0
    let maxReconnectAttempts = 5
    private var reconnectTimer: Timer?

    // MARK: - Patient

    let patient: Patient

    // MARK: - ECG Data Buffer (12 leads, accumulates during recording)

    private(set) var ecgDataBuffer: ECGLeads = []

    // MARK: - Live Waveform Feed (filtered Int16 frames pushed to EKGRealtimeView)
    // frameCount increments on every new frame — EKGRealtimeView observes this Int
    // (Equatable) rather than [[Int16]] (not Equatable) so onChange fires reliably.

    private(set) var latestECGFrame: [[Int16]] = []
    private(set) var frameCount: Int = 0
    private(set) var latestLeadStatus: [Bool] = []
    private(set) var leadStatusCount: Int = 0

    // MARK: - Dependencies

    var deviceService: DeviceServiceProtocol
    private let router: AppRouter
    private let diContainer: AppDIContainer
    private var countTimer: Timer?
    private var signalWatchdog: Timer?

    // MARK: - Init

    init(patient: Patient, deviceService: DeviceServiceProtocol, router: AppRouter, diContainer: AppDIContainer) {
        self.patient = patient
        self.deviceService = deviceService
        self.router = router
        self.diContainer = diContainer
    }

    /// Call from RecordingView .onAppear — wires this VM as the sole onECGData receiver.
    func activate() {
        #if DEBUG
        print("🟢 [Recording] activate() — deviceState=\(deviceService.currentState)")
        #endif
        setupDeviceCallbacks()
        deviceService.reconfigureFilters()
        #if DEBUG
        print("🟢 [Recording] reconfigureFilters() called — deviceState=\(deviceService.currentState)")
        #endif
        connectSheetState = deviceService.currentState
        wireConnectionCallback()
        if deviceService.currentState == .connected {
            startRecording()
        } else {
            showConnectSheet = true
            deviceService.connect()
        }
    }

    // MARK: - Connect Sheet Actions

    func connectDevice() {
        nilOutCallbacks()
        diContainer.switchToRealDevice()
        deviceService = diContainer.deviceService
        connectSheetState = .disconnected
        connectSheetDeviceName = nil
        setupDeviceCallbacks()
        deviceService.reconfigureFilters()
        wireConnectionCallback()
        deviceService.connect()
    }

    func connectDemoDevice() {
        nilOutCallbacks()
        diContainer.switchToDemo()
        deviceService = diContainer.deviceService
        connectSheetState = .disconnected
        connectSheetDeviceName = nil
        setupDeviceCallbacks()
        deviceService.reconfigureFilters()
        wireConnectionCallback()
        deviceService.connect()
    }

    func cancelConnect() {
        showConnectSheet = false
        confirmExit()
    }

    private func nilOutCallbacks() {
        deviceService.onECGData = nil
        deviceService.onLeadStatus = nil
        deviceService.onBattery = nil
        deviceService.onConnectionStateChanged = nil
    }

    private func wireConnectionCallback() {
        deviceService.onConnectionStateChanged = { [weak self] state in
            guard let self else { return }
            DispatchQueue.main.async {
                #if DEBUG
                print("📡 [Recording] connectionStateChanged → \(state)")
                #endif
                self.connectSheetState = state
                switch state {
                case .connected where self.isReconnecting:
                    self.handleReconnectSuccess()
                case .connected where self.showConnectSheet:
                    self.connectSheetDeviceName = self.deviceService.connectedDeviceName
                    self.showConnectSheet = false
                    self.startRecording()
                case .disconnected where !self.isReconnecting && !self.showConnectSheet:
                    self.stopTimers()
                    self.startReconnectFlow()
                default:
                    break
                }
            }
        }
    }

    /// Call from RecordingView .onDisappear — releases the callback so the next VM can own it.
    func deactivate() {
        nilOutCallbacks()
        stopTimers()
    }

    // MARK: - Recording Control

    func startRecording() {
        guard recordingState == .idle else { return }
        ecgDataBuffer = []
        elapsedSeconds = 0
        recordingState = .recording
        resetWatchdog()

        countTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
        }
    }

    func stopRecording() {
        guard recordingState == .recording else { return }
        finishRecording()
    }

    func resetRecording() {
        stopTimers()          // also stops reconnectTimer
        isReconnecting = false
        reconnectAttempt = 0
        ecgDataBuffer = []
        latestECGFrame = []
        frameCount = 0
        elapsedSeconds = 0
        heartRate = 0
        recordingState = .idle
        showPreviewSheet = false
    }

    func confirmExit() {
        nilOutCallbacks()
        resetRecording()
        let dest = router.recordingReturnRoute
        router.recordingReturnRoute = .patientSelection
        router.navigate(to: dest)
    }

    func proceedToAnalysis() {
        showPreviewSheet = false
        diContainer.lastRecordingPatient = patient
        diContainer.lastRecordingData = ecgDataBuffer
        diContainer.lastRecordingSampleRate = deviceService.sampleRate
        diContainer.lastRecordingExistingId = nil
        if let start = diContainer.recordingSessionStartedAt {
            diContainer.lastRecordingTotalDuration = Int(Date().timeIntervalSince(start))
        }
        router.analysisReturnRoute = .vitals
        router.navigate(to: .ecgAnalysis(recordingId: ""))
    }

    // MARK: - Computed

    var elapsedFormatted: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var durationFormatted: String {
        selectedDuration == .continuous ? "∞" : "\(selectedDuration.seconds) s"
    }

    var progressFraction: Double {
        guard selectedDuration != .continuous, selectedDuration.seconds > 0 else { return 0 }
        return min(Double(elapsedSeconds) / Double(selectedDuration.seconds), 1.0)
    }

    var isReadyToRecord: Bool {
        deviceService.currentState == .connected
    }

    // True once the rolling buffer has accumulated the full selected duration
    var isBufferReady: Bool {
        guard selectedDuration != .continuous else { return true }
        return elapsedSeconds >= selectedDuration.seconds
    }

    static let minimumRecordingSeconds = 10

    // Stop / View Result button is locked for the first 10 s of every recording
    var canStopOrView: Bool {
        guard recordingState == .recording else { return true }
        return elapsedSeconds >= Self.minimumRecordingSeconds
    }

    var secondsUntilCanStop: Int {
        max(0, Self.minimumRecordingSeconds - elapsedSeconds)
    }

    var connectedDeviceName: String? {
        deviceService.connectedDeviceName
    }

    // MARK: - Private

    private func finishRecording() {
        stopTimers()
        recordingState = .done
        showPreviewSheet = true
    }

    private func stopTimers() {
        countTimer?.invalidate()
        countTimer = nil
        signalWatchdog?.invalidate()
        signalWatchdog = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    private func resetWatchdog() {
        signalWatchdog?.invalidate()
        signalWatchdog = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            guard let self, self.recordingState == .recording, !self.isReconnecting else { return }
            // Device still connected but data is momentarily absent (e.g. filter re-init after
            // reconfigureFilters()). Calling connect() on a connected device forces a disconnect
            // + rescan which breaks the recording. Reschedule the watchdog and wait instead.
            guard self.deviceService.currentState != .connected else {
                self.resetWatchdog()
                return
            }
            self.stopTimers()
            self.startReconnectFlow()
        }
    }

    // MARK: - Reconnect Flow
    //
    // Uses a Timer per attempt (not async/await + sleep) so there are no Swift
    // Concurrency cancellation surprises. Each attempt gives the device 8 seconds
    // to appear; if onConnectionStateChanged(.connected) fires sooner, success is
    // handled immediately without waiting for the timer.

    private func startReconnectFlow() {
        guard !isReconnecting else { return }
        isReconnecting = true
        reconnectAttempt = 0
        scheduleReconnectAttempt()
    }

    private func scheduleReconnectAttempt() {
        reconnectAttempt += 1
        // If device is already connected, calling connect() would force a disconnect + rescan.
        // Treat this as an instant success instead.
        if deviceService.currentState == .connected {
            handleReconnectSuccess()
            return
        }
        deviceService.connect()
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
            guard let self, self.isReconnecting else { return }
            if self.deviceService.currentState == .connected {
                self.handleReconnectSuccess()
            } else if self.reconnectAttempt < self.maxReconnectAttempts {
                self.scheduleReconnectAttempt()
            } else {
                self.handleReconnectFailure()
            }
        }
    }

    private func handleReconnectSuccess() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        resetRecording()
        startRecording()
    }

    private func handleReconnectFailure() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        isReconnecting = false
        reconnectAttempt = 0
        showDeviceDisconnected = true
    }

    private func setupDeviceCallbacks() {
        #if DEBUG
        print("🔧 [Recording] setupDeviceCallbacks()")
        #endif

        deviceService.onBattery = { [weak self] level in
            guard let self else { return }
            Task { @MainActor in
                self.batteryLevel = level
            }
        }

        deviceService.onLeadStatus = { [weak self] status in
            guard let self else { return }
            Task { @MainActor in
                self.latestLeadStatus = status
                self.leadStatusCount &+= 1
            }
        }

        deviceService.onECGData = { [weak self] leads in
            guard let self else { return }
            #if DEBUG
            //print("📦 [Recording] onECGData fired — leads=\(leads.count) samples=\(leads.first?.count ?? 0)")
            #endif
            vhECGFiltersLib.shared().filtersECGsData(leads) { [weak self] filtered in
                guard let self, let filtered else {
                    #if DEBUG
                    //print("⚠️ [Recording] filtersECGsData callback — filtered is nil!")
                    #endif
                    return
                }
                #if DEBUG
                //print("✅ [Recording] filtersECGsData done — filtered leads=\(filtered.count) frameCount will be=\(self.frameCount + 1)")
                #endif
                let frame = filtered.map { $0.map { Int16(truncatingIfNeeded: $0.intValue) } }
                Task { @MainActor in
                    self.latestECGFrame = frame
                    self.frameCount &+= 1
                    if self.recordingState == .recording {
                        self.appendToBuffer(filtered)
                        self.resetWatchdog()
                    }
                }
            } hbrHandler: { [weak self] hbr in
                guard let self else { return }
                Task { @MainActor in
                    self.heartRate = Int(hbr)
                }
            }
        }
    }

    private func appendToBuffer(_ leads: ECGLeads) {
        let maxSamples = selectedDuration.seconds == Int.max
            ? 660 * 60
            : 660 * selectedDuration.seconds + 660

        if ecgDataBuffer.isEmpty {
            ecgDataBuffer = leads
        } else {
            for i in 0..<min(leads.count, ecgDataBuffer.count) {
                ecgDataBuffer[i].append(contentsOf: leads[i])
            }
        }

        // Trim oldest samples if over cap
        let currentCount = ecgDataBuffer.first?.count ?? 0
        if currentCount > maxSamples {
            let trimCount = currentCount - maxSamples
            for i in 0..<ecgDataBuffer.count {
                ecgDataBuffer[i].removeFirst(trimCount)
            }
        }
    }
}
