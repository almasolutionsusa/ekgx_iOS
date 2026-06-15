import Foundation
import SwiftUI

// MARK: - Vital Save States

enum BPSaveState:   Equatable { case idle, saved }
enum SpO2SaveState: Equatable { case idle, saved }
enum TempSaveState: Equatable { case idle, saved }
enum RRSaveState:   Equatable { case idle, saved }
enum PainSaveState: Equatable { case idle, saved }

// MARK: - SpO2 History Item

struct SpO2HistoryItem: Identifiable {
    let id: String
    let displayValue: String
    let pulseRate: Int?
    let formattedDate: String
    let formattedTime: String
}

// MARK: - Temp History Item

struct TempHistoryItem: Identifiable {
    let id: String
    let displayValue: String
    let formattedDate: String
    let formattedTime: String
}

// MARK: - RR History Item

struct RRHistoryItem: Identifiable {
    let id: String
    let displayValue: String
    let formattedDate: String
    let formattedTime: String
}

// MARK: - Pain History Item

struct PainHistoryItem: Identifiable {
    let id: String
    let displayValue: String
    let formattedDate: String
    let formattedTime: String
}

// MARK: - VitalsViewModel

@Observable
@MainActor
final class VitalsViewModel {

    // MARK: - Dependencies

    let patient: Patient
    private let router: AppRouter
    private let diContainer: AppDIContainer
    private let appInfoService: AppInfoService

    // MARK: - Device Registry

    // One box per vital type. New vitals: register in setUp().
    private var registry: [VitalType: VitalDeviceServiceBox] = [:]

    // Observable connection states — updated via service callbacks.
    var connectionStates: [VitalType: DeviceConnectionState] = [:]

    // Scan timeout tasks — cancelled when device connects, fires after 50 s to stop scan.
    @ObservationIgnored private var scanTimeoutTasks: [VitalType: Task<Void, Never>] = [:]
    private static let scanTimeoutSeconds: UInt64 = 50

    // Device measurements — updated whenever a service fires new data.
    var measurements: [VitalType: VitalMeasurement] = [:]

    // MARK: - Weight Scan

    // Direct reference kept so the scan picker can call selectDevice
    @ObservationIgnored private var weightService: WeightVitalDeviceService?
    var weightScanDevices: [WeightDeviceInfo] = []

    func selectWeightDevice(_ info: WeightDeviceInfo) {
        weightService?.selectDevice(info)
    }

    // MARK: - Sheet State

    var selectedVital: VitalType? = nil
    var showConnectSheet: Bool = false
    var showWeightPopover: Bool = false

    // MARK: - Manual Entry Sheets

    var showManualBPEntry:   Bool = false
    var showManualSpO2Entry: Bool = false
    var showManualTempEntry: Bool = false
    var showManualPREntry:   Bool = false

    // Tracks vitals entered manually so the source label says "Manual"
    var manualEntryVitals: Set<VitalType> = []

    func openManualEntry(for type: VitalType) {
        switch type {
        case .bloodPressure:    showManualBPEntry   = true
        case .oxygenSaturation: showManualSpO2Entry = true
        case .temperature:      showManualTempEntry = true
        case .heartRate:        showManualPREntry   = true
        default: break
        }
    }

