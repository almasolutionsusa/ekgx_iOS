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

            // Side menu — always on top
            SideMenuView(
                user: viewModel.currentUser,
                userInitials: viewModel.userInitials,
                userRoleDisplayName: viewModel.userRoleDisplayName,
                isVisible: viewModel.isMenuVisible,
                onDismiss:           { viewModel.closeMenu() },
                onSettings:          { viewModel.navigateToSettings() },
                onMyAccount:         { viewModel.navigateToMyAccount() },
                onSupport:           { viewModel.navigateToSupport() },
                onFAQ:               { viewModel.navigateToFAQ() },
                onIndicationsForUse: { viewModel.navigateToIndicationsForUse() },
                onLogout:            { viewModel.confirmLogout() }
            )
        }
        .confirmationDialog(
            L10n.Menu.logoutConfirm,
            isPresented: $viewModel.showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Menu.logoutConfirmButton, role: .destructive) { viewModel.logout() }
            Button(L10n.Common.cancel, role: .cancel) {}
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
                Text("\(viewModel.greeting), \(viewModel.currentUser.firstName)")
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
                DeviceConnectButton(
                    state: viewModel.deviceState,
                    onTap: {
                        if viewModel.deviceState == .connected {
                            viewModel.disconnectDevice()
                        } else {
                            viewModel.connectDevice()
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
        HStack(spacing: AppMetrics.spacing10) {
            VStack(alignment: .trailing, spacing: AppMetrics.spacing2) {
                Text(viewModel.currentUser.fullName)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.userRoleDisplayName)
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.brandPrimary)
            }
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary)
                    .frame(width: 40, height: 40)
                Text(viewModel.userInitials)
                    .font(AppTypography.bodySemibold)
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let router = AppRouter()
    HomeView(viewModel: HomeViewModel(router: router))
        .environment(router)
}
