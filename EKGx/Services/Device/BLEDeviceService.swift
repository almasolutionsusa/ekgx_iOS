//
//  BLEDeviceService.swift
//  EKGx
//
//  Real iCV200BLE Bluetooth device service.
//
//  Crash root cause: replacing vhiCVBleManager while its internal CBCentralManager
//  is mid-scan causes NSAVHCVConnect to receive callbacks after dealloc →
//  "unrecognized selector" crash.
//
//  Rules:
//  1. ONE vhiCVBleManager for the entire app lifetime — never recreated.
//  2. To re-scan: stopScan → short delay → startScan on the same instance.
//  3. hardReset() is permanently removed.
//  4. scanPending handles the case where BT is not yet powered on at connect() time.
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
    private(set) var sampleRate: Int = 660

    private let bleManager: vhiCVBleManager   // never replaced
    private var scanPending = false

    override init() {
        bleManager = vhiCVBleManager()
        super.init()
        bleManager.delegate = self
    }

    // MARK: - DeviceServiceProtocol

    func connect() {
        guard currentState == .disconnected else { return }

        // Stop any lingering scan on the same instance, then re-scan after a
        // brief yield so the SDK's internal CBCentralManager settles.
        bleManager.stopScan()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            self.bleManager.checkBletooth { [weak self] status in
                guard let self else { return }
                DispatchQueue.main.async {
                    if status == .OK {
                        self.scanPending = false
                        self.startScan()
                    } else {
                        // BT not ready — wait for icvBleManagerBluetoothOn callback.
                        self.scanPending = true
                        self.currentState = .searching
                        self.onConnectionStateChanged?(.searching)
                    }
                }
            }
        }
    }

    func disconnect() {
        scanPending = false
        bleManager.stopScan()
        bleManager.collectStop()
        if currentState == .connected {
            bleManager.disConnect { [weak self] _ in
                DispatchQueue.main.async {
                    self?.currentState = .disconnected
                    self?.onConnectionStateChanged?(.disconnected)
                }
            }
        } else {
            currentState = .disconnected
            onConnectionStateChanged?(.disconnected)
        }
    }

    // MARK: - Private

    private func startScan() {
        currentState = .searching
        onConnectionStateChanged?(.searching)
        bleManager.startScan()
    }

    private func configureFilters() {
        let rate = Double(bleManager.rate > 0 ? bleManager.rate : 660)
        let uVpb = bleManager.uVpb > 0 ? bleManager.uVpb : 4.88
        vhECGFiltersLib.shared().setFilterWithRate(Int32(rate), uVpb: uVpb)
        vhECGFiltersLib.shared().setFilterSwitch(true)
        vhECGFiltersLib.shared().setFilterFreqNotch(.notchType_50)
        vhECGFiltersLib.shared().setFilterFreqLow(.lowType_40)
        vhECGFiltersLib.shared().setFilterFreqMooth(.smoothType_weak)
    }
}

// MARK: - vhiCVBleManagerDelegate

extension BLEDeviceService: vhiCVBleManagerDelegate {

    func icvBleManagerBluetoothOn(_ manager: vhiCVBleManager) {
        DispatchQueue.main.async {
            guard self.scanPending else { return }
            self.scanPending = false
            self.startScan()
        }
    }

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
                self.sampleRate = Int(manager.rate > 0 ? manager.rate : 660)
                self.configureFilters()
                self.currentState = .connected
                self.onConnectionStateChanged?(.connected)
                if manager.batVol > 0 {
                    self.onBattery?(Int(manager.batVol))
                }
            case .disconnectedError, .disconnected, .lostDevice:
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
