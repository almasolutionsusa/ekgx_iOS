//
//  SideMenuView.swift
//  EKGx
//
//  Slide-out navigation drawer overlaying from the left edge.
//  Receives all callbacks from the parent — no router dependency,
//  keeping this component fully reusable.
//

import SwiftUI

// MARK: - Menu Item Model

struct SideMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let isDestructive: Bool
    let action: () -> Void
}

// MARK: - SideMenuView

struct SideMenuView: View {

    let userFullName: String
    let userEmail: String
    let userInitials: String
    let userRoleDisplayName: String
    let isVisible: Bool
    let onDismiss: () -> Void

    // Navigation callbacks
    let onSettings: () -> Void
    let onMyAccount: () -> Void
    let onSupport: () -> Void
    let onFAQ: () -> Void
    let onIndicationsForUse: () -> Void
    let onLogout: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            // Scrim
            if isVisible {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { onDismiss() }
                    .transition(.opacity)
            }

            // Panel
            if isVisible {
                menuPanel
                    .frame(width: AppMetrics.sideMenuWidth)
                    .frame(maxHeight: .infinity)
                    .ignoresSafeArea(edges: .vertical)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(.easeInOut(duration: 0.26), value: isVisible)
    }

    // MARK: - Panel

    private var menuPanel: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [AppColors.surfaceSidebar, Color(red: 0.04, green: 0.18, blue: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 0) {
                headerSection
                    .padding(.top, AppMetrics.spacing48)
                    .padding(.horizontal, AppMetrics.spacing24)

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.top, AppMetrics.spacing20)
                    .padding(.horizontal, AppMetrics.spacing24)

                mainMenuItems
                    .padding(.top, AppMetrics.spacing8)

                Spacer()

                logoutRow
                    .padding(.horizontal, AppMetrics.spacing12)
                    .padding(.bottom, AppMetrics.spacing40)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing20) {
            // App brand
            HStack(spacing: AppMetrics.spacing12) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .fill(AppColors.brandPrimary)
                        .frame(width: 44, height: 44)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: AppMetrics.spacing2) {
                    Text(L10n.Branding.appName)
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.textOnDark)
                    Text(L10n.Branding.tagline)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textOnDark.opacity(0.55))
                }
            }

            // User info card
            HStack(spacing: AppMetrics.spacing12) {
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.3))
                        .frame(width: 44, height: 44)
                    Text(userInitials)
                        .font(AppTypography.bodySemibold)
                        .foregroundStyle(AppColors.textOnDark)
                }
                VStack(alignment: .leading, spacing: AppMetrics.spacing2) {
                    Text(userFullName)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textOnDark)
                    Text(userRoleDisplayName)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textOnDark.opacity(0.6))
                }
            }
            .padding(AppMetrics.spacing12)
            .background(Color.white.opacity(0.06))
            .cornerRadius(AppMetrics.radiusMedium)
        }
    }

    // MARK: - Main Menu Items

    private var mainMenuItems: some View {
        let items: [SideMenuItem] = [
            SideMenuItem(title: L10n.Menu.settings,          systemImage: "gear",                               isDestructive: false, action: onSettings),
            SideMenuItem(title: L10n.Menu.myAccount,         systemImage: "person.circle",                      isDestructive: false, action: onMyAccount),
            SideMenuItem(title: L10n.Menu.support,           systemImage: "questionmark.circle",                isDestructive: false, action: onSupport),
            SideMenuItem(title: L10n.Menu.faq,               systemImage: "text.bubble",                        isDestructive: false, action: onFAQ),
            SideMenuItem(title: L10n.Menu.indicationsForUse, systemImage: "doc.text",                           isDestructive: false, action: onIndicationsForUse),
        ]

        return VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
            ForEach(items) { item in
                SideMenuRow(item: item)
            }
        }
        .padding(.horizontal, AppMetrics.spacing12)
    }

    // MARK: - Logout

    private var logoutRow: some View {
        SideMenuRow(item: SideMenuItem(
            title: L10n.Menu.logout,
            systemImage: "rectangle.portrait.and.arrow.right",
            isDestructive: true,
            action: onLogout
        ))
    }
}

// MARK: - SideMenuRow

private struct SideMenuRow: View {

    let item: SideMenuItem

    var body: some View {
        Button(action: item.action) {
            HStack(spacing: AppMetrics.spacing16) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(item.isDestructive ? AppColors.statusCritical : AppColors.textOnDark.opacity(0.85))
                    .frame(width: 28)

                Text(item.title)
                    .font(AppTypography.body)
                    .foregroundStyle(item.isDestructive ? AppColors.statusCritical : AppColors.textOnDark)

                Spacer()

                if !item.isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textOnDark.opacity(0.3))
                }
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .padding(.vertical, AppMetrics.spacing14)
            .background(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .fill(item.isDestructive
                          ? AppColors.statusCritical.opacity(0.1)
                          : Color.white.opacity(0.0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
