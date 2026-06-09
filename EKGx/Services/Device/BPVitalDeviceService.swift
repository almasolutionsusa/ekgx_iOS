import Foundation

// MARK: - BPVitalDeviceService

#if !targetEnvironment(simulator)

final class BPVitalDeviceService: NSObject, VitalDeviceServiceProtocol,
                                   VTBLEUtilsDelegate,
                                   VTMURATDeviceDelegate,
                                   VTMURATUtilsDelegate {

    // MARK: - VitalDeviceServiceProtocol

    private(set) var connectionState: DeviceConnectionState = .disconnected {
        didSet { guard connectionState != oldValue else { return }
                 onStateChanged?(connectionState) }
    }

    private(set) var connectedDeviceName: String?
    var onStateChanged:  ((DeviceConnectionState) -> Void)?
    var onMeasurement:   ((VitalMeasurement) -> Void)?

    // MARK: - Private

    private var pollTimer: Timer?

    // MARK: - Connect / Disconnect

    func connect() {
        tearDown()
        VTBLEUtils.sharedInstance().delegate = self
        VTMProductURATUtils.sharedInstance().delegate = self
        VTMProductURATUtils.sharedInstance().deviceDelegate = self
        connectionState = .searching
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            VTBLEUtils.sharedInstance().startScan()
        }
    }

    func connectDemo() {
        tearDown()
        connectionState = .connecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            connectedDeviceName = "BP Demo"
            connectionState = .connected
            simulateMeasurement()
        }
    }

    func disconnect() {
        tearDown()
        connectionState = .disconnected
    }

    // MARK: - VTBLEUtilsDelegate

    func update(_ state: VTBLEState) {}

    func didDiscover(_ device: VTDevice) {
        connectedDeviceName = device.advName
        connectionState = .connecting
        VTBLEUtils.sharedInstance().stopScan()
        VTBLEUtils.sharedInstance().connect(to: device)
    }

    func didConnectedDevice(_ device: VTDevice) {
        connectedDeviceName = device.advName
        VTMProductURATUtils.sharedInstance().peripheral = device.rawPeripheral
        connectionState = .connected
        // Polling starts in utilDeployCompletion once services/characteristics are ready.
    }

    func didDisconnectedDevice(_ device: VTDevice, andError error: Error) {
        tearDown()
        connectionState = .disconnected
    }

    // MARK: - VTMURATDeviceDelegate

    func utilDeployCompletion(_ util: VTMURATUtils) {
        startPolling()
    }

    func utilDeployFailed(_ util: VTMURATUtils) {
        tearDown()
        connectionState = .disconnected
    }

    // MARK: - VTMURATUtilsDelegate

    func util(_ util: VTMURATUtils,
              commandCompletion cmdType: u_char,
              deviceType: VTMDeviceType,
              response: Data?) {

        guard let response, cmdType == VTMBPCmdGetRealData.rawValue else { return }

        let bpData   = VTMBLEParser.parseBPRealTime(response)
        let status   = bpData.run_status
        let waveform = bpData.rt_wav

        switch status.status {

        case 4: // Inflating / deflating — show live cuff pressure
            let ptr = UnsafeMutablePointer<VTMBPRealTimeWaveform>.allocate(capacity: 1)
            ptr.pointee = waveform
            let raw      = VTMProductURATUtils.sharedInstance().obbj(ptr)
            let measuring = VTMBLEParser.parseBPMeasuring(raw)
            guard measuring.pressure > 0 else { return }
            let mmhg = Int(measuring.pressure) / 100
            DispatchQueue.main.async { [weak self] in
                self?.onMeasurement?(VitalMeasurement(displayValue: "\(mmhg)/--", unit: "mmHg"))
            }

        case 5: // Measurement complete — keep polling so next cycle is captured automatically
            let ptr = UnsafeMutablePointer<VTMBPRealTimeWaveform>.allocate(capacity: 1)
            ptr.pointee = waveform
            let raw    = VTMProductURATUtils.sharedInstance().obbj(ptr)
            let result = VTMBLEParser.parseBPEndMeasure(raw)
            let sys    = Int(result.systolic_pressure)
            let dia    = Int(result.diastolic_pressure)
            let pr     = result.pulse_rate > 0 ? Int(result.pulse_rate) : nil
            DispatchQueue.main.async { [weak self] in
                var m = VitalMeasurement(displayValue: "\(sys)/\(dia)", unit: "mmHg")
                m.systolic  = sys
                m.diastolic = dia
                m.pulseRate = pr
                self?.onMeasurement?(m)
            }

        default:
            break
        }
    }

    // MARK: - Private helpers

    private func startPolling() {
        stopPolling()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                VTMProductURATUtils.sharedInstance().requestBPRealData()
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func tearDown() {
        stopPolling()
        VTBLEUtils.sharedInstance().stopScan()
        VTBLEUtils.sharedInstance().cancelConnect()
        VTBLEUtils.sharedInstance().delegate = nil
        VTMProductURATUtils.sharedInstance().delegate = nil
        VTMProductURATUtils.sharedInstance().deviceDelegate = nil
        connectedDeviceName = nil
    }

    private func simulateMeasurement() {
        var cuffPressure = 160
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] timer in
            guard let self, connectionState == .connected else { timer.invalidate(); return }
            cuffPressure -= 8
            if cuffPressure <= 110 {
                timer.invalidate()
                var m = VitalMeasurement(displayValue: "120/80", unit: "mmHg")
                m.systolic  = 120
                m.diastolic = 80
                m.pulseRate = 72
                onMeasurement?(m)
                // Repeat cycle after 8 seconds to simulate a live device
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
                    guard self?.connectionState == .connected else { return }
                    self?.simulateMeasurement()
                }
            } else {
                onMeasurement?(VitalMeasurement(displayValue: "\(cuffPressure)/--", unit: "mmHg"))
            }
        }
    }
}

#else

// MARK: - Simulator stub

final class BPVitalDeviceService: VitalDeviceServiceProtocol {
    var connectionState:     DeviceConnectionState              = .disconnected
    var connectedDeviceName: String?                            = nil
    var onStateChanged:  ((DeviceConnectionState) -> Void)?     = nil
    var onMeasurement:   ((VitalMeasurement) -> Void)?          = nil
    func connect()      {}
    func connectDemo()  {}
    func disconnect()   {}
}

#endif

