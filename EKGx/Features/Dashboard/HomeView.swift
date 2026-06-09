//
//  HomeView.swift
//  EKGx
//
//  Main dashboard — landscape iPad kiosk.
//
//  ┌──────────────────────────────────────────────────────────────────────────┐
//  │  [≡ Menu]   [~~~ECG animated logo~~~]   [Device Btn]  [SM · Physician]  │
//  ├──────────────────────────────────────────────────────────────────────────┤
//  │                                                                          │
//  │   Good Morning, Sarah                                                    │
//  │   What would you like to do today?                                       │
//  │                                                                          │
//  │   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │
//  │   │  ECG Recording  │  │    Patients      │  │  Cloud/Reports  │        │
//  │   └─────────────────┘  └─────────────────┘  └─────────────────┘        │
//  └──────────────────────────────────────────────────────────────────────────┘
//

import SwiftUI

// MARK: - HomeView

struct HomeView: View {

    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HomeNavigationBar(viewModel: viewModel)
                homeContent.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            viewModel.activate()
        }
    }

    // MARK: - Main Content

    private var homeContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo — centered at the top
            ECGLogoView()
                .frame(maxWidth: .infinity)
                .padding(.top, AppMetrics.spacing24)
                .padding(.bottom, AppMetrics.spacing8)

            // Greeting
            VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                Text("\(viewModel.greeting), \(viewModel.currentUserFullName)")
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Home.subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppMetrics.spacing40)
            .padding(.top, AppMetrics.spacing28)
            .padding(.bottom, AppMetrics.spacing20)

            // Feature cards
            HStack(spacing: AppMetrics.spacing16) {
                FeatureCard(
                    systemImage: "waveform.path.ecg",
                    title: L10n.Home.Card.Recording.title,
                    subtitle: L10n.Home.Card.Recording.subtitle,
                    accentColor: AppColors.brandPrimary,
                    isEnabled: viewModel.isDeviceConnected,
                    action: { viewModel.navigateToRecording() }
                )
                FeatureCard(
                    systemImage: "person.2.fill",
                    title: L10n.Home.Card.Patients.title,
                    subtitle: L10n.Home.Card.Patients.subtitle,
                    accentColor: AppColors.brandSecondary,
                    action: { viewModel.navigateToPatients() }
                )
                FeatureCard(
                    systemImage: "cloud.fill",
                    title: L10n.Home.Card.Cloud.title,
                    subtitle: L10n.Home.Card.Cloud.subtitle,
                    accentColor: AppColors.statusInfo,
                    action: { viewModel.navigateToCloud() }
                )
            }
            .padding(.horizontal, AppMetrics.spacing40)
            .padding(.bottom, AppMetrics.spacing32)
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - HomeNavigationBar

private struct HomeNavigationBar: View {

    let viewModel: HomeViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 0) {

            // ── LEFT: Menu button
            menuButton

            Spacer()

            Spacer()

            // ── RIGHT: Device button + user chip
            HStack(spacing: AppMetrics.spacing16) {
                if viewModel.deviceState == .disconnected {
                    Button("Demo") { viewModel.connectDemo() }
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.brandPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.brandPrimary.opacity(0.1))
                        .cornerRadius(AppMetrics.radiusMedium)
                        .buttonStyle(.hapticPlain)
                }
                DeviceConnectButton(
                    state: viewModel.deviceState,
                    onTap: {
                        if viewModel.deviceState == .disconnected {
                            viewModel.connectDevice()
                        } else {
                            viewModel.disconnectDevice()
                        }
                    }
                )
                userChip
            }
        }
        .padding(.horizontal, AppMetrics.spacing24)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Sub-components

    private var menuButton: some View {
        Button(action: { viewModel.openMenu() }) {
            HStack(spacing: AppMetrics.spacing8) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                Text(L10n.Home.Nav.menuButton)
                    .font(AppTypography.callout)
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppMetrics.spacing16)
            .padding(.vertical, AppMetrics.spacing8)
            .background(AppColors.borderSubtle.opacity(0.5))
            .cornerRadius(AppMetrics.radiusMedium)
        }
        .accessibilityLabel(L10n.Home.Nav.menuButton)
    }

    private var userChip: some View {
        Button(action: { viewModel.confirmLogout() }) {
            HStack(spacing: AppMetrics.spacing8) {
                Image(systemName: "power")
                    .font(.system(size: 15, weight: .semibold))
                Text(L10n.Menu.logout)
                    .font(AppTypography.callout)
            }
            .foregroundStyle(AppColors.statusCritical)
            .padding(.horizontal, AppMetrics.spacing16)
            .padding(.vertical, AppMetrics.spacing8)
            .background(AppColors.statusCritical.opacity(0.08))
            .cornerRadius(AppMetrics.radiusMedium)
        }
        .buttonStyle(.hapticPlain)
    }
}

// MARK: - Preview
//
//#Preview {
//    let router = AppRouter()
//    HomeView(viewModel: HomeViewModel(router: router, deviceService: DemoDeviceService()))
//        .environment(router)
//}
