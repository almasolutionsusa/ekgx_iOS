import Foundation
import SwiftUI

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

    // MARK: - Sheet State

    var selectedVital: VitalType? = nil
    var showConnectSheet: Bool = false

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
    }

    // Register all known device services here.
    // To add Echo: create EchoVitalDeviceService and register it for .echo.
    private func setUp() {
        let ekgService = EKGVitalDeviceService(diContainer: diContainer)
        register(ekgService, for: .ekg)
    }

    private func register(_ service: some VitalDeviceServiceProtocol, for type: VitalType) {
        let box = VitalDeviceServiceBox(service, for: type)
        box.observe { [weak self] state in
            withAnimation { self?.connectionStates[type] = state }
            if state == .connected { self?.showConnectSheet = false }
        }
        connectionStates[type] = service.connectionState
        registry[type] = box
    }

    // MARK: - Computed

    var facilityName: String { appInfoService.cached?.facilityName ?? "EKGx" }
    var patientName: String  { patient.fullName }

    func connectionState(for type: VitalType) -> DeviceConnectionState {
        connectionStates[type] ?? .disconnected
    }

    func connectedDeviceName(for type: VitalType) -> String? {
        registry[type]?.connectedDeviceName
    }

    // MARK: - Connect Sheet

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
            openConnectSheet(for: .ekg)
            return
        }
        diContainer.lastRecordingPatient = patient
        router.recordingReturnRoute = .vitals
        router.navigate(to: .ecgRecording(patientId: patient.id.map(String.init) ?? ""))
    }

    var examCount: Int {
        let pid = patient.patientId ?? patient.uniqueId ?? ""
        guard !pid.isEmpty else { return 0 }
        return diContainer.recordingStore.recordings(for: pid).count
    }

    func openExams() {
        router.navigate(to: .patientExams)
    }

    func navigateBack() {
        router.navigate(to: .patientSelection)
    }
}