    func saveManualBP(systolic: Int, diastolic: Int, pulseRate: Int?) {
        var m = VitalMeasurement(displayValue: "\(systolic)/\(diastolic)", unit: "mmHg")
        m.systolic  = systolic
        m.diastolic = diastolic
        m.pulseRate = pulseRate
        measurements[.bloodPressure] = m
        if let pr = pulseRate {
            measurements[.heartRate] = VitalMeasurement(displayValue: "\(pr)", unit: "BPM")
            manualEntryVitals.insert(.heartRate)
        }
        manualEntryVitals.insert(.bloodPressure)
        showManualBPEntry = false

        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let reading = BPRecording(
            id:            UUID().uuidString,
            patientId:     pid,
            patientName:   patient.fullName,
            patientDob:    patient.birthDate,
            patientGender: patient.gender,
            patientMrn:    patient.medicalRecordNumber,
            recordedAt:    Date(),
            systolic:      systolic,
            diastolic:     diastolic,
            pulseRate:     pulseRate,
            username:      diContainer.authService.currentUser?.username,
            arm:           bpArm,
            position:      bpPosition
        )
        diContainer.bpStore.save(reading)
        loadBPHistory()
        print("✅ Manual BP saved: \(systolic)/\(diastolic) for \(patient.fullName)")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { bpSaveState = .saved }
        bpSaveTask?.cancel()
        bpSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.spring(duration: 0.3)) { self?.bpSaveState = .idle }
        }
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadBP(
                systolic: systolic, diastolic: diastolic, pulseRate: pulseRate,
                patient: patient, deviceName: nil,
                arm: bpArm, position: bpPosition,
                methodOverride: "Manual"
            )
            if let pr = pulseRate {
                try? await self.diContainer.vitalsUploadService.uploadHeartRate(
                    bpm: pr, patient: patient, deviceName: nil
                )
            }
        }
    }

    func saveManualSpO2(value: Int, pulseRate: Int?) {
        var m = VitalMeasurement(displayValue: "\(value)", unit: "%")
        m.pulseRate = pulseRate
        measurements[.oxygenSaturation] = m
        if let pr = pulseRate {
            measurements[.heartRate] = VitalMeasurement(displayValue: "\(pr)", unit: "BPM")
            manualEntryVitals.insert(.heartRate)
        }
        manualEntryVitals.insert(.oxygenSaturation)
        showManualSpO2Entry = false

        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let reading = SpO2Reading(
            id:            UUID().uuidString,
            patientId:     pid,
            patientName:   patient.fullName,
            patientDob:    patient.birthDate,
            patientGender: patient.gender,
            patientMrn:    patient.medicalRecordNumber,
            recordedAt:    Date(),
            value:         value,
            pulseRate:     pulseRate,
            unit:          "%",
            username:      diContainer.authService.currentUser?.username
        )
        diContainer.spo2Store.save(reading)
        loadSpO2History()
        print("✅ Manual SpO2 saved: \(value)% for \(patient.fullName)")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { spo2SaveState = .saved }
        spo2SaveTask?.cancel()
        spo2SaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.spring(duration: 0.3)) { self?.spo2SaveState = .idle }
        }
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadSpO2(
                value: value, pulseRate: pulseRate,
                patient: patient, deviceName: nil,
                methodOverride: "Manual"
            )
            if let pr = pulseRate {
                try? await self.diContainer.vitalsUploadService.uploadHeartRate(
                    bpm: pr, patient: patient, deviceName: nil
                )
            }
        }
    }

    func saveManualTemp(value: Double, unit: String) {
        measurements[.temperature] = VitalMeasurement(displayValue: String(format: "%.1f", value), unit: unit)
        manualEntryVitals.insert(.temperature)
        showManualTempEntry = false

        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let reading = TempReading(
            id:            UUID().uuidString,
            patientId:     pid,
            patientName:   patient.fullName,
            patientDob:    patient.birthDate,
            patientGender: patient.gender,
            patientMrn:    patient.medicalRecordNumber,
            recordedAt:    Date(),
            value:         value,
            unit:          unit,
            username:      diContainer.authService.currentUser?.username
        )
        diContainer.tempStore.save(reading)
        loadTempHistory()
        print("✅ Manual Temp saved: \(String(format: "%.1f", value)) \(unit) for \(patient.fullName)")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { tempSaveState = .saved }
        tempSaveTask?.cancel()
        tempSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.spring(duration: 0.3)) { self?.tempSaveState = .idle }
        }
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadTemp(
                value: value, unit: unit,
                patient: patient, deviceName: nil,
                methodOverride: "Manual"
            )
        }
    }

    func saveManualPR(bpm: Int) {
        measurements[.heartRate] = VitalMeasurement(displayValue: "\(bpm)", unit: "BPM")
        manualEntryVitals.insert(.heartRate)
        showManualPREntry = false
        print("✅ Manual PR saved: \(bpm) BPM for \(patient.fullName)")
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadHeartRate(
                bpm: bpm, patient: patient, deviceName: nil
            )
        }
    }

    // MARK: - Pain Level

    var showPainLevelPicker: Bool = false
    var painLevel: Int? = nil
    var painSaveState: PainSaveState = .idle
    @ObservationIgnored private var painSaveTask: Task<Void, Never>?
    var painHistory: [PainHistoryItem] = []

    func openPainLevel() { showPainLevelPicker = true }

    func savePainLevel(_ level: Int) {
        painLevel = level
        showPainLevelPicker = false
        measurements[.painLevel] = VitalMeasurement(displayValue: "\(level)", unit: "/10")
        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let reading = PainReading(
            id:           UUID().uuidString,
            patientId:    pid,
            patientName:  patient.fullName,
            patientDob:   patient.birthDate,
            patientGender: patient.gender,
            patientMrn:   patient.medicalRecordNumber,
            recordedAt:   Date(),
            value:        level,
            username:     diContainer.authService.currentUser?.username
        )
        diContainer.painStore.save(reading)
        loadPainHistory()
        print("✅ Pain level saved: \(level)/10 for \(patient.fullName)")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { painSaveState = .saved }
        painSaveTask?.cancel()
        painSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.spring(duration: 0.3)) { self?.painSaveState = .idle }
        }
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadPain(value: level, patient: patient)
        }
    }

    private func loadPainHistory() {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        let readings = pid.isEmpty ? [] : Array(diContainer.painStore.readings(for: pid).prefix(20))
        painHistory = readings.map { r in
            PainHistoryItem(
                id:            r.id,
                displayValue:  r.displayValue,
                formattedDate: r.formattedDate,
                formattedTime: r.formattedTime
            )
        }
    }

    // MARK: - Height

    var showHeightPicker: Bool = false
    var heightCm: Double? = nil
    var heightDisplay: String? = nil

    func openHeight() { showHeightPicker = true }
    func saveHeight(_ cm: Double, display: String) {
        heightCm = cm; heightDisplay = display; showHeightPicker = false
        measurements[.height] = VitalMeasurement(displayValue: display, unit: "")
        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let reading = HeightReading(
            id:           UUID().uuidString,
            patientId:    pid,
            patientName:  patient.fullName,
            patientDob:   patient.birthDate,
            patientGender: patient.gender,
            patientMrn:   patient.medicalRecordNumber,
            recordedAt:   Date(),
            valueCm:      cm,
            displayValue: display,
            username:     diContainer.authService.currentUser?.username
        )
        diContainer.heightStore.save(reading)
        print("✅ Height saved: \(display) for \(patient.fullName)")
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadHeight(valueCm: cm, patient: patient)
        }
    }

    // MARK: - Weight

    var showWeightPicker: Bool = false
    var weightKg: Double? = nil
    var weightDisplay: String? = nil

    func openWeight() { showWeightPicker = true }
    func saveWeight(_ value: Double, unit: String, display: String) {
        weightKg      = unit == "lb" ? value / 2.2046 : value
        weightDisplay = display
        showWeightPicker  = false
        showWeightPopover = false
        measurements[.weight] = VitalMeasurement(displayValue: String(format: "%.1f", value), unit: unit)
        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let deviceName = connectedDeviceName(for: .weight)
        let reading = WeightReading(
            id:           UUID().uuidString,
            patientId:    pid,
            patientName:  patient.fullName,
            patientDob:   patient.birthDate,
            patientGender: patient.gender,
            patientMrn:   patient.medicalRecordNumber,
            recordedAt:   Date(),
            value:        value,
            unit:         unit,
            deviceName:   deviceName,
            username:     diContainer.authService.currentUser?.username
        )
        diContainer.weightStore.save(reading)
        print("✅ Weight saved: \(display) for \(patient.fullName)")
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadWeight(
                value: value, unit: unit, patient: patient, deviceName: deviceName
            )
        }
    }

    // MARK: - BP History (last 3 readings shown in the vitals card)

    var bpHistory: [BPHistoryItem] = []

    private func loadBPHistory() {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        let readings = pid.isEmpty ? [] : Array(diContainer.bpStore.readings(for: pid).prefix(20))
        bpHistory = readings.map { r in
            BPHistoryItem(
                id:            r.id,
                displayValue:  r.displayValue,
                riskColor:     bpRiskColor(r.riskLevel),
                riskLabel:     r.riskLevel.label,
                pulseRate:     r.pulseRate,
                formattedDate: r.formattedDate,
                formattedTime: r.formattedTime,
                armLabel:      r.arm?.label,
                positionLabel: r.position?.shortLabel
            )
        }
    }

    private func bpRiskColor(_ level: BPRiskLevel) -> Color {
        switch level {
        case .normal:      return AppColors.statusSuccess
        case .elevated:    return Color(red: 0.86, green: 0.72, blue: 0.10)
        case .highStage1:  return Color(red: 0.95, green: 0.50, blue: 0.10)
        case .highStage2:  return AppColors.statusCritical
        case .crisis:      return Color(red: 0.65, green: 0.05, blue: 0.05)
        }
    }

    // MARK: - BP Arm & Position

    var bpArm: BPArm = .right
    var bpPosition: BPPosition = .sitting

    // MARK: - BP Save

    var bpSaveState: BPSaveState = .idle
    @ObservationIgnored private var bpSaveTask: Task<Void, Never>?

    // MARK: - BP Sensor Error

    var bpSensorError: Bool = false
    @ObservationIgnored private var bpErrorTask: Task<Void, Never>?

    var hasCompleteBPReading: Bool {
        let m = measurements[.bloodPressure]
        return m?.systolic != nil && m?.diastolic != nil
    }

    func saveBPReading() {
        guard let m = measurements[.bloodPressure],
              let sys = m.systolic, let dia = m.diastolic else { return }
        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let reading = BPRecording(
            id:           UUID().uuidString,
            patientId:    pid,
            patientName:  patient.fullName,
            patientDob:   patient.birthDate,
            patientGender: patient.gender,
            patientMrn:   patient.medicalRecordNumber,
            recordedAt:   Date(),
            systolic:     sys,
            diastolic:    dia,
            pulseRate:    m.pulseRate,
            username:     diContainer.authService.currentUser?.username,
            arm:          bpArm,
            position:     bpPosition
        )
        diContainer.bpStore.save(reading)
        loadBPHistory()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { bpSaveState = .saved }
        bpSaveTask?.cancel()
        bpSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.spring(duration: 0.3)) { self?.bpSaveState = .idle }
        }
        let deviceName = connectedDeviceName(for: .bloodPressure)
        let pulseRate  = m.pulseRate
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadBP(
                systolic: sys, diastolic: dia, pulseRate: pulseRate,
                patient: patient, deviceName: deviceName,
                arm: bpArm, position: bpPosition
            )
            if let pr = pulseRate {
                try? await self.diContainer.vitalsUploadService.uploadHeartRate(
                    bpm: pr, patient: patient, deviceName: deviceName
                )
            }
        }
    }

    // MARK: - SpO2 Save

    var spo2SaveState: SpO2SaveState = .idle
    @ObservationIgnored private var spo2SaveTask: Task<Void, Never>?
    var spo2History: [SpO2HistoryItem] = []

    var hasCompleteSpO2Reading: Bool {
        guard let m = measurements[.oxygenSaturation] else { return false }
        return Int(m.displayValue) != nil
    }

    func saveSpO2Reading() {
        guard let m = measurements[.oxygenSaturation],
              let val = Int(m.displayValue) else { return }
        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let reading = SpO2Reading(
            id:           UUID().uuidString,
            patientId:    pid,
            patientName:  patient.fullName,
            patientDob:   patient.birthDate,
            patientGender: patient.gender,
            patientMrn:   patient.medicalRecordNumber,
            recordedAt:   Date(),
            value:        val,
            pulseRate:    m.pulseRate,
            unit:         m.unit.isEmpty ? "%" : m.unit,
            username:     diContainer.authService.currentUser?.username
        )
        diContainer.spo2Store.save(reading)
        loadSpO2History()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { spo2SaveState = .saved }
        spo2SaveTask?.cancel()
        spo2SaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.spring(duration: 0.3)) { self?.spo2SaveState = .idle }
        }
        let deviceName = connectedDeviceName(for: .oxygenSaturation)
        let pulseRate  = m.pulseRate
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadSpO2(
                value: val, pulseRate: pulseRate,
                patient: patient, deviceName: deviceName
            )
            if let pr = pulseRate {
                try? await self.diContainer.vitalsUploadService.uploadHeartRate(
                    bpm: pr, patient: patient, deviceName: deviceName
                )
            }
        }
    }

    private func loadSpO2History() {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        let readings = pid.isEmpty ? [] : Array(diContainer.spo2Store.readings(for: pid).prefix(20))
        spo2History = readings.map { r in
            SpO2HistoryItem(
                id:           r.id,
                displayValue: r.displayValue,
                pulseRate:    r.pulseRate,
                formattedDate: r.formattedDate,
                formattedTime: r.formattedTime
            )
        }
    }

    // MARK: - Temp Save

    var tempSaveState: TempSaveState = .idle
    @ObservationIgnored private var tempSaveTask: Task<Void, Never>?
    var tempHistory: [TempHistoryItem] = []

    var hasCompleteTempReading: Bool {
        guard let m = measurements[.temperature] else { return false }
        return Double(m.displayValue) != nil
    }

    func saveTempReading() {
        guard let m = measurements[.temperature],
              let val = Double(m.displayValue) else { return }
        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let reading = TempReading(
            id:           UUID().uuidString,
            patientId:    pid,
            patientName:  patient.fullName,
            patientDob:   patient.birthDate,
            patientGender: patient.gender,
            patientMrn:   patient.medicalRecordNumber,
            recordedAt:   Date(),
            value:        val,
            unit:         m.unit.isEmpty ? "°C" : m.unit,
            username:     diContainer.authService.currentUser?.username
        )
        diContainer.tempStore.save(reading)
        loadTempHistory()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { tempSaveState = .saved }
        tempSaveTask?.cancel()
        tempSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.spring(duration: 0.3)) { self?.tempSaveState = .idle }
        }
        let unit       = m.unit.isEmpty ? "°C" : m.unit
        let deviceName = connectedDeviceName(for: .temperature)
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadTemp(
                value: val, unit: unit,
                patient: patient, deviceName: deviceName
            )
        }
    }

    private func loadTempHistory() {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        let readings = pid.isEmpty ? [] : Array(diContainer.tempStore.readings(for: pid).prefix(20))
        tempHistory = readings.map { r in
            TempHistoryItem(
                id:           r.id,
                displayValue: r.displayValue,
                formattedDate: r.formattedDate,
                formattedTime: r.formattedTime
            )
        }
    }

    // MARK: - Respirations

    var rrSaveState: RRSaveState = .idle
    @ObservationIgnored private var rrSaveTask: Task<Void, Never>?
    var rrHistory: [RRHistoryItem] = []

    func saveRR(_ value: Int) {
        measurements[.respirations] = VitalMeasurement(displayValue: "\(value)", unit: "rpm")
        let pid = patient.patientId ?? patient.uniqueId ?? UUID().uuidString
        let reading = RRReading(
            id:           UUID().uuidString,
            patientId:    pid,
            patientName:  patient.fullName,
            patientDob:   patient.birthDate,
            patientGender: patient.gender,
            patientMrn:   patient.medicalRecordNumber,
            recordedAt:   Date(),
            value:        value,
            username:     diContainer.authService.currentUser?.username
        )
        diContainer.rrStore.save(reading)
        loadRRHistory()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { rrSaveState = .saved }
        rrSaveTask?.cancel()
        rrSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation(.spring(duration: 0.3)) { self?.rrSaveState = .idle }
        }
        guard !diContainer.isLocalMode else { return }
        Task {
            try? await self.diContainer.vitalsUploadService.uploadRR(value: value, patient: patient)
        }
    }

    private func loadRRHistory() {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        let readings = pid.isEmpty ? [] : Array(diContainer.rrStore.readings(for: pid).prefix(20))
        rrHistory = readings.map { r in
            RRHistoryItem(
                id:           r.id,
                displayValue: r.displayValue,
                formattedDate: r.formattedDate,
                formattedTime: r.formattedTime
            )
        }
    }

    // MARK: - Init

    init(patient: Patient, router: AppRouter, diContainer: AppDIContainer, appInfoService: AppInfoService) {
        self.patient        = patient
        self.router         = router
        self.diContainer    = diContainer
        self.appInfoService = appInfoService
    }

    // MARK: - Lifecycle

    func activate() {
        setUp()
        loadBPHistory()
        loadSpO2History()
        loadTempHistory()
        loadRRHistory()
        loadPainHistory()
    }

    // Register all known device services here.
    // To add Echo: create EchoVitalDeviceService and register it for .echo.
    private func setUp() {
        let ekgService = EKGVitalDeviceService(diContainer: diContainer)
        register(ekgService, for: .ekg)
        if diContainer.isDemoMode { ekgService.connect() }

        register(diContainer.bpVitalService,   for: .bloodPressure)
        register(diContainer.spo2VitalService, for: .oxygenSaturation)
        register(diContainer.tempVitalService, for: .temperature)

        let ws = diContainer.weightVitalService
        weightService = ws
        ws.onScanDevicesChanged = { [weak self] devices in
            DispatchQueue.main.async { self?.weightScanDevices = devices }
        }
        register(ws, for: .weight)
        // Wrap the box callback: BLE measurement also auto-saves to the patient weight pill
        let boxHandler = ws.onMeasurement
        ws.onMeasurement = { [weak self] measurement in
            boxHandler?(measurement)
            guard let kg = Double(measurement.displayValue) else { return }
            DispatchQueue.main.async {
                self?.weightKg = kg
                self?.weightDisplay = "\(measurement.displayValue) \(measurement.unit)"
            }
        }
    }

    private func register(_ service: some VitalDeviceServiceProtocol, for type: VitalType) {
        let box = VitalDeviceServiceBox(service, for: type)
        box.observe { [weak self] state in
            withAnimation { self?.connectionStates[type] = state }
            switch state {
            case .connected:
                self?.showConnectSheet = false
                self?.cancelScanTimeout(for: type)
            case .searching, .connecting:
                self?.startScanTimeout(for: type)
            case .disconnected:
                self?.cancelScanTimeout(for: type)
            }
        }
        box.observeMeasurement { [weak self] measurement in
            // Convert temperature from device °C to user's preferred unit
            var measurement = measurement
            if type == .temperature,
               (UserDefaults.standard.string(forKey: "app.temperatureUnit") ?? "°F") == "°F",
               let celsius = Double(measurement.displayValue) {
                let fahrenheit = celsius * 9.0 / 5.0 + 32.0
                measurement = VitalMeasurement(displayValue: String(format: "%.1f", fahrenheit), unit: "°F")
            }

            // Reject obviously invalid BP sensor values (> 1000 mmHg is a device error)
            if type == .bloodPressure {
                let sysValue  = measurement.systolic ?? 0
                let diaValue  = measurement.diastolic ?? 0
                let cuffValue = Int(measurement.displayValue.components(separatedBy: "/").first ?? "") ?? 0
                let maxRaw    = max(sysValue, diaValue, cuffValue)
                if maxRaw > 1000 {
                    withAnimation { self?.bpSensorError = true }
                    self?.bpErrorTask?.cancel()
                    self?.bpErrorTask = Task { @MainActor [weak self] in
                        try? await Task.sleep(nanoseconds: 4_000_000_000)
                        withAnimation { self?.bpSensorError = false }
                    }
                    return
                }
                // Valid reading — clear any prior error
                if self?.bpSensorError == true {
                    withAnimation { self?.bpSensorError = false }
                    self?.bpErrorTask?.cancel()
                }
            }

            withAnimation { self?.measurements[type] = measurement }
            // New complete BP reading — reset save state so user can save again
            // Guard: don't interrupt the "Saved" confirmation while it's showing
            if type == .bloodPressure, measurement.systolic != nil, self?.bpSaveState != .saved {
                self?.bpSaveTask?.cancel()
                withAnimation { self?.bpSaveState = .idle }
            }
            if type == .oxygenSaturation, Int(measurement.displayValue) != nil, self?.spo2SaveState != .saved {
                self?.spo2SaveTask?.cancel()
                withAnimation { self?.spo2SaveState = .idle }
            }
            if type == .temperature, Double(measurement.displayValue) != nil, self?.tempSaveState != .saved {
                self?.tempSaveTask?.cancel()
                withAnimation { self?.tempSaveState = .idle }
            }
            // Heart rate reported by BP/SpO2 also populates the HR card
            if let pr = measurement.pulseRate {
                withAnimation {
                    self?.measurements[.heartRate] = VitalMeasurement(
                        displayValue: "\(pr)", unit: "BPM"
                    )
                }
            }
        }
        connectionStates[type] = service.connectionState
        registry[type] = box
    }

    // MARK: - Scan Timeout

    private func startScanTimeout(for type: VitalType) {
        guard scanTimeoutTasks[type] == nil else { return }
        scanTimeoutTasks[type] = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: VitalsViewModel.scanTimeoutSeconds * 1_000_000_000)
            guard let self, !Task.isCancelled else { return }
            let state = connectionStates[type] ?? .disconnected
            guard state == .searching || state == .connecting else { return }
            print("⏱ Scan timeout for \(type) — stopping after \(VitalsViewModel.scanTimeoutSeconds)s")
            registry[type]?.disconnect()
            withAnimation { connectionStates[type] = .disconnected }
            scanTimeoutTasks[type] = nil
        }
    }

    private func cancelScanTimeout(for type: VitalType) {
        scanTimeoutTasks[type]?.cancel()
        scanTimeoutTasks[type] = nil
    }

    // MARK: - Computed

    var isDemoMode: Bool { diContainer.isDemoMode }
    var facilityName: String { appInfoService.cached?.facilityName ?? "EKGx" }
    var patientName: String  { patient.fullName }

    func connectionState(for type: VitalType) -> DeviceConnectionState {
        connectionStates[type] ?? .disconnected
    }

    func connectedDeviceName(for type: VitalType) -> String? {
        registry[type]?.connectedDeviceName
    }

    // MARK: - Connect

    func startConnect(for type: VitalType) {
        switch connectionState(for: type) {
        case .disconnected:
            selectedVital = type
            registry[type]?.connect()
            // Weight uses a popover anchored on the pill
            if type == .weight { showWeightPopover = true }
        case .connected:
            registry[type]?.disconnect()
            withAnimation { connectionStates[type] = .disconnected }
        case .searching, .connecting:
            break
        }
    }

    func openWeightScanSheet() {
        selectedVital = .weight
        if connectionState(for: .weight) == .disconnected {
            registry[.weight]?.connect()
        }
        showWeightPopover = true
    }

    func openConnectSheet(for type: VitalType) {
        selectedVital    = type
        showConnectSheet = true
    }

    func connect() {
        guard let type = selectedVital else { return }
        registry[type]?.connect()
    }

    func connectDemo() {
        guard let type = selectedVital else { return }
        registry[type]?.connectDemo()
    }

    func disconnect() {
        guard let type = selectedVital else { return }
        registry[type]?.disconnect()
        withAnimation { connectionStates[type] = .disconnected }
    }

    // MARK: - Navigation

    func startEKG() {
        guard connectionState(for: .ekg) == .connected else {
            startConnect(for: .ekg)
            return
        }
        diContainer.lastRecordingPatient = patient
        router.recordingReturnRoute = .vitals
        router.navigate(to: .ecgRecording(patientId: patient.id.map(String.init) ?? ""))
    }

    var examCount: Int {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        guard !pid.isEmpty else { return 0 }
        let ekgCount  = diContainer.recordingStore.recordings(for: pid).count
        let bpCount   = diContainer.bpStore.readings(for: pid).count
        let spo2Count = diContainer.spo2Store.readings(for: pid).count
        let tempCount = diContainer.tempStore.readings(for: pid).count
        let rrCount     = diContainer.rrStore.readings(for: pid).count
        let painCount   = diContainer.painStore.readings(for: pid).count
        let weightCount = diContainer.weightStore.readings(for: pid).count
        let heightCount = diContainer.heightStore.readings(for: pid).count
        return ekgCount + bpCount + spo2Count + tempCount + rrCount + painCount + weightCount + heightCount
    }

    func openExams() {
        router.navigate(to: .patientExams)
    }

    func deactivate() {
        // Cancel any pending scan timeouts — services stay connected across navigation.
        scanTimeoutTasks.values.forEach { $0.cancel() }
        scanTimeoutTasks.removeAll()
    }

    func navigateBack() {
        deactivate()
        let dest = router.vitalsReturnRoute
        router.vitalsReturnRoute = .patientSelection
        router.navigate(to: dest)
    }
}
