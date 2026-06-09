import Foundation
import AHDevicePlugin

// MARK: - TemperatureVitalDeviceService


final class TemperatureVitalDeviceService: NSObject,
                                            VitalDeviceServiceProtocol,
                                            AHBluetoothStatusDelegate,
                                            AHDeviceDataDelegate {

    // MARK: - VitalDeviceServiceProtocol

    private(set) var connectionState: DeviceConnectionState = .disconnected {
        didSet {
            guard connectionState != oldValue else { return }
            onStateChanged?(connectionState)
        }
    }
    private(set) var connectedDeviceName: String?
    var onStateChanged: ((DeviceConnectionState) -> Void)?
    var onMeasurement:  ((VitalMeasurement) -> Void)?

    // MARK: - Private

    // Stored once to avoid the optional return from AHDevicePlugin.`default`() at each call site.
    private let sdk: AHDevicePlugin = AHDevicePlugin.`default`()

    private var currentDevice: BTDeviceInfo?
    private var demoTimer: Timer?
    private var demoTick: Int = 0

    // MARK: - Connect / Disconnect

    func connect() {
        tearDown()
        connectionState = .searching
        sdk.initPlugin(.main)
        sdk.bleStateDelegate = self

        let filter = BTScanFilter()
        filter.scanTypes = [
            NSNumber(value: BTDeviceType.thermometer.rawValue),
            NSNumber(value: BTDeviceType.digitalThermometer.rawValue)
        ]

        sdk.searchDevice(filter) { [weak self] device in
            guard let self, let device else { return }
            sdk.stopSearch()
            connectedDeviceName = device.broadcastId ?? "AOJ Thermometer"
            connectionState = .connecting
            addAndConnect(device)
        }
    }

    func connectDemo() {
        tearDown()
        connectionState = .connecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            connectedDeviceName = "AOJ Thermo Demo"
            connectionState = .connected
            startDemoStream()
        }
    }

    func disconnect() {
        tearDown()
        connectionState = .disconnected
    }

    // MARK: - AHBluetoothStatusDelegate

    func systemDidBluetoothStatusChange(_ bleState: CBManagerState) {}

    // MARK: - AHDeviceDataDelegate

    func bleDevice(_ device: BTDeviceInfo, didConnectStateChanged state: BTConnectState) {
        switch state {
        case .success:
            currentDevice = device
            connectedDeviceName = device.broadcastId ?? "AOJ Thermometer"
            connectionState = .connected
        case .failure, .disconnect, .timeout:
            tearDown()
            connectionState = .disconnected
        default:
            break
        }
    }

    func bleDevice(_ device: BTDeviceInfo, didDataUpdateNotification obj: BTDeviceData) {
        guard let data = obj as? AHTempData, !data.historyMarker else { return }
        let celsius = data.temp
        let display = String(format: "%.1f", celsius)
        DispatchQueue.main.async { [weak self] in
            self?.onMeasurement?(VitalMeasurement(displayValue: display, unit: "°C"))
        }
    }

    // MARK: - Private helpers

    private func addAndConnect(_ device: BTDeviceInfo) {
        currentDevice = device
        sdk.addDevice(device)
        sdk.startAutoConnect(self)
    }

    private func tearDown() {
        demoTimer?.invalidate()
        demoTimer = nil
        demoTick = 0
        sdk.stopSearch()
        sdk.stopAutoConnect()
        if let broadcastId = currentDevice?.broadcastId {
            sdk.removeDevice(broadcastId)
        }
        sdk.bleStateDelegate = nil
        currentDevice = nil
        connectedDeviceName = nil
    }

    private func startDemoStream() {
        demoTick = 0
        demoTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            Task { @MainActor [weak self] in
                guard let self, self.connectionState == .connected else {
                    timer.invalidate()
                    return
                }
                self.demoTick += 1
                let temp = 36.5 + Double(self.demoTick % 5) * 0.1
                self.onMeasurement?(VitalMeasurement(displayValue: String(format: "%.1f", temp), unit: "°C"))
            }
        }
    }
}
