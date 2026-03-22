//
//  BLEDeviceService.swift
//  EKGx
//
//  Real iCV200BLE Bluetooth device service.
//  Swap into AppDIContainer by replacing DemoDeviceService with BLEDeviceService.
//

import Foundation
import iCV200BLE
import vhECGSTFilters

final class BLEDeviceService: NSObject, DeviceServiceProtocol {

    var onConnectionStateChanged: ((DeviceConnectionState) -> Void)?
    var onECGData: ((ECGLeads) -> Void)?
    var onLeadStatus: (([Bool]) -> Void)?
    var onBattery: ((Int) -> Void)?
    private(set) var currentState: DeviceConnectionState = .disconnected

    // Updated from bleManager.rate / bleManager.uVpb after device connects.
    private(set) var sampleRate: Int = 660

    private var bleManager: vhiCVBleManager

    override init() {
        bleManager = vhiCVBleManager()
        super.init()
        bleManager.delegate = self
    }

    private func resetManager() {
        bleManager.delegate = nil
        bleManager = vhiCVBleManager()
        bleManager.delegate = self
    }

    // MARK: - DeviceServiceProtocol

    func connect() {
        guard currentState == .disconnected else { return }
        bleManager.checkBletooth { [weak self] status in
            guard let self else { return }
            DispatchQueue.main.async {
                if status == .OK {
                    self.currentState = .searching
                    self.onConnectionStateChanged?(.searching)
                    self.bleManager.startScan()
                }
                // TODO: Surface .poweredOff / .unsupported / .unauthorized error to UI
            }
        }
    }

    func disconnect() {
        bleManager.stopScan()
        bleManager.collectStop()
        if currentState == .connected {
            bleManager.disConnect { [weak self] _ in
                DispatchQueue.main.async {
                    self?.resetManager()
                    self?.currentState = .disconnected
                    self?.onConnectionStateChanged?(.disconnected)
                }
            }
        } else {
            resetManager()
            currentState = .disconnected
            onConnectionStateChanged?(.disconnected)
        }
    }

    // MARK: - Private

    private func configureFilters() {
        let rate  = Double(bleManager.rate > 0 ? bleManager.rate : 660)
        let uVpb  = bleManager.uVpb > 0 ? bleManager.uVpb : 4.88
        vhECGFiltersLib.shared().setFilterWithRate(Int32(rate), uVpb: uVpb)
        vhECGFiltersLib.shared().setFilterSwitch(true)
        vhECGFiltersLib.shared().setFilterFreqNotch(.notchType_50)
        vhECGFiltersLib.shared().setFilterFreqLow(.lowType_40)
        vhECGFiltersLib.shared().setFilterFreqMooth(.smoothType_weak)
    }
}

// MARK: - vhiCVBleManagerDelegate

extension BLEDeviceService: vhiCVBleManagerDelegate {

    func icvBleManager(_ manager: vhiCVBleManager, foundDeviceName name: String) {
        manager.connect(name, isAutoCollect: true)
    }

    func icvBleManager(_ manager: vhiCVBleManager, lostDeviceName name: String) {
        DispatchQueue.main.async {
            self.currentState = .disconnected
            self.onConnectionStateChanged?(.disconnected)
        }
    }

    func icvBleManager(_ manager: vhiCVBleManager, connecting status: vhiCVBleConnectStatus) {
        DispatchQueue.main.async {
            switch status {
            case .connected:
                manager.stopScan()
                // Read actual rate + uVpb from device and reconfigure filters.
                self.sampleRate = Int(manager.rate > 0 ? manager.rate : 660)
                self.configureFilters()
                self.currentState = .connected
                self.onConnectionStateChanged?(.connected)
                // Read initial battery from property (delegate may fire later or not at all)
                if manager.batVol > 0 {
                    self.onBattery?(Int(manager.batVol))
                }
            case .disconnectedError:
                // Connection timed out or failed — recreate manager so next scan works cleanly
                self.resetManager()
                self.currentState = .disconnected
                self.onConnectionStateChanged?(.disconnected)
            case .disconnected, .lostDevice:
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

    func icvBleManager(_ manager: vhiCVBleManager, battery value: Int32) {
        DispatchQueue.main.async {
            self.onBattery?(Int(value))
        }
    }

    func icvBleManager(_ manager: vhiCVBleManager,
                       updateLeadWithI linked_I: Bool, ii linked_II: Bool, iii linked_III: Bool,
                       aVR linked_aVR: Bool, aVL linked_aVL: Bool, aVF linked_aVF: Bool,
                       v1 linked_V1: Bool, v2 linked_V2: Bool, v3 linked_V3: Bool,
                       v4 linked_V4: Bool, v5 linked_V5: Bool, v6 linked_V6: Bool) {
        let status = [linked_I, linked_II, linked_III, linked_aVR, linked_aVL, linked_aVF,
                      linked_V1, linked_V2, linked_V3, linked_V4, linked_V5, linked_V6]
        DispatchQueue.main.async {
            self.onLeadStatus?(status)
        }
    }
}
