//
//  EKGxApp.swift
//  EKGx
//
//  Application entry point. Bootstraps the DI container and navigation
//  coordinator, then mounts the root view into the window.
//

import SwiftUI
import CoreData

@main
struct EKGxApp: App {

    // MARK: - App-level State

    @State private var router      = AppRouter()
    @State private var diContainer = AppDIContainer()
    @AppStorage("isDarkMode") private var isDarkMode = true

    let persistenceController = PersistenceController.shared

    init() {
        #if DEBUG
        for family in UIFont.familyNames.sorted() {
            for name in UIFont.fontNames(forFamilyName: family) {
                if name.contains("Montserrat") || name.contains("Roboto") {
//                    print("✅ Font loaded: \(name)")
                }
            }
        }
        #endif
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(diContainer)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                // Kiosk chrome reduction
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .task {
                    // Wire global session expiry handler — any 302 forces logout + login redirect.
                    diContainer.configureSessionExpiry(router: router)
                    // Wire global API error toast — every failed request auto-surfaces a message.
                    // Session-expired errors are handled by configureSessionExpiry instead.
                    APIClient.shared.onError = { [weak diContainer] message in
                        guard message != L10n.Auth.Login.errorSessionExpired else { return }
                        guard !(diContainer?.isLocalMode ?? false) else { return }
                        diContainer?.errorToast.show(message)
                    }
                    // Fire-and-forget: registers the app install with the server.
                    // Failure is silently ignored — app works fully offline.
                    await diContainer.checkinService.checkin()
                    // Prefetch facility + enum options for downstream screens
                    // (patient search, EKG upload, register form).
                    await diContainer.appInfoService.getInfo()
                }
        }
    }
}
