//
//  HomeViewModel.swift
//  EKGx
//
//  Drives all state for HomeView.
//

import Foundation
import SwiftUI

// MARK: - Device Connection State

enum DeviceConnectionState {
    case disconnected
    case searching
    case connected

    var label: String {
        switch self {
        case .disconnected: return L10n.Home.Device.disconnected
        case .searching:    return L10n.Home.Device.searching
        case .connected:    return L10n.Home.Device.connected
        }
    }

    var color: Color {
        switch self {
        case .disconnected: return AppColors.textSecondary
        case .searching:    return AppColors.statusWarning
        case .connected:    return AppColors.statusSuccess
        }
    }

    var systemImage: String {
        switch self {
        case .disconnected: return "wifi.slash"
        case .searching:    return "antenna.radiowaves.left.and.right"
        case .connected:    return "checkmark.circle.fill"
        }
    }
}

// MARK: - HomeViewModel

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - UI State

    var isMenuVisible: Bool = false
    var showLogoutConfirmation: Bool = false
    var deviceState: DeviceConnectionState = .disconnected

    // MARK: - Dependencies

    private let router: AppRouter
    private let diContainer: AppDIContainer
    private var deviceService: DeviceServiceProtocol

    init(router: AppRouter, diContainer: AppDIContainer) {
        self.router = router
        self.diContainer = diContainer
        self.deviceService = diContainer.deviceService
        deviceState = diContainer.deviceService.currentState
    }

    // MARK: - Current User (from login response)

    private var sessionUser: SessionUser? { diContainer.authService.loginData?.user }

    var currentUserFullName: String {
        guard let u = sessionUser else { return "" }
        let first = u.username
        return first
    }

    var currentUserEmail: String {
        sessionUser?.email ?? ""
    }

    /// Call from HomeView .onAppear — re-registers the callback every time we return to home.
    func activate() {
        deviceService = diContainer.deviceService
        deviceState = deviceService.currentState
        deviceService.onConnectionStateChanged = { [weak self] state in
            withAnimation { self?.deviceState = state }
        }
    }

    // MARK: - Menu

    func openMenu() {
        withAnimation(.easeInOut(duration: 0.28)) { isMenuVisible = true }
    }

    func closeMenu() {
        withAnimation(.easeInOut(duration: 0.24)) { isMenuVisible = false }
    }

    // MARK: - Device

    func connectDevice() {
        guard deviceState == .disconnected else { return }
        diContainer.switchToRealDevice()
        deviceService = diContainer.deviceService
        deviceService.onConnectionStateChanged = { [weak self] state in
            withAnimation { self?.deviceState = state }
        }
        deviceService.connect()
    }

    func connectDemo() {
        guard deviceState == .disconnected else { return }
        diContainer.switchToDemo()
        deviceService = diContainer.deviceService
        deviceService.onConnectionStateChanged = { [weak self] state in
            withAnimation { self?.deviceState = state }
        }
        deviceService.connect()
    }

    func disconnectDevice() {
        deviceService.disconnect()
        withAnimation { deviceState = .disconnected }
    }

    // MARK: - Feature Navigation

    func navigateToRecording() {
        closeMenu()
        router.navigate(to: .patientSelection)
    }

    func navigateToPatients() {
        closeMenu()
        router.navigate(to: .patientList)
    }

    func navigateToCloud() {
        closeMenu()
        router.navigate(to: .cloudReports)
    }

    // MARK: - Side Menu Navigation

    func navigateToSettings()          { closeMenu(); router.navigate(to: .settings) }
    func navigateToMyAccount()         { closeMenu(); router.navigate(to: .myAccount) }
    func navigateToSupport()           { closeMenu(); router.navigate(to: .support) }
    func navigateToFAQ()               { closeMenu(); router.navigate(to: .faq) }
    func navigateToIndicationsForUse() { closeMenu(); router.navigate(to: .indicationsForUse) }

    func confirmLogout() { showLogoutConfirmation = true }

    func logout() {
        showLogoutConfirmation = false
        closeMenu()
        router.navigate(to: .login)
    }

    // MARK: - Computed Helpers

    var isDeviceConnected: Bool { deviceState == .connected }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return L10n.Home.Greeting.morning
        case 12..<17: return L10n.Home.Greeting.afternoon
        default:      return L10n.Home.Greeting.evening
        }
    }

    var userRoleDisplayName: String {
        sessionUser?.title?.capitalized ?? sessionUser?.role?.capitalized ?? ""
    }

    var userInitials: String {
        guard let name = sessionUser?.username, !name.isEmpty else { return "?" }
        return String(name.prefix(2)).uppercased()
    }
}
