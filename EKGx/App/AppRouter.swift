//
//  AppRouter.swift
//  EKGx
//
//  Central navigation coordinator. Views call the router to navigate;
//  the router owns all navigation state. Never push routes from ViewModels
//  directly — always go through this object.
//

import SwiftUI

// MARK: - Route Definitions

enum AppRoute: Hashable, Equatable {
    case login
    case register
    case dashboard
    case patientList
    case cloudReports
    case ecgRecording(patientId: String)
    case ecgAnalysis(recordingId: String)
    case patientDetail(patientId: String)
    case settings
    case myAccount
    case support
    case faq
    case indicationsForUse
}

// MARK: - AppRouter

@Observable
@MainActor
final class AppRouter {

    var currentRoute: AppRoute = .login
    var navigationPath: NavigationPath = NavigationPath()

    // MARK: - Navigation

    func navigate(to route: AppRoute) {
        currentRoute = route
    }

    func push(_ route: AppRoute) {
        navigationPath.append(route)
    }

    func popBack() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }
}
