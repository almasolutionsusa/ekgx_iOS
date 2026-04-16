//
//  AppDIContainer.swift
//  EKGx
//
//  Dependency injection root.
//
//  LOCAL MODE (isLocalMode = true)
//  ─────────────────────────────────────────────────────────────────────────
//  No login required. Router starts at .dashboard directly.
//  Checkin and upload services still run but fail silently.
//
//  ONLINE MODE (isLocalMode = false)
//  ─────────────────────────────────────────────────────────────────────────
//  Real AuthService (session cookie). Checkin on launch.
//  ECG uploads sent to POST /api/ekg/results.
//

import Foundation

@Observable
@MainActor
final class AppDIContainer {

    // MARK: - Mode

    /// Toggle: true = no login required, mock auth, local-only.
    /// false = real API, session cookie auth required.
    private(set) var isLocalMode: Bool

    // MARK: - Services

    private(set) var authService: AuthServiceProtocol
    let checkinService: AppCheckinService
    let appInfoService: AppInfoService
    let patientsService: PatientsService
    let ekgUploadService: EKGUploadService
    let autoLockManager: AutoLockManager

    // MARK: - Device Service

    private(set) var deviceService: DeviceServiceProtocol = BLEDeviceService()

    // MARK: - Init

    init(localMode: Bool = false) {
        self.isLocalMode      = localMode
        self.authService      = AuthService()
        let checkin           = AppCheckinService()
        self.checkinService   = checkin
        self.appInfoService   = AppInfoService(checkinService: checkin)
        self.patientsService  = PatientsService()
        self.ekgUploadService = EKGUploadService()
        self.autoLockManager  = AutoLockManager()
    }

    // MARK: - Mode Switching

    func enableOnlineMode() {
        isLocalMode = false
    }

    /// Switches to local mode and navigates directly to dashboard — no login needed.
    func enableLocalMode(router: AppRouter) {
        isLocalMode = true
        router.navigate(to: .dashboard)
    }

    // MARK: - Device Switching

    func switchToDemo() {
        deviceService = DemoDeviceService()
    }

    func switchToRealDevice() {
        deviceService = BLEDeviceService()
    }

    // MARK: - ViewModel Factories

    func makeLoginViewModel(router: AppRouter) -> LoginViewModel {
        LoginViewModel(authService: authService, diContainer: self, router: router)
    }

    func makeRegisterViewModel(router: AppRouter) -> RegisterViewModel {
        RegisterViewModel(authService: authService, appInfoService: appInfoService, router: router)
    }

    func makeHomeViewModel(router: AppRouter) -> HomeViewModel {
        HomeViewModel(router: router, diContainer: self)
    }

    func makePatientListViewModel(router: AppRouter) -> PatientListViewModel {
        PatientListViewModel(router: router)
    }

    func makePatientSelectionViewModel(router: AppRouter) -> PatientSelectionViewModel {
        PatientSelectionViewModel(
            patientsService: patientsService,
            appInfoService: appInfoService,
            diContainer: self,
            router: router
        )
    }

    func makeCloudViewModel(router: AppRouter) -> CloudViewModel {
        CloudViewModel(router: router)
    }

    func makeSettingsViewModel(router: AppRouter) -> SettingsViewModel {
        SettingsViewModel(router: router, authService: authService)
    }

    func makeMyAccountViewModel(router: AppRouter) -> MyAccountViewModel {
        MyAccountViewModel(router: router, authService: authService)
    }

    func makeRecordingViewModel(patient: Patient, router: AppRouter) -> RecordingViewModel {
        RecordingViewModel(patient: patient, deviceService: deviceService, router: router, diContainer: self)
    }

    // MARK: - Last Recording (set by RecordingViewModel before navigating to analysis)

    var lastRecordingPatient: Patient?
    var lastRecordingData: ECGLeads = []
    var lastRecordingSampleRate: Int = 660

    func makeAnalysisViewModel(router: AppRouter) -> AnalysisViewModel {
        AnalysisViewModel(
            patient: lastRecordingPatient ?? Patient.mockPatients[0],
            ecgData: lastRecordingData,
            sampleRate: lastRecordingSampleRate,
            router: router
        )
    }
}
