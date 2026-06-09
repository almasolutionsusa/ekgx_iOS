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
    // Incremented by disconnect() and each performScan() — lets in-flight checkBletooth
    // callbacks detect that the scan was cancelled before they start a new scan.
    private var scanGeneration: Int = 0

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

    func stopScan() {
        guard currentState == .searching || currentState == .connecting else { return }
        scanGeneration += 1
        bleManager.stopScan()
        connectedDeviceName = nil
        currentState = .disconnected
        onConnectionStateChanged?(.disconnected)
    }

    func disconnect() {
        // Capture before we reset state — we need to know whether to call disConnect().
        let wasBusy = currentState == .connected || currentState == .connecting
        scanPending = false
        scanAfterDisconnect = false
        scanGeneration += 1          // invalidate any in-flight checkBletooth callbacks
        connectedDeviceName = nil
        bleManager.stopScan()
        bleManager.collectStop()
        // Set .disconnected synchronously so any in-flight disconnectedError callback
        // sees this state and skips auto-reconnect, preventing a zombie NSAVHCVConnect crash.
        currentState = .disconnected
        onConnectionStateChanged?(.disconnected)
        if wasBusy {
            // Abort the ongoing GATT handshake (.connecting) or clean up the active
            // connection (.connected). Without this, the SDK fires disconnectedError
            // after stopScan() which would restart the scan and create a new NSAVHCVConnect
            // while CoreBluetooth still has didDiscoverPeripheral queued on the released one.
            bleManager.disConnect { _ in }
        }
    }

    // MARK: - Private

    private func performScan() {
        // Each call gets a new generation token. disconnect() also increments it.
        // Any in-flight checkBletooth callback that sees a stale generation bails out,
        // preventing it from firing startScan() after an explicit disconnect().
        scanGeneration += 1
        let myGeneration = scanGeneration
        connectedDeviceName = nil
        bleManager.stopScan()
        bleManager.checkBletooth { [weak self] status in
            guard let self else { return }
            DispatchQueue.main.async {
                guard self.scanGeneration == myGeneration else { return }
                guard self.currentState != .connected else { return }
                if status == .OK {
                    self.scanPending = false
                    self.currentState = .searching
                    self.onConnectionStateChanged?(.searching)
                    // 250ms drain delay: CoreBluetooth queues didDiscoverPeripheral callbacks
                    // asynchronously. If startScan() creates a new NSAVHCVConnect (new delegate)
                    // while the old peripheral's callbacks are still queued, CB fires them on
                    // the freed NSAVHCVConnect pointer → crash. The delay lets CB drain that
                    // queue before a new delegate object exists.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                        guard let self,
                              self.scanGeneration == myGeneration,
                              self.currentState == .searching else { return }
                        self.bleManager.startScan()
                    }
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
                //
                // Guard: if disconnect() was already called explicitly (e.g. user pressed Back
                // from RecordingView), currentState is already .disconnected. Skip auto-reconnect
                // so we don't create a new NSAVHCVConnect → zombie crash on the queued callback.
                //
                // MUST call stopScan() before startScan(): without it the SDK creates a new
                // NSAVHCVConnect delegate while CoreBluetooth still has a queued
                // didDiscoverPeripheral addressed to the released instance → zombie crash.
                // The 250ms delay lets CoreBluetooth drain that callback queue before the
                // new scan (and new NSAVHCVConnect) is created.
                guard self.currentState != .disconnected else { return }
                self.connectedDeviceName = nil
                self.currentState = .searching
                self.onConnectionStateChanged?(.searching)
                manager.stopScan()
                self.scanGeneration += 1
                let gen = self.scanGeneration
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    guard let self,
                          self.scanGeneration == gen,
                          self.currentState == .searching else { return }
                    manager.startScan()
                }
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
