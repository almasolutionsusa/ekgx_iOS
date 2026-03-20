//
//  DemoDeviceService.swift
//  EKGx
//
//  Simulates a connected ECG device by streaming real pre-recorded 12-lead ECG
//  data from ecg_demo.plist (10s @ 660Hz, loops continuously).
//
//  Data format is identical to live iCV200BLE device callbacks:
//  [[NSNumber]] — 12 leads (I, II, III, aVR, aVL, aVF, V1–V6), N samples each.
//

import Foundation

final class DemoDeviceService: DeviceServiceProtocol {

    var onConnectionStateChanged: ((DeviceConnectionState) -> Void)?
    var onECGData: ((ECGLeads) -> Void)?
    private(set) var currentState: DeviceConnectionState = .disconnected

    // Matches ecg.plist source device — 660 Hz, 25 samples per ~38ms tick
    let sampleRate: Int = 660
    private let batchSize: Int = 25

    private var ecgData: ECGLeads = []   // 12 leads × 6600 samples
    private var sampleIndex: Int = 0
    private var timer: Timer?

    func connect() {
        guard currentState == .disconnected else { return }
        currentState = .searching
        onConnectionStateChanged?(.searching)
        loadDemoData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            self.currentState = .connected
            self.startStreaming()
            self.onConnectionStateChanged?(.connected)
        }
    }

    func disconnect() {
        stopStreaming()
        currentState = .disconnected
        onConnectionStateChanged?(.disconnected)
    }

    // MARK: - Private

    private func loadDemoData() {
        guard let path = Bundle.main.path(forResource: "ecg_demo", ofType: "plist"),
              let raw = NSArray(contentsOfFile: path) as? [[NSNumber]],
              raw.count == 12 else {
            return
        }
        ecgData = raw
    }

    private func startStreaming() {
        guard !ecgData.isEmpty else { return }
        sampleIndex = 0

        let interval = Double(batchSize) / Double(sampleRate)   // ~0.038s
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.deliverNextBatch()
        }
    }

    private func stopStreaming() {
        timer?.invalidate()
        timer = nil
        sampleIndex = 0
    }

    private func deliverNextBatch() {
        let totalSamples = ecgData[0].count
        let end = min(sampleIndex + batchSize, totalSamples)
        let count = end - sampleIndex

        var batch: ECGLeads = []
        for lead in ecgData {
            batch.append(Array(lead[sampleIndex..<end]))
        }

        onECGData?(batch)

        sampleIndex += count
        if sampleIndex >= totalSamples {
            sampleIndex = 0   // loop
        }
    }
}
