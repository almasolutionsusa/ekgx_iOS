//
//  AppDIContainer.swift
//  EKGx
//
//  Dependency injection container. Owns all service instances and exposes
//  factory methods for constructing ViewModels with the correct dependencies.
//  ViewModels are never created directly by Views.
//

import Foundation

@Observable
@MainActor
final class AppDIContainer {

    // MARK: - Services

    // TODO: Switch back to AuthService() when the API is ready
    private let _authService: MockAuthService = MockAuthService()
    var authService: AuthServiceProtocol { _authService }

    private(set) var deviceService: DeviceServiceProtocol = BLEDeviceService()

    func switchToDemo() {
        deviceService = DemoDeviceService()
    }

    func switchToRealDevice() {
        deviceService = BLEDeviceService()
    }

    // MARK: - ViewModel Factories

    func makeLoginViewModel(router: AppRouter) -> LoginViewModel {
        LoginViewModel(authService: authService, router: router)
    }

    func makeRegisterViewModel(router: AppRouter) -> RegisterViewModel {
        RegisterViewModel(authService: authService, router: router)
    }

    func makeHomeViewModel(router: AppRouter) -> HomeViewModel {
        HomeViewModel(router: router, diContainer: self)
    }

    func makePatientListViewModel(router: AppRouter) -> PatientListViewModel {
        PatientListViewModel(router: router)
    }

    func makeCloudViewModel(router: AppRouter) -> CloudViewModel {
        CloudViewModel(router: router)
    }

    func makeSettingsViewModel(router: AppRouter) -> SettingsViewModel {
        SettingsViewModel(router: router)
    }

    func makeMyAccountViewModel(router: AppRouter) -> MyAccountViewModel {
        MyAccountViewModel(router: router)
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
