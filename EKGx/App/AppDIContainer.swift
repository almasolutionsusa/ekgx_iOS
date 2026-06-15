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

    /// Set when the user enters via EKG Emergency — gates the upload flow in AnalysisView.
    /// Consumed (reset to false) once makeAnalysisViewModel reads it.
    var isEmergencySession: Bool = false
    /// Return route captured when the emergency session starts, stored so RecordingViewModel
    /// overwriting router.analysisReturnRoute doesn't lose our destination.
    private var emergencyReturnRoute: AppRoute = AppRoute.login

    // MARK: - Services

    private(set) var authService: AuthServiceProtocol
    let checkinService: AppCheckinService
    let appInfoService: AppInfoService
    let patientsService: PatientsService
    let ordersService: OrdersService
    let appContentService: AppContentService
    let ekgUploadService: EKGUploadService
    let vitalsUploadService: VitalsUploadService
    let autoLockManager: AutoLockManager
    let recordingStore: LocalRecordingStore
    let localPatientStore: LocalPatientStore
    let patientRepository: PatientRepositoryProtocol
    let errorToast: ErrorToastManager

    // MARK: - Device Service

    private(set) var deviceService: DeviceServiceProtocol = BLEDeviceService()

    /// True when the app is running with the simulated demo ECG device.
    var isDemoMode: Bool { deviceService is DemoDeviceService }

    // MARK: - Vital Device Services (app-scoped so devices stay connected across navigation)

    let bpVitalService     = BPVitalDeviceService()
    let spo2VitalService   = OximeterVitalDeviceService()
    let tempVitalService   = TemperatureVitalDeviceService()
    let weightVitalService = WeightVitalDeviceService()
    let bpStore            = LocalBPStore()
    let spo2Store          = LocalSpO2Store()
    let tempStore          = LocalTempStore()
    let rrStore            = LocalRRStore()
    let painStore          = LocalPainStore()
    let weightStore        = LocalWeightStore()
    let heightStore        = LocalHeightStore()

    // MARK: - Init

    init(localMode: Bool = false) {
        self.isLocalMode      = localMode
        let auth              = AuthService()
        self.authService      = auth
        let checkin           = AppCheckinService()
        self.checkinService   = checkin
        self.appInfoService   = AppInfoService(checkinService: checkin)
        self.patientsService  = PatientsService()
        self.ordersService      = OrdersService(checkinService: checkin)
        self.appContentService  = AppContentService(checkinService: checkin)
        self.ekgUploadService      = EKGUploadService()
        self.vitalsUploadService   = VitalsUploadService(authService: auth)
        self.autoLockManager  = AutoLockManager()
        self.recordingStore      = LocalRecordingStore()
        self.localPatientStore   = LocalPatientStore()
        self.patientRepository   = CoreDataPatientRepository()
        self.errorToast          = ErrorToastManager()
        // Restore demo device if it was enabled in a previous session
        if UserDefaults.standard.bool(forKey: "app.demoData") {
            deviceService = DemoDeviceService()
        }

        self.autoLockManager.onWillLock = { [weak self] in
            self?.deviceService.disconnect()
        }
    }

    // MARK: - Session Expiry

    /// Wire this up from EKGxApp with the router so any 302 silently falls back to local mode.
    func configureSessionExpiry(router: AppRouter) {
        APIClient.shared.onSessionExpired = { [weak self] in
            guard let self, !self.isLocalMode, self.authService.isAuthenticated else { return }
            Task { @MainActor in
                try? await self.authService.logout()
                self.isLocalMode = true
                // Stay on the current screen — data continues to save locally
            }
        }
    }

    // MARK: - Mode Switching

    func enableOnlineMode() {
        isLocalMode = false
        isEmergencySession = false
    }

    // MARK: - Emergency Session

    /// Creates or reuses the anonymous patient (MRN 000000) and navigates directly to RecordingView.
    /// No login required. The AnalysisView will gate upload with a PIN check.
    func startEmergencySession(router: AppRouter) {
        isEmergencySession = true
        let returnRoute = authService.isAuthenticated ? AppRoute.patientSelection : AppRoute.login
        emergencyReturnRoute = returnRoute
        clearRecordingSession()
        Task {
            let anon = await getOrCreateAnonymousPatient()
            lastRecordingPatient = anon.toPatient()
            recordingSessionStartedAt = Date()
            router.recordingReturnRoute = returnRoute
            router.navigate(to: .ecgRecording(patientId: ""))
        }
    }

    private func getOrCreateAnonymousPatient() async -> LocalPatient {
        let all = (try? await patientRepository.fetchAll()) ?? []
        if let existing = all.first(where: { $0.mrn == "000000" }) {
            return existing
        }
        var comps = DateComponents(); comps.year = -35
        let dob = Calendar.current.date(byAdding: comps, to: Date()) ?? Date()
        let dobStr = LocalPatient.dateFormatter.string(from: dob)
        let input = NewPatientInput(
            firstName: "Anonymous",
            lastName: "Anonymous",
            birthDate: dobStr,
            gender: "Male",
            mrn: "000000",
            createdBy: "system"
        )
        return (try? await patientRepository.add(input)) ?? LocalPatient(
            firstName: "Anonymous", lastName: "Anonymous",
            birthDate: dobStr, gender: "Male", mrn: "000000"
        )
    }

    /// Switches to local mode and navigates directly to patient selection — no login needed.
    func enableLocalMode(router: AppRouter) {
        isLocalMode = true
        router.navigate(to: .patientSelection)
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
        RegisterViewModel(authService: authService, router: router)
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
        PatientSelectionViewModel(repository: patientRepository, router: router, diContainer: self)
    }

    private var _cloudViewModel: CloudViewModel?
    func makeCloudViewModel(router: AppRouter) -> CloudViewModel {
        if let existing = _cloudViewModel { return existing }
        let vm = CloudViewModel(router: router, recordingStore: recordingStore, diContainer: self)
        _cloudViewModel = vm
        return vm
    }

    private var _settingsViewModel: SettingsViewModel?
    func makeSettingsViewModel(router: AppRouter) -> SettingsViewModel {
        if let existing = _settingsViewModel { return existing }
        let vm = SettingsViewModel(router: router, authService: authService, diContainer: self)
        _settingsViewModel = vm
        return vm
    }

    func makeMyAccountViewModel(router: AppRouter) -> MyAccountViewModel {
        MyAccountViewModel(router: router, authService: authService, appInfoService: appInfoService)
    }

    func makeAppContentViewModel(router: AppRouter) -> AppContentViewModel {
        AppContentViewModel(contentService: appContentService, router: router)
    }

    func makeVitalsViewModel(router: AppRouter) -> VitalsViewModel {
        VitalsViewModel(patient: lastRecordingPatient ?? Patient.mockPatients[0], router: router, diContainer: self, appInfoService: appInfoService)
    }

    func makePatientExamsViewModel(router: AppRouter) -> PatientExamsViewModel {
        PatientExamsViewModel(
            patient: lastRecordingPatient ?? Patient.mockPatients[0],
            recordingStore: recordingStore,
            router: router,
            diContainer: self
        )
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

    func makeMenuViewModel(router: AppRouter) -> MenuViewModel {
        MenuViewModel(
            router: router,
            authService: authService,
            appInfoService: appInfoService,
            diContainer: self,
            settings: makeSettingsViewModel(router: router)
        )
    }

    func makeWaitingListViewModel(router: AppRouter) -> WaitingListViewModel {
        WaitingListViewModel(repository: patientRepository, router: router, diContainer: self)
    }

    func makeAnalysisViewModel(router: AppRouter) -> AnalysisViewModel {
        // Consume the emergency flag: once the AnalysisViewModel is created, reset it so
        // subsequent normal recordings don't inherit the emergency gate.
        let em = isEmergencySession
        let emReturn = emergencyReturnRoute
        isEmergencySession = false
        // Also check the stored recording's isEmergency flag so the banner shows
        // when reopening a historical emergency exam (live session flag is already reset).
        let storedIsEmergency = lastRecordingExistingId.map { recordingStore.isEmergency(for: $0) } ?? false
        return AnalysisViewModel(
            patient: lastRecordingPatient ?? Patient.mockPatients[0],
            ecgData: lastRecordingData,
            sampleRate: lastRecordingSampleRate,
            totalDuration: lastRecordingTotalDuration,
            existingRecordingId: lastRecordingExistingId,
            isLocalMode: isLocalMode,
            isEmergencySession: em,
            emergencyReturnRoute: emReturn,
            recordingIsEmergency: storedIsEmergency,
            patientRepository: patientRepository,
            router: router,
            uploadService: ekgUploadService,
            checkinService: checkinService,
            recordingStore: recordingStore,
            authService: authService
        )
    }
}
