import Foundation

// MARK: - VitalMeasurement

struct VitalMeasurement {
    let displayValue: String
    let unit: String
    var systolic: Int?         = nil
    var diastolic: Int?        = nil
    var pulseRate: Int?        = nil
    var bodyFatPercent: Double? = nil
}

// MARK: - Protocol

protocol VitalDeviceServiceProtocol: AnyObject {
    var connectionState: DeviceConnectionState { get }
    var connectedDeviceName: String? { get }
    var onStateChanged:   ((DeviceConnectionState) -> Void)? { get set }
    var onMeasurement:    ((VitalMeasurement) -> Void)?       { get set }
    func connect()
    func connectDemo()
    func disconnect()
}

// MARK: - Type Eraser

final class VitalDeviceServiceBox {

    let vitalType: VitalType

    private let _state:                  () -> DeviceConnectionState
    private let _deviceName:             () -> String?
    private let _connect:                () -> Void
    private let _connectDemo:            () -> Void
    private let _disconnect:             () -> Void
    private let _setStateCallback:       (@escaping (DeviceConnectionState) -> Void) -> Void
    private let _setMeasurementCallback: (@escaping (VitalMeasurement) -> Void) -> Void

    init<S: VitalDeviceServiceProtocol>(_ service: S, for type: VitalType) {
        self.vitalType             = type
        _state                    = { service.connectionState }
        _deviceName               = { service.connectedDeviceName }
        _connect                  = { service.connect() }
        _connectDemo              = { service.connectDemo() }
        _disconnect               = { service.disconnect() }
        _setStateCallback         = { service.onStateChanged = $0 }
        _setMeasurementCallback   = { service.onMeasurement = $0 }
    }

    var connectionState: DeviceConnectionState { _state() }
    var connectedDeviceName: String?            { _deviceName() }

    func connect()     { _connect() }
    func connectDemo() { _connectDemo() }
    func disconnect()  { _disconnect() }

    func observe(_ handler: @escaping (DeviceConnectionState) -> Void) {
        _setStateCallback(handler)
    }

    func observeMeasurement(_ handler: @escaping (VitalMeasurement) -> Void) {
        _setMeasurementCallback(handler)
    }
}

// MARK: - EKG Implementation

final class EKGVitalDeviceService: VitalDeviceServiceProtocol {

    private let diContainer: AppDIContainer

    var onStateChanged:  ((DeviceConnectionState) -> Void)?
    var onMeasurement:   ((VitalMeasurement) -> Void)?

    var connectionState: DeviceConnectionState {
        diContainer.deviceService.currentState
    }

    var connectedDeviceName: String? {
        diContainer.deviceService.connectedDeviceName
    }

    init(diContainer: AppDIContainer) {
        self.diContainer = diContainer
    }

    func connect() {
        diContainer.switchToRealDevice()
        wire()
        diContainer.deviceService.connect()
    }

    func connectDemo() {
        diContainer.switchToDemo()
        wire()
        diContainer.deviceService.connect()
    }

    func disconnect() {
        diContainer.deviceService.disconnect()
    }

    private func wire() {
        diContainer.deviceService.onConnectionStateChanged = { [weak self] state in
            self?.onStateChanged?(state)
        }
    }
}
