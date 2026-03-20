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

    // MARK: - Current User

    let currentUser: User = User(
        id: "mock-001",
        firstName: "Sarah",
        lastName: "Mitchell",
        email: "s.mitchell@hospital.com",
        role: .physician
    )

    // MARK: - Dependencies

    private let router: AppRouter
    private let deviceService: DeviceServiceProtocol

    init(router: AppRouter, deviceService: DeviceServiceProtocol) {
        self.router = router
        self.deviceService = deviceService
        // Sync initial state from the service (device may already be connected)
        deviceState = deviceService.currentState
    }

    /// Call from HomeView .onAppear — re-registers the callback every time we return to home.
    func activate() {
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
        deviceService.connect()
    }

    func disconnectDevice() {
        deviceService.disconnect()
    }

    // MARK: - Feature Navigation

    func navigateToRecording() {
        closeMenu()
        router.navigate(to: .ecgRecording(patientId: ""))
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
        currentUser.role.label
    }

    var userInitials: String {
        let f = currentUser.firstName.first.map(String.init) ?? ""
        let l = currentUser.lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }
}
