import Foundation

// MARK: - OximeterVitalDeviceService

#if !targetEnvironment(simulator)

private let kSupportedDevicePrefixes = ["PC-60E", "PC-60F", "PC-68B", "OxyKnight", "OxySmart", "AP-20", "SP-20"]

final class OximeterVitalDeviceService: NSObject, VitalDeviceServiceProtocol,
                                         CRBlueToothManagerDelegate,
                                         CRAP20SDKDelegate {

    // MARK: - VitalDeviceServiceProtocol

    private(set) var connectionState: DeviceConnectionState = .disconnected {
        didSet { guard connectionState != oldValue else { return }
                 onStateChanged?(connectionState) }
    }

    private(set) var connectedDeviceName: String?
    var onStateChanged:  ((DeviceConnectionState) -> Void)?
    var onMeasurement:   ((VitalMeasurement) -> Void)?

    // MARK: - Private

    private var demoTimer: Timer?
    private var connectedDevice: CRBleDevice?
    private var shouldRetrySearch = false

    // MARK: - Connect / Disconnect

    func connect() {
        print("[SpO2] connect() — starting BLE scan for \(kSupportedDevicePrefixes)")
        tearDown()
        shouldRetrySearch = true
        CCRBlueToothManager.shareInstance().delegate = self
        connectionState = .searching
        CCRBlueToothManager.shareInstance().startSearchDevices(forSeconds: 5)
    }

    func connectDemo() {
        print("[SpO2] connectDemo() — starting demo mode")
        tearDown()
        connectionState = .connecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            connectedDeviceName = "SpO2 Demo"
            connectionState = .connected
            print("[SpO2] connectDemo() — demo device connected")
            streamDemoReadings()
        }
    }

    func disconnect() {
        print("[SpO2] disconnect() called")
        tearDown()
        connectionState = .disconnected
    }

    // MARK: - CRBlueToothManagerDelegate

    func bleManager(_ manager: CCRBlueToothManager!, didUpdate state: CBManagerState) {
        let label: String
        switch state {
        case .poweredOn:    label = "poweredOn"
        case .poweredOff:   label = "poweredOff"
        case .unauthorized: label = "unauthorized"
        case .unsupported:  label = "unsupported"
        case .resetting:    label = "resetting"
        default:            label = "unknown(\(state.rawValue))"
        }
        print("[SpO2] BT state changed → \(label)")
    }

    func bleManager(_ manager: CCRBlueToothManager!,
                    didSearchCompleteWithResult deviceList: [CRBleDevice]!) {
        let names = (deviceList ?? []).compactMap { $0.bleName }
        print("[SpO2] scan complete — found \(names.count) device(s): \(names)")

        let match = (deviceList ?? []).first { device in
            kSupportedDevicePrefixes.contains(where: { device.bleName?.hasPrefix($0) == true })
        }
        if let device = match {
            print("[SpO2] matched device '\(device.bleName ?? "?")' — connecting…")
            shouldRetrySearch = false
            CCRBlueToothManager.shareInstance().stopSearch()
            CCRBlueToothManager.shareInstance().connect(device)
            connectionState = .connecting
        } else if shouldRetrySearch {
            print("[SpO2] no match — retrying scan…")
            CCRBlueToothManager.shareInstance().startSearchDevices(forSeconds: 5)
        } else {
            print("[SpO2] no supported device found — scan stopped")
        }
    }

    func bleManager(_ manager: CCRBlueToothManager!, didFindDevice deviceList: [CRBleDevice]!) {
        let names = (deviceList ?? []).compactMap { $0.bleName }
        print("[SpO2] didFindDevice (interim) — \(names)")
    }

    func bleManager(_ manager: CCRBlueToothManager!, didConnect device: CRBleDevice!) {
        print("[SpO2] connected to '\(device.bleName ?? "?")'")
        connectedDevice     = device
        connectedDeviceName = device.bleName
        CRAP20SDK.shareInstance().didConnect(device)
        CRAP20SDK.shareInstance().delegate = self
        connectionState = .connected
    }

    func bleManager(_ manager: CCRBlueToothManager!,
                    didDisconnectDevice device: CRBleDevice!,
                    error: (any Error)?) {
        print("[SpO2] disconnected from '\(device?.bleName ?? "?")' error=\(error?.localizedDescription ?? "none")")
        CRAP20SDK.shareInstance().willDisconnect(with: device)
        CRAP20SDK.shareInstance().delegate = nil
        connectedDevice     = nil
        connectedDeviceName = nil
        connectionState     = .disconnected
    }

    func bleManager(_ manager: CCRBlueToothManager!,
                    didFailToConnect device: CRBleDevice!,
                    error: (any Error)?) {
        print("[SpO2] failed to connect to '\(device?.bleName ?? "?")' error=\(error?.localizedDescription ?? "none")")
        connectedDevice     = nil
        connectedDeviceName = nil
        connectionState     = .disconnected
    }

    // MARK: - CRAP20SDKDelegate — primary data

    func ap_20SDK(_ ap_20SDK: CRAP20SDK!,
                  getSpo2Value spo2: Int32,
                  pulseRate pr: Int32,
                  pi: Int32,
                  state: CRAP_20Spo2State,
                  mode: CRAP_20Spo2Mode,
                  battaryLevel: Int32,
                  from device: CRBleDevice!) {

        let stateDesc = spo2StateDescription(state)
        let modeDesc  = mode.rawValue == 1 ? "Newborn" : mode.rawValue == 2 ? "Animal" : "Adult"
        print("[SpO2] data — spo2=\(spo2)% pr=\(pr)bpm pi=\(pi) battery=\(battaryLevel)% state=[\(stateDesc)] mode=\(modeDesc) device='\(device?.bleName ?? "?")'")

        let spo2Int = Int(spo2)
        let prInt   = Int(pr)
        DispatchQueue.main.async { [weak self] in
            var m = VitalMeasurement(displayValue: "\(spo2Int)", unit: "%")
            m.pulseRate = prInt
            self?.onMeasurement?(m)
        }
    }

    func ap_20SDK(_ ap_20SDK: CRAP20SDK!,
                  getSpo2Wave wave: UnsafeMutablePointer<waveData>!,
                  from device: CRBleDevice!) {
//        if let w = wave {
            //print("[SpO2] wave — value=\(w.pointee.waveValue)")
//        }
    }

    // MARK: - Remaining CRAP20SDKDelegate stubs

    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getDeviceInfoForSoftWareVersion softWareV: String!, hardWaveVersion hardWareV: String!, productName: String!, from device: CRBleDevice!) {
        print("[SpO2] device info — product='\(productName ?? "?")' sw=\(softWareV ?? "?") hw=\(hardWareV ?? "?")")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getSerialNumber serialNumber: String!, from device: CRBleDevice!) {
        print("[SpO2] serial number — \(serialNumber ?? "?")")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getDeviceTime deviceTime: String!, from device: CRBleDevice!) {
        print("[SpO2] device time — \(deviceTime ?? "?")")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getDeviceBackLightLevel lightLevel: Int32, from device: CRBleDevice!) {
        print("[SpO2] backlight level — \(lightLevel)")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getBartteryLevel batteryLevel: Int32, from device: CRBleDevice!) {
        print("[SpO2] battery — \(batteryLevel)%")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getSpo2AlertInfoWith type: CRAP_20Spo2AlertConfigType, value: Int32, from device: CRBleDevice!) {
        print("[SpO2] alert config — type=\(type.rawValue) value=\(value)")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getUserID userID: String!, from device: CRBleDevice!) {
        print("[SpO2] user ID — \(userID ?? "?")")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, deviceBackLightLevelSettedSuccess success: Bool, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, deviceTimeSettedSuccess success: Bool, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, spo2AlertParamInfoType type: CRAP_20Spo2AlertConfigType, settedSuccess success: Bool, from device: CRBleDevice!) {}
    func successdToSetSpo2ParamEnable(from device: CRBleDevice!) {
        print("[SpO2] spo2 param enable set ✓")
    }
    func successdToSetSpo2WaveEnable(from device: CRBleDevice!) {
        print("[SpO2] spo2 wave enable set ✓")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getMenuLowSpO2 lowSpO2: Int32, highPR highPr: Int32, lowPR lowPr: Int32, spot: Int32, beepOn: Int32, rotateOn: Int32, from device: CRBleDevice!) {
        print("[SpO2] menu — lowSpO2=\(lowSpO2) highPR=\(highPr) lowPR=\(lowPr) spot=\(spot) beep=\(beepOn) rotate=\(rotateOn)")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getRecordsInfoArray infoArray: [Any]!, from device: CRBleDevice!) {
        print("[SpO2] stored records — count=\((infoArray ?? []).count)")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getRecordsData model: CRAP20RecordModel!, from device: CRBleDevice!) {
        print("[SpO2] record #\(model?.recordNum ?? -1) time=\(model?.time ?? "?") spo2Points=\(model?.spo2Array?.count ?? 0)")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, didDeleteRecordsSuccess success: Bool, from device: CRBleDevice!) {
        print("[SpO2] delete records — \(success ? "success" : "failed")")
    }
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getSpo2AlertState alertOn: Bool, spo2LowValue spo2Low: Int32, prLowValue prLow: Int32, prHighValue prHigh: Int32, pulseBeep beepOn: Bool, sensorAlert sensorOn: Bool, for device: CRBleDevice!) {
        print("[SpO2] alert state — on=\(alertOn) spo2Low=\(spo2Low) prLow=\(prLow) prHigh=\(prHigh) beep=\(beepOn) sensor=\(sensorOn)")
    }

    // MARK: - Private helpers

    private func tearDown() {
        print("[SpO2] tearDown — cleaning up BLE state")
        shouldRetrySearch = false
        demoTimer?.invalidate()
        demoTimer = nil
        if let device = connectedDevice {
            CRAP20SDK.shareInstance().willDisconnect(with: device)
            CRAP20SDK.shareInstance().delegate = nil
            CCRBlueToothManager.shareInstance().disconnectDevice(device)
        }
        CCRBlueToothManager.shareInstance().stopSearch()
        CCRBlueToothManager.shareInstance().delegate = nil
        connectedDevice     = nil
        connectedDeviceName = nil
    }

    private func spo2StateDescription(_ state: CRAP_20Spo2State) -> String {
        let v = state.rawValue
        if v == 0 { return "Normal" }
        var parts: [String] = []
        if v & 0x01 != 0 { parts.append("ProbeDisconnected") }
        if v & 0x02 != 0 { parts.append("ProbeOff") }
        if v & 0x04 != 0 { parts.append("PulseSearching") }
        if v & 0x08 != 0 { parts.append("CheckProbe") }
        if v & 0x10 != 0 { parts.append("MotionDetected") }
        if v & 0x20 != 0 { parts.append("LowPerfusion") }
        return parts.isEmpty ? "Unknown(0x\(String(v, radix: 16)))" : parts.joined(separator: "|")
    }

    private func streamDemoReadings() {
        var tick = 0
        demoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self, connectionState == .connected else { timer.invalidate(); return }
            tick += 1
            let spo2 = 97 + (tick % 3)
            let pr   = 68 + (tick % 8)
            var m = VitalMeasurement(displayValue: "\(spo2)", unit: "%")
            m.pulseRate = pr
            onMeasurement?(m)
        }
    }
}

#else

// MARK: - Simulator stub

final class OximeterVitalDeviceService: VitalDeviceServiceProtocol {
    var connectionState:     DeviceConnectionState              = .disconnected
    var connectedDeviceName: String?                            = nil
    var onStateChanged:  ((DeviceConnectionState) -> Void)?     = nil
    var onMeasurement:   ((VitalMeasurement) -> Void)?          = nil
    func connect()      {}
    func connectDemo()  {}
    func disconnect()   {}
}

#endif
