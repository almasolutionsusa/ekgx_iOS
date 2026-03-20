//
//  BLEDeviceService.swift
//  EKGx
//
//  Real iCV200BLE Bluetooth device service.
//  TODO: Implement when physical device integration is ready.
//  Swap in AppDIContainer: replace DemoDeviceService with BLEDeviceService.
//

import Foundation
import iCV200BLE

final class BLEDeviceService: NSObject, DeviceServiceProtocol {

    var onConnectionStateChanged: ((DeviceConnectionState) -> Void)?
    var onECGData: ((ECGLeads) -> Void)?
    private(set) var currentState: DeviceConnectionState = .disconnected

    private lazy var bleManager: vhiCVBleManager = {
        let m = vhiCVBleManager()
        m.delegate = self
        return m
    }()

    func connect() {
        bleManager.checkBletooth { [weak self] status in
            guard let self else { return }
            if status == .OK {
                DispatchQueue.main.async {
                    self.onConnectionStateChanged?(.searching)
                    self.bleManager.startScan()
                }
            }
            // TODO: Surface Bluetooth unavailable error to UI for other statuses
        }
    }

    func disconnect() {
        bleManager.stopScan()
        bleManager.disConnect { [weak self] _ in
            DispatchQueue.main.async {
                self?.onConnectionStateChanged?(.disconnected)
            }
        }
    }
}

// MARK: - vhiCVBleManagerDelegate

extension BLEDeviceService: vhiCVBleManagerDelegate {

    func icvBleManager(_ manager: vhiCVBleManager, foundDeviceName name: String) {
        // Auto-connect to first found device
        manager.stopScan()
        manager.connect(name, isAutoCollect: true)
    }

    func icvBleManager(_ manager: vhiCVBleManager, lostDeviceName name: String) {
        DispatchQueue.main.async {
            self.onConnectionStateChanged?(.disconnected)
        }
    }

    func icvBleManager(_ manager: vhiCVBleManager, connecting status: vhiCVBleConnectStatus) {
        DispatchQueue.main.async {
            switch status {
            case .connected:
                self.currentState = .connected
                self.onConnectionStateChanged?(.connected)
            case .disconnected, .disconnectedError, .lostDevice:
                self.currentState = .disconnected
                self.onConnectionStateChanged?(.disconnected)
            default:
                self.currentState = .searching
                self.onConnectionStateChanged?(.searching)
            }
        }
    }

    func icvBleManager(_ manager: vhiCVBleManager, data ECGs: [[NSNumber]]!) {
        guard let ECGs else { return }
        DispatchQueue.main.async {
            self.onECGData?(ECGs)
        }
    }
}
