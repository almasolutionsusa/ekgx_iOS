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
    let ordersService: OrdersService
    let appContentService: AppContentService
    let ekgUploadService: EKGUploadService
    let autoLockManager: AutoLockManager
    let recordingStore: LocalRecordingStore
    let localPatientStore: LocalPatientStore
    let errorToast: ErrorToastManager

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
        self.ordersService      = OrdersService(checkinService: checkin)
        self.appContentService  = AppContentService(checkinService: checkin)
        self.ekgUploadService   = EKGUploadService()
        self.autoLockManager  = AutoLockManager()
        self.recordingStore      = LocalRecordingStore()
        self.localPatientStore   = LocalPatientStore()
        self.errorToast          = ErrorToastManager()
        self.autoLockManager.onWillLock = { [weak self] in
            self?.deviceService.disconnect()
        }
    }

    // MARK: - Session Expiry

    /// Wire this up from EKGxApp with the router so any 302 forces logout + login redirect.
    func configureSessionExpiry(router: AppRouter) {
        APIClient.shared.onSessionExpired = { [weak self] in
            guard let self, !self.isLocalMode else { return }
            Task { @MainActor in
                try? await self.authService.logout()
                self.autoLockManager.stop()
                self.clearRecordingSession()
                router.navigate(to: .login)
            }
        }
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
        deviceService.disconnect()
        deviceService = DemoDeviceService()
    }

    func switchToRealDevice() {
        guard !(deviceService is BLEDeviceService) else { return }
        deviceService.disconnect()
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

    private var _patientListViewModel: PatientListViewModel?
    func makePatientListViewModel(router: AppRouter) -> PatientListViewModel {
        if let existing = _patientListViewModel { return existing }
        let vm = PatientListViewModel(
            ordersService: ordersService,
            patientsService: patientsService,
            appInfoService: appInfoService,
            router: router,
            diContainer: self
        )
        _patientListViewModel = vm
        return vm
    }

    func makePatientSelectionViewModel(router: AppRouter) -> PatientSelectionViewModel {
        PatientSelectionViewModel(
            patientsService: patientsService,
            appInfoService: appInfoService,
            diContainer: self,
            router: router
        )
    }

    func makeOfflinePatientSelectionViewModel(router: AppRouter) -> OfflinePatientSelectionViewModel {
        OfflinePatientSelectionViewModel(patientStore: localPatientStore, diContainer: self, router: router)
    }

    private var _cloudViewModel: CloudViewModel?
    func makeCloudViewModel(router: AppRouter) -> CloudViewModel {
        if let existing = _cloudViewModel { return existing }
        let vm = CloudViewModel(router: router, recordingStore: recordingStore, diContainer: self)
        _cloudViewModel = vm
        return vm
    }

    func makeSettingsViewModel(router: AppRouter) -> SettingsViewModel {
        SettingsViewModel(router: router, authService: authService)
    }

    func makeMyAccountViewModel(router: AppRouter) -> MyAccountViewModel {
        MyAccountViewModel(router: router, authService: authService, appInfoService: appInfoService)
    }

    func makeAppContentViewModel(router: AppRouter) -> AppContentViewModel {
        AppContentViewModel(contentService: appContentService, router: router)
    }

    func makeRecordingViewModel(patient: Patient, router: AppRouter) -> RecordingViewModel {
        RecordingViewModel(patient: patient, deviceService: deviceService, router: router, diContainer: self)
    }

    // MARK: - Last Recording (set by RecordingViewModel before navigating to analysis)

    var lastRecordingPatient: Patient?
    var lastRecordingData: ECGLeads = []
    var lastRecordingSampleRate: Int = 660
    /// Stamped when the user confirms a patient — used to compute totalDuration on upload.
    var recordingSessionStartedAt: Date? = nil
    /// Seconds from patient confirmation to analysis view. Nil if timer wasn't started.
    var lastRecordingTotalDuration: Int? = nil
    /// Set when reopening an existing recording from Cloud — prevents duplicate local save.
    var lastRecordingExistingId: String? = nil

    func clearRecordingSession() {
        lastRecordingPatient = nil
        lastRecordingData = []
        lastRecordingSampleRate = 660
        recordingSessionStartedAt = nil
        lastRecordingTotalDuration = nil
        lastRecordingExistingId = nil
    }

    func makeAnalysisViewModel(router: AppRouter) -> AnalysisViewModel {
        AnalysisViewModel(
            patient: lastRecordingPatient ?? Patient.mockPatients[0],
            ecgData: lastRecordingData,
            sampleRate: lastRecordingSampleRate,
            totalDuration: lastRecordingTotalDuration,
            existingRecordingId: lastRecordingExistingId,
            isLocalMode: isLocalMode,
            router: router,
            uploadService: ekgUploadService,
            checkinService: checkinService,
            recordingStore: recordingStore,
            authService: authService
        )
    }
}
