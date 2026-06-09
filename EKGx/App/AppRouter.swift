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
    case patientSelection
    case vitals
    case ecgRecording(patientId: String)
    case ecgAnalysis(recordingId: String)
    case patientDetail(patientId: String)
    case settings
    case myAccount
    case support
    case faq
    case indicationsForUse
    case patientExams
    case waitingList
    case menu
}

// MARK: - AppRouter

@Observable
@MainActor
final class AppRouter {

    var currentRoute: AppRoute = .login
    var navigationPath: NavigationPath = NavigationPath()
    /// Route to return to when the user presses Back from Analysis. Defaults to .vitals.
    var analysisReturnRoute: AppRoute = .vitals
    /// Route to return to when the user exits the Recording screen. Defaults to .vitals.
    var recordingReturnRoute: AppRoute = .vitals
    /// Route to return to when the user presses Back from Vitals. Defaults to .patientSelection.
    var vitalsReturnRoute: AppRoute = .patientSelection
    /// Route to return to when the user presses Back from PatientExams. Defaults to .vitals.
    var patientExamsReturnRoute: AppRoute = .vitals
    /// The screen that opened the full-screen menu — used by MenuView's close/back action.
    var menuReturnRoute: AppRoute = .patientSelection

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
