//
//  MenuViewModel.swift
//  EKGx
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class MenuViewModel {

    var showLogoutAlert: Bool = false

    let settings: SettingsViewModel

    private let router:      AppRouter
    private let authService: AuthServiceProtocol
    let appInfoService:      AppInfoService
    private let diContainer: AppDIContainer

    init(
        router:         AppRouter,
        authService:    AuthServiceProtocol,
        appInfoService: AppInfoService,
        diContainer:    AppDIContainer,
        settings:       SettingsViewModel
    ) {
        self.router         = router
        self.authService    = authService
        self.appInfoService = appInfoService
        self.diContainer    = diContainer
        self.settings       = settings
    }

    // MARK: - User Info

    var fullName: String {
        let store = LocalUserStore.shared
        let first = authService.loginData?.user.firstName ?? store.firstName ?? ""
        let last  = authService.loginData?.user.lastName  ?? store.lastName  ?? ""
        let joined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return joined.isEmpty ? (authService.currentUser?.username ?? store.username ?? "") : joined
    }

    var email: String {
        authService.loginData?.user.email ?? LocalUserStore.shared.email ?? ""
    }

    var role: String {
        authService.loginData?.user.title?.capitalized
            ?? authService.loginData?.user.role?.capitalized
            ?? ""
    }

    var facilityName: String {
        appInfoService.cached?.facilityName ?? authService.loginData?.facilityName ?? ""
    }

    var initials: String {
        let words = fullName.split(separator: " ")
        if words.count >= 2,
           let f = words[0].first,
           let l = words[1].first { return "\(f)\(l)".uppercased() }
        return String(fullName.prefix(2)).uppercased()
    }

    // MARK: - Navigation

    func close() {
        settings.saveChanges()
        router.navigate(to: router.menuReturnRoute)
    }
    func goToMyAccount(){ router.navigate(to: .myAccount) }
    func goToFAQ()      { router.navigate(to: .faq) }
    func goToIFU()      { router.navigate(to: .indicationsForUse) }
    func goToSupport()  { router.navigate(to: .support) }

    func confirmLogout() { showLogoutAlert = true }

    func logout() {
        diContainer.autoLockManager.stop()
        Task { try? await diContainer.authService.logout() }
        router.navigate(to: .login)
    }
}
