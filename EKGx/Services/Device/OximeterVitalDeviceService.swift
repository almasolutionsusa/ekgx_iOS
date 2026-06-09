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

    // MARK: - Connect / Disconnect

    func connect() {
        tearDown()
        CCRBlueToothManager.shareInstance().delegate = self
        connectionState = .searching
        CCRBlueToothManager.shareInstance().startSearchDevices(forSeconds: 5)
    }

    func connectDemo() {
        tearDown()
        connectionState = .connecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            connectedDeviceName = "SpO2 Demo"
            connectionState = .connected
            streamDemoReadings()
        }
    }

    func disconnect() {
        tearDown()
        connectionState = .disconnected
    }

    // MARK: - CRBlueToothManagerDelegate

    func bleManager(_ manager: CCRBlueToothManager!, didUpdate state: CBManagerState) {}

    func bleManager(_ manager: CCRBlueToothManager!,
                    didSearchCompleteWithResult deviceList: [CRBleDevice]!) {

        let match = (deviceList ?? []).first { device in
            kSupportedDevicePrefixes.contains(where: { device.bleName?.hasPrefix($0) == true })
        }
        if let device = match {
            CCRBlueToothManager.shareInstance().stopSearch()
            CCRBlueToothManager.shareInstance().connect(device)
            connectionState = .connecting
        }
    }

    func bleManager(_ manager: CCRBlueToothManager!, didFindDevice deviceList: [CRBleDevice]!) {}

    func bleManager(_ manager: CCRBlueToothManager!, didConnect device: CRBleDevice!) {
        connectedDevice     = device
        connectedDeviceName = device.bleName
        CRAP20SDK.shareInstance().didConnect(device)
        CRAP20SDK.shareInstance().delegate = self
        connectionState = .connected
    }

    func bleManager(_ manager: CCRBlueToothManager!,
                    didDisconnectDevice device: CRBleDevice!,
                    error: NSError?) {
        CRAP20SDK.shareInstance().willDisconnect(with: device)
        CRAP20SDK.shareInstance().delegate = nil
        connectedDevice     = nil
        connectedDeviceName = nil
        connectionState     = .disconnected
    }

    func bleManager(_ manager: CCRBlueToothManager!,
                    didFailToConnect device: CRBleDevice!,
                    error: NSError?) {
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

        let spo2Int = Int(spo2)
        let prInt   = Int(pr)
        DispatchQueue.main.async { [weak self] in
            var m = VitalMeasurement(displayValue: "\(spo2Int)%", unit: "%")
            m.pulseRate = prInt
            self?.onMeasurement?(m)
        }
    }

    func ap_20SDK(_ ap_20SDK: CRAP20SDK!,
                  getSpo2Wave wave: UnsafeMutablePointer<waveData>!,
                  from device: CRBleDevice!) {}

    // MARK: - Remaining CRAP20SDKDelegate stubs
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getDeviceInfoForSoftWareVersion softWareV: String!, hardWaveVersion hardWareV: String!, productName: String!, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getSerialNumber serialNumber: String!, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getDeviceTime deviceTime: String!, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getDeviceBackLightLevel lightLevel: Int32, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getBartteryLevel batteryLevel: Int32, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getSpo2AlertInfoWith type: CRAP_20Spo2AlertConfigType, value: Int32, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getUserID userID: String!, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, deviceBackLightLevelSettedSuccess success: Bool, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, deviceTimeSettedSuccess success: Bool, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, spo2AlertParamInfoType type: CRAP_20Spo2AlertConfigType, settedSuccess success: Bool, from device: CRBleDevice!) {}
    func successdToSetSpo2ParamEnable(from device: CRBleDevice!) {}
    func successdToSetSpo2WaveEnable(from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getNasalFlowWave nasalFlowWave: nasalFlowWaveData, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getNasalFlowRespirationRate rate: Int32, from device: CRBleDevice!) {}
    func successdToSetNasalFlowParamEnable(from device: CRBleDevice!) {}
    func successdToSetNasalFlowWaveEnable(from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, get waveData: three_AxesWaveData, from device: CRBleDevice!) {}
    func successdToSetThree_AxesWaveEnable(from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, get result: CRAP_20TemparatureResult, value tempValue: Float, unit unitCode: CRAP_20TemparatureUnit, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getMACAddress macAddress: String!, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getWorkStatusDataWith mode: CRPC_60FWorkStatusMode, stage: CRPC_60FCommanMessureStage, parameter para: Int32, otherParameter otherPara: Int32, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, setMenuSuccess failOrSuccess: Bool, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getMenuLowSpO2 lowSpO2: Int32, highPR highPr: Int32, lowPR lowPr: Int32, spot: Int32, beepOn: Int32, rotateOn: Int32, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getRecordsInfoArray infoArray: [Any]!, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getRecordsData model: CRAP20RecordModel!, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, didDeleteRecordsSuccess success: Bool, from device: CRBleDevice!) {}
    func ap_20SDK(_ ap_20SDK: CRAP20SDK!, getSpo2AlertState alertOn: Bool, spo2LowValue spo2Low: Int32, prLowValue prLow: Int32, prHighValue prHigh: Int32, pulseBeep beepOn: Bool, sensorAlert sensorOn: Bool, for device: CRBleDevice!) {}

    // MARK: - Private helpers

    private func tearDown() {
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

    private func streamDemoReadings() {
        var tick = 0
        demoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self, connectionState == .connected else { timer.invalidate(); return }
            tick += 1
            let spo2 = 97 + (tick % 3)
            let pr   = 68 + (tick % 8)
            var m = VitalMeasurement(displayValue: "\(spo2)%", unit: "%")
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
