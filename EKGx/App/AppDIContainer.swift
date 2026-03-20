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

    // TODO: Swap DemoDeviceService → BLEDeviceService when physical device is ready
    private let deviceService: DeviceServiceProtocol = DemoDeviceService()

    // MARK: - ViewModel Factories

    func makeLoginViewModel(router: AppRouter) -> LoginViewModel {
        LoginViewModel(authService: authService, router: router)
    }

    func makeRegisterViewModel(router: AppRouter) -> RegisterViewModel {
        RegisterViewModel(authService: authService, router: router)
    }

    func makeHomeViewModel(router: AppRouter) -> HomeViewModel {
        HomeViewModel(router: router, deviceService: deviceService)
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
        RecordingViewModel(patient: patient, deviceService: deviceService, router: router)
    }
}
