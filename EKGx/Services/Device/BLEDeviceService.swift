//
//  BLEDeviceService.swift
//  EKGx
//
//  Real iCV200BLE Bluetooth device service.
//
//  ONE vhiCVBleManager for the entire app lifetime — never recreated.
//
//  connect() flow:
//  - If already disconnected: stopScan → checkBletooth → startScan
//  - If currently connected: disconnect first, then auto-scan once fully disconnected
//  - If BT not powered on yet: set scanPending, scan from icvBleManagerBluetoothOn
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
    private(set) var connectedDeviceName: String? = nil

    private let bleManager: vhiCVBleManager   // never replaced
    private var scanPending = false
    private var scanAfterDisconnect = false    // true = start scan once disConnect callback fires

    override init() {
        bleManager = vhiCVBleManager()
        super.init()
        bleManager.delegate = self
    }

    // MARK: - DeviceServiceProtocol

    /// Re-applies filter configuration without reconnecting.
    /// Call this whenever the recording screen opens with an already-connected device
    /// so `filtersECGsData` callbacks fire even if the `.connected` event wasn't observed.
    func reconfigureFilters() {
        guard currentState == .connected else { return }
        configureFilters()
    }

    func connect() {
        switch currentState {
        case .disconnected:
            performScan()

        case .connected:
            // Disconnect first; scanAfterDisconnect will trigger scan once done.
            scanAfterDisconnect = true
            currentState = .searching
            onConnectionStateChanged?(.searching)
            bleManager.collectStop()
            bleManager.disConnect { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if self.scanAfterDisconnect {
                        self.scanAfterDisconnect = false
                        self.performScan()
                    }
                }
            }

        case .searching, .connecting:
            break
        }
    }

    func disconnect() {
        scanPending = false
        scanAfterDisconnect = false
        connectedDeviceName = nil
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

    private func performScan() {
        connectedDeviceName = nil
        bleManager.stopScan()
        bleManager.checkBletooth { [weak self] status in
            guard let self else { return }
            DispatchQueue.main.async {
                if status == .OK {
                    self.scanPending = false
                    self.currentState = .searching
                    self.onConnectionStateChanged?(.searching)
                    self.bleManager.startScan()
                } else {
                    // BT not ready — wait for icvBleManagerBluetoothOn.
                    self.scanPending = true
                    self.currentState = .searching
                    self.onConnectionStateChanged?(.searching)
                }
            }
        }
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
            self.currentState = .searching
            self.onConnectionStateChanged?(.searching)
            manager.startScan()
        }
    }

    func icvBleManager(_ manager: vhiCVBleManager, foundDeviceName name: String) {
        // Guard prevents a second foundDeviceName (same scan cycle) from calling connect() twice.
        // connectedDeviceName being set here (synchronously) also lets lostDeviceName ignore
        // the peripheral dropping out of advertisement once the connection handshake begins.
        guard connectedDeviceName == nil else { return }
        connectedDeviceName = name
        // Do NOT call stopScan() here — the SDK needs the scan active through the full
        // GATT handshake (Connecting→DiscoverChars→BuildCredits→InitDevice→Connected).
        // Stopping early causes LostDevice (status 9) to fire mid-handshake.
        // stopScan() is called in the .connected case below.
        DispatchQueue.main.async {
            self.currentState = .connecting
            self.onConnectionStateChanged?(.connecting)
        }
        manager.connect(name, isAutoCollect: true)
    }

    func icvBleManager(_ manager: vhiCVBleManager, lostDeviceName name: String) {
        // connectedDeviceName is set synchronously in foundDeviceName (no dispatch).
        // If it's already set, we've found the device and are connecting — the peripheral
        // simply stopped advertising after accepting our connection request. This is normal.
        // True disconnects are handled by icvBleManager(_:connecting:status:).
        guard connectedDeviceName == nil else { return }
        DispatchQueue.main.async {
            self.currentState = .disconnected
            self.onConnectionStateChanged?(.disconnected)
        }
    }

    func icvBleManager(_ manager: vhiCVBleManager, connecting status: vhiCVBleConnectStatus) {
        DispatchQueue.main.async {
            #if DEBUG
            print("📡 [BLE] connecting status: \(status.rawValue) → currentState: \(self.currentState)")
            #endif
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
            case .disconnectedError:
                // Connection failed — reset and auto-restart scan so user sees "Searching"
                // rather than having to press Connect again.
                self.connectedDeviceName = nil
                self.currentState = .searching
                self.onConnectionStateChanged?(.searching)
                manager.startScan()
            case .disconnected, .lostDevice:
                self.connectedDeviceName = nil
                self.currentState = .disconnected
                self.onConnectionStateChanged?(.disconnected)
            default:
                // Intermediate GATT phases (0-5): Connecting, DiscoverChars, DiscoverDescriptors,
                // BuildCredits, InitDevice, InitDeviceAgain — all mean "still handshaking".
                self.currentState = .connecting
                self.onConnectionStateChanged?(.connecting)
            }
        }
    }

    func icvBleManager(_ manager: vhiCVBleManager, data ECGs: [[NSNumber]]!) {
        guard let ECGs else { return }
        DispatchQueue.main.async {
            #if DEBUG
           // print("📡 [BLE] SDK data arrived — leads=\(ECGs.count) samples=\(ECGs.first?.count ?? 0) callbackSet=\(self.onECGData != nil)")
            #endif
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
