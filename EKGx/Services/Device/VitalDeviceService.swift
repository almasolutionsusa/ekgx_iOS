import Foundation

// MARK: - Protocol

// Each vital's hardware SDK wraps itself in a class conforming to this.
// Adding Echo support = create EchoVitalDeviceService: VitalDeviceServiceProtocol.
protocol VitalDeviceServiceProtocol: AnyObject {
    var connectionState: DeviceConnectionState { get }
    var connectedDeviceName: String? { get }
    var onStateChanged: ((DeviceConnectionState) -> Void)? { get set }
    func connect()
    func connectDemo()
    func disconnect()
}

// MARK: - Type Eraser

// Lets the ViewModel store heterogeneous services in a plain dictionary.
final class VitalDeviceServiceBox {

    let vitalType: VitalType

    private let _state:       () -> DeviceConnectionState
    private let _deviceName:  () -> String?
    private let _connect:     () -> Void
    private let _connectDemo: () -> Void
    private let _disconnect:  () -> Void
    private let _setCallback: (@escaping (DeviceConnectionState) -> Void) -> Void

    init<S: VitalDeviceServiceProtocol>(_ service: S, for type: VitalType) {
        self.vitalType    = type
        _state       = { service.connectionState }
        _deviceName  = { service.connectedDeviceName }
        _connect     = { service.connect() }
        _connectDemo = { service.connectDemo() }
        _disconnect  = { service.disconnect() }
        _setCallback = { service.onStateChanged = $0 }
    }

    var connectionState: DeviceConnectionState { _state() }
    var connectedDeviceName: String?            { _deviceName() }

    func connect()     { _connect() }
    func connectDemo() { _connectDemo() }
    func disconnect()  { _disconnect() }
    func observe(_ handler: @escaping (DeviceConnectionState) -> Void) { _setCallback(handler) }
}

// MARK: - EKG Implementation

// Delegates to the existing BLEDeviceService / DemoDeviceService via AppDIContainer.
final class EKGVitalDeviceService: VitalDeviceServiceProtocol {

    private let diContainer: AppDIContainer

    var onStateChanged: ((DeviceConnectionState) -> Void)?

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
