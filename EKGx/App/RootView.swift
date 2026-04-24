//
//  RootView.swift
//  EKGx
//
//  Navigation root. Switches on AppRouter.currentRoute to display the
//  correct feature screen. All navigation logic lives in AppRouter.
//

import SwiftUI

struct RootView: View {

    @Environment(AppRouter.self) private var router
    @Environment(AppDIContainer.self) private var diContainer

    var body: some View {
        ZStack {
            routedContent

            // Invisible window-level activity tracker (gesture recognizer
            // attached to UIWindow). Never intercepts touches.
            ActivityTrackingView {
                diContainer.autoLockManager.reportActivity()
            }
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)

            // Lock popup — shown on top of the content and blocks all underlying touches.
            // Not shown on the login/register screens or in local/offline mode.
            if diContainer.autoLockManager.isLocked
                && router.currentRoute != .login
                && router.currentRoute != .register
                && !diContainer.isLocalMode {
                LockOverlayView(diContainer: diContainer, router: router)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: diContainer.autoLockManager.isLocked)
    }

    @ViewBuilder
    private var routedContent: some View {
        ZStack {
            switch router.currentRoute {

            case .login:
                LoginView(viewModel: diContainer.makeLoginViewModel(router: router))
                    .id(AppRoute.login)
                    .transition(.opacity)

            case .register:
                RegisterView(viewModel: diContainer.makeRegisterViewModel(router: router))
                    .id(AppRoute.register)
                    .transition(.push(from: .trailing))

            case .dashboard:
                HomeView(viewModel: diContainer.makeHomeViewModel(router: router))
                    .id(AppRoute.dashboard)
                    .transition(.opacity)

            case .patientList:
                PatientListView(viewModel: diContainer.makePatientListViewModel(router: router))
                    .id(AppRoute.patientList)
                    .transition(.push(from: .trailing))

            case .cloudReports:
                CloudView(viewModel: diContainer.makeCloudViewModel(router: router))
                    .id(AppRoute.cloudReports)
                    .transition(.push(from: .trailing))

            case .settings:
                SettingsView(viewModel: diContainer.makeSettingsViewModel(router: router))
                    .id(AppRoute.settings)
                    .transition(.push(from: .trailing))

            case .myAccount:
                MyAccountView(viewModel: diContainer.makeMyAccountViewModel(router: router))
                    .id(AppRoute.myAccount)
                    .transition(.push(from: .trailing))

            case .patientSelection:
                PatientSelectionView(viewModel: diContainer.makePatientSelectionViewModel(router: router))
                    .id(AppRoute.patientSelection)
                    .transition(.push(from: .trailing))

            case .ecgRecording:
                let patient = diContainer.lastRecordingPatient ?? Patient.mockPatients[0]
                RecordingView(viewModel: diContainer.makeRecordingViewModel(patient: patient, router: router))
                    .id(AppRoute.ecgRecording(patientId: ""))
                    .transition(.push(from: .trailing))

            case .ecgAnalysis:
                AnalysisView(viewModel: diContainer.makeAnalysisViewModel(router: router))
                    .id(AppRoute.ecgAnalysis(recordingId: ""))
                    .transition(.push(from: .trailing))

            case .faq:
                FAQView(viewModel: diContainer.makeAppContentViewModel(router: router))
                    .id(AppRoute.faq)
                    .transition(.push(from: .trailing))

            case .support:
                SupportView(viewModel: diContainer.makeAppContentViewModel(router: router))
                    .id(AppRoute.support)
                    .transition(.push(from: .trailing))

            case .indicationsForUse:
                IndicationsForUseView(viewModel: diContainer.makeAppContentViewModel(router: router))
                    .id(AppRoute.indicationsForUse)
                    .transition(.push(from: .trailing))

            case .patientDetail:
                PlaceholderView()
                    .id(AppRoute.patientDetail(patientId: ""))
                    .transition(.push(from: .trailing))
            }
        }
        .animation(.snappy(duration: 0.35), value: router.currentRoute)
    }
}

// MARK: - Placeholder (for routes not yet implemented)

private struct PlaceholderView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing24) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(AppColors.brandPrimary.opacity(0.4))

                VStack(spacing: AppMetrics.spacing8) {
                    Text(L10n.Placeholder.comingSoon)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.Placeholder.comingSoonSubtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Button(L10n.Common.back) {
                    router.navigate(to: .dashboard)
                }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, AppMetrics.spacing32)
                .padding(.vertical, AppMetrics.spacing14)
                .background(AppColors.brandPrimary)
                .cornerRadius(AppMetrics.radiusMedium)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environment(AppRouter())
        .environment(AppDIContainer())
}
