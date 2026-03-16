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

            case .ecgRecording,
                 .ecgAnalysis,
                 .patientDetail,
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
