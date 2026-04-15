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
        Group {
            switch router.currentRoute {

            case .login:
                LoginView(viewModel: diContainer.makeLoginViewModel(router: router))
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))

            case .register:
                RegisterView(viewModel: diContainer.makeRegisterViewModel(router: router))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            case .dashboard:
                HomeView(viewModel: diContainer.makeHomeViewModel(router: router))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))

            case .patientList:
                PatientListView(viewModel: diContainer.makePatientListViewModel(router: router))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))

            case .cloudReports:
                CloudView(viewModel: diContainer.makeCloudViewModel(router: router))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))

            case .settings:
                SettingsView(viewModel: diContainer.makeSettingsViewModel(router: router))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))

            case .myAccount:
                MyAccountView(viewModel: diContainer.makeMyAccountViewModel(router: router))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))

            case .patientSelection:
                PatientSelectionView(viewModel: diContainer.makePatientSelectionViewModel(router: router))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))

            case .ecgRecording(let patientId):
                let patient = Patient.mockPatients.first { $0.uniqueId == patientId } ?? Patient.mockPatients[0]
                RecordingView(viewModel: diContainer.makeRecordingViewModel(patient: patient, router: router))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))

            case .ecgAnalysis:
                AnalysisView(viewModel: diContainer.makeAnalysisViewModel(router: router))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))

            case .patientDetail,
                 .support,
                 .faq,
                 .indicationsForUse:
                PlaceholderView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: router.currentRoute)
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
