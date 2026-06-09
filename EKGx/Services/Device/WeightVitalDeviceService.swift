import Foundation
import ICDeviceManager

// MARK: - WeightDeviceInfo

struct WeightDeviceInfo: Identifiable {
    let id: String      // macAddr
    let name: String
    let rssi: Int
}

// MARK: - WeightVitalDeviceService

final class WeightVitalDeviceService: NSObject, VitalDeviceServiceProtocol {

    // MARK: - VitalDeviceServiceProtocol

    private(set) var connectionState: DeviceConnectionState = .disconnected {
        didSet {
            guard connectionState != oldValue else { return }
            onStateChanged?(connectionState)
        }
    }

    private(set) var connectedDeviceName: String?
    var onStateChanged:  ((DeviceConnectionState) -> Void)?
    var onMeasurement:   ((VitalMeasurement) -> Void)?

    // MARK: - Scan Results (observed by VitalsViewModel)

    private(set) var scanDevices: [WeightDeviceInfo] = []
    var onScanDevicesChanged: (([WeightDeviceInfo]) -> Void)?

    // MARK: - Private

    // Strong refs to scan results keyed by macAddr — needed when calling addDevice
    private var discoveredScanInfos: [String: ICScanDeviceInfo] = [:]
    private var connectedDevice: ICDevice?
    private var connectedSubType: ICDeviceSubType = .default
    private let macAddrKey = "weight.pairedMacAddr"

    // MARK: - Init

    override init() {
        super.init()
        ICDeviceManager.shared().delegate = self
        ICDeviceManager.shared().initMgr()
    }

    // MARK: - VitalDeviceServiceProtocol

    func connect() {
        discoveredScanInfos = [:]
        scanDevices = []
        onScanDevicesChanged?([])
        connectionState = .searching
        ICDeviceManager.shared().scanDevice(self)
    }

    func connectDemo() {
        disconnect()
        connectionState = .connecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            connectedDeviceName = "Scale Demo"
            connectionState = .connected
            // Fire demo measurements with a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.fireDemoMeasurement()
            }
        }
    }

    func disconnect() {
        ICDeviceManager.shared().stopScan()
        if let device = connectedDevice {
            ICDeviceManager.shared().remove(device, callback: nil)
            connectedDevice = nil
        }
        connectedDeviceName = nil
        connectedSubType = .default
        scanDevices = []
        discoveredScanInfos = [:]
        connectionState = .disconnected
    }

    // MARK: - Device Selection

    func selectDevice(_ info: WeightDeviceInfo) {
        guard let scanInfo = discoveredScanInfos[info.id] else { return }

        connectionState = .connecting
        connectedDeviceName = info.name
        connectedSubType = scanInfo.subType

        let device = ICDevice()
        device.macAddr = info.id
        connectedDevice = device

        UserDefaults.standard.set(info.id, forKey: macAddrKey)

        ICDeviceManager.shared().add(device, callback: nil)
        ICDeviceManager.shared().stopScan()
    }

    // MARK: - User Info

    private func sendUserInfo(for device: ICDevice) {
        let userInfo = ICUserInfo()
        userInfo.height = 170
        userInfo.age = 35
        userInfo.sex = ICSexType.male//ICSexTypeMale
        userInfo.weightUnit = ICWeightUnit.kg//ICWeightUnitKg
        if connectedSubType == ICDeviceSubType.newScale {
            ICDeviceManager.shared().getSettingManager()?.setUserInfo(device, userInfo: userInfo, callback: nil)
        } else {
            ICDeviceManager.shared().update(userInfo)
        }
    }

    // MARK: - Demo

    private func fireDemoMeasurement() {
        let weightKg = Double(Int.random(in: 600...900)) / 10.0
        let bodyFat  = Double(Int.random(in: 150...350)) / 10.0
        onMeasurement?(VitalMeasurement(
            displayValue: String(format: "%.1f", weightKg),
            unit: "kg",
            bodyFatPercent: bodyFat
        ))
    }
}

// MARK: - ICScanDeviceDelegate

extension WeightVitalDeviceService: ICScanDeviceDelegate {

    func onScanResult(_ deviceInfo: ICScanDeviceInfo) {
        guard let mac = deviceInfo.macAddr, !mac.isEmpty else { return }
        print("[WeightSDK] onScanResult: mac=\(mac) name=\(deviceInfo.name ?? "nil") rssi=\(deviceInfo.rssi) subType=\(deviceInfo.subType.rawValue)")
        discoveredScanInfos[mac] = deviceInfo
        let name = deviceInfo.name?.isEmpty == false ? deviceInfo.name! : mac

        guard !scanDevices.contains(where: { $0.id == mac }) else { return }
        let info = WeightDeviceInfo(id: mac, name: name, rssi: deviceInfo.rssi)
        scanDevices.append(info)
        onScanDevicesChanged?(scanDevices)

        // Auto-connect to the first device found
        if scanDevices.count == 1 {
            selectDevice(info)
        }
    }
}

// MARK: - ICDeviceManagerDelegate

extension WeightVitalDeviceService: ICDeviceManagerDelegate {

    func onInitFinish(_ bSuccess: Bool) {
        print("[WeightSDK] onInitFinish: \(bSuccess)")
    }

    func onDeviceConnectionChanged(_ device: ICDevice, state: ICDeviceConnectState) {
        print("[WeightSDK] onDeviceConnectionChanged: \(state.rawValue) mac=\(device.macAddr ?? "nil")")
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch state {
            case ICDeviceConnectState.connected:
                connectedDevice = device
                if connectedDeviceName == nil {
                    connectedDeviceName = device.macAddr
                }
                connectionState = .connected
                sendUserInfo(for: device)

            case ICDeviceConnectState.disconnected:
                if connectionState != .disconnected {
                    connectedDevice = nil
                    connectedDeviceName = nil
                    connectionState = .disconnected
                }

            default:
                break
            }
        }
    }

    func onReceiveWeightData(_ device: ICDevice, data: ICWeightData) {
        print("[WeightSDK] onReceiveWeightData: weight_kg=\(data.weight_kg) isStabilized=\(data.isStabilized) bodyFat=\(data.bodyFatPercent)")
        guard data.isStabilized else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let kg = Double(data.weight_kg)
            var fat: Double? = nil
            if data.bodyFatPercent > 0 { fat = Double(data.bodyFatPercent) }
            onMeasurement?(VitalMeasurement(
                displayValue: String(format: "%.1f", kg),
                unit: "kg",
                bodyFatPercent: fat
            ))
        }
    }

    func onReceiveMeasureStepData(_ device: ICDevice, step: ICMeasureStep, data: NSObject) {
        print("[WeightSDK] onReceiveMeasureStepData: step=\(step.rawValue) dataType=\(type(of: data))")
        guard step == ICMeasureStepMeasureOver, let weightData = data as? ICWeightData else { return }
        print("[WeightSDK] onReceiveMeasureStepData (MeasureOver): weight_kg=\(weightData.weight_kg) bodyFat=\(weightData.bodyFatPercent)")
        weightData.isStabilized = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let kg = Double(weightData.weight_kg)
            var fat: Double? = nil
            if weightData.bodyFatPercent > 0 { fat = Double(weightData.bodyFatPercent) }
            onMeasurement?(VitalMeasurement(
                displayValue: String(format: "%.1f", kg),
                unit: "kg",
                bodyFatPercent: fat
            ))
        }
    }
}
