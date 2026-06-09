//
//  MenuView.swift
//  EKGx
//
//  Full-screen split menu:
//  Left  — dark profile card (340 pt)
//  Right — scrollable list: My Account nav cell + all Settings inline + Help nav cells
//

import SwiftUI

// MARK: - MenuView

struct MenuView: View {

    @State private var viewModel: MenuViewModel

    init(viewModel: MenuViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        HStack(spacing: 0) {
            profilePanel
                .frame(width: 340)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1)
                .ignoresSafeArea()

            SettingsPanelView(
                settings:    viewModel.settings,
                onMyAccount: viewModel.goToMyAccount,
                onFAQ:       viewModel.goToFAQ,
                onIFU:       viewModel.goToIFU,
                onSupport:   viewModel.goToSupport
            )
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea()
        .alert(L10n.Menu.logoutConfirm, isPresented: $viewModel.showLogoutAlert) {
            Button(L10n.Menu.logoutConfirmButton, role: .destructive) { viewModel.logout() }
            Button(L10n.Common.cancel, role: .cancel) {}
        }
    }

    // MARK: - Left: Profile Panel

    private var profilePanel: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [AppColors.surfaceSidebar, AppColors.surfaceSidebar.opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ecgDecoration

            VStack(alignment: .leading, spacing: 0) {

                HStack(spacing: AppMetrics.spacing12) {
                    Button { viewModel.close() } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 38, height: 38)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.hapticPlain)
                    AppImages.logo
                        .resizable()
                        .scaledToFit()
                        .frame(height: 18)
                }
                .padding(.top, 52)

                Spacer()

                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.22))
                        .frame(width: 90, height: 90)
                    Circle()
                        .stroke(AppColors.brandPrimary.opacity(0.4), lineWidth: 2)
                        .frame(width: 90, height: 90)
                    Text(viewModel.initials)
                        .font(AppTypography.title2)
                        .foregroundStyle(.white)
                }

                Text(viewModel.fullName)
                    .font(AppTypography.title3)
                    .foregroundStyle(.white)
                    .padding(.top, AppMetrics.spacing20)

                Text(viewModel.email)
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(1)
                    .padding(.top, AppMetrics.spacing4)

                if !viewModel.role.isEmpty {
                    HStack(spacing: 5) {
                        Circle().fill(AppColors.brandPrimary).frame(width: 5, height: 5)
                        Text(viewModel.role)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.brandPrimary)
                    }
                    .padding(.horizontal, AppMetrics.spacing10)
                    .padding(.vertical, AppMetrics.spacing4)
                    .background(AppColors.brandPrimary.opacity(0.15))
                    .cornerRadius(20)
                    .padding(.top, AppMetrics.spacing12)
                }

                if !viewModel.facilityName.isEmpty {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.35))
                        Text(viewModel.facilityName)
                            .font(AppTypography.caption)
                            .foregroundStyle(Color.white.opacity(0.45))
                            .lineLimit(1)
                    }
                    .padding(.top, AppMetrics.spacing8)
                }

                Spacer()

                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.bottom, AppMetrics.spacing24)

                Button { viewModel.confirmLogout() } label: {
                    HStack(spacing: AppMetrics.spacing10) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                        Text(L10n.Menu.logout)
                            .font(AppTypography.bodyMedium)
                    }
                    .foregroundStyle(AppColors.statusCritical)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing14)
                    .background(AppColors.statusCritical.opacity(0.1))
                    .cornerRadius(AppMetrics.radiusMedium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                            .stroke(AppColors.statusCritical.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.hapticPlain)

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, AppMetrics.spacing32)
        }
    }

    // MARK: - Decorative ECG line

    private var ecgDecoration: some View {
        GeometryReader { geo in
            Path { path in
                let w  = geo.size.width
                let cy = geo.size.height * 0.72
                let s  = w / 18.0
                path.move(to: CGPoint(x: 0,      y: cy))
                path.addLine(to: CGPoint(x: s * 3,  y: cy))
                path.addLine(to: CGPoint(x: s * 4,  y: cy - 18))
                path.addLine(to: CGPoint(x: s * 5,  y: cy + 44))
                path.addLine(to: CGPoint(x: s * 6,  y: cy - 60))
                path.addLine(to: CGPoint(x: s * 7,  y: cy + 44))
                path.addLine(to: CGPoint(x: s * 8,  y: cy - 18))
                path.addLine(to: CGPoint(x: s * 9,  y: cy))
                path.addLine(to: CGPoint(x: s * 11, y: cy))
                path.addLine(to: CGPoint(x: s * 12, y: cy - 10))
                path.addLine(to: CGPoint(x: s * 13, y: cy + 10))
                path.addLine(to: CGPoint(x: s * 14, y: cy))
                path.addLine(to: CGPoint(x: w,       y: cy))
            }
            .stroke(
                AppColors.brandPrimary.opacity(0.08),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Settings Panel (right side)

private struct SettingsPanelView: View {

    @Bindable var settings: SettingsViewModel
    let onMyAccount: () -> Void
    let onFAQ:       () -> Void
    let onIFU:       () -> Void
    let onSupport:   () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppMetrics.spacing28) {

                // Header
                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(L10n.Menu.title)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.Menu.sectionSubtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.top, AppMetrics.spacing48)

                // ── ACCOUNT ──────────────────────────────────────────────
                menuSection(header: L10n.Menu.sectionAccount) {
                    MenuNavRow(
                        icon:      "person.circle.fill",
                        iconColor: AppColors.brandPrimary,
                        title:     L10n.Menu.myAccount,
                        subtitle:  L10n.Menu.subtitleMyAccount,
                        action:    onMyAccount
                    )
                }

                // ── EKG SIGNAL ────────────────────────────────────────────
                menuSection(header: L10n.Settings.ECG.sectionTitle) {
                    SettingRow(icon: "waveform.path.ecg", iconColor: AppColors.brandPrimary,
                               title: L10n.Settings.ECG.emgTitle) {
                        Picker("", selection: $settings.emgFilter) {
                            ForEach(EMGFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 210)
                    }
                    SettingRow(icon: "arrow.up.to.line", iconColor: AppColors.accentTeal,
                               title: L10n.Settings.ECG.highPassTitle) {
                        Picker("", selection: $settings.highPass) {
                            ForEach(HighPassFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.brandPrimary)
                        .font(AppTypography.callout)
                    }
                    SettingRow(icon: "arrow.down.to.line", iconColor: AppColors.accentCyan,
                               title: L10n.Settings.ECG.lowPassTitle) {
                        Picker("", selection: $settings.lowPass) {
                            ForEach(LowPassFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.brandPrimary)
                        .font(AppTypography.callout)
                    }
                    SettingRow(icon: "bolt.fill", iconColor: AppColors.statusWarning,
                               title: L10n.Settings.ECG.acNotchTitle) {
                        Picker("", selection: $settings.acNotch) {
                            ForEach(ACNotch.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 190)
                    }
                    SettingRow(icon: "list.number", iconColor: AppColors.accentViolet,
                               title: L10n.Settings.ECG.minnesotaTitle) {
                        Toggle("", isOn: $settings.minnesotaCodeEnabled)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                    SettingRow(icon: "eye.fill", iconColor: AppColors.brandSecondary,
                               title: L10n.Settings.ECG.leadV5Title) {
                        Toggle("", isOn: $settings.showLeadV5)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                }

                // ── DISPLAY ───────────────────────────────────────────────
                menuSection(header: L10n.Settings.Display.sectionTitle) {
                    SettingRow(icon: "moon.fill",
                               iconColor: Color(red: 0.38, green: 0.29, blue: 0.88),
                               title: L10n.Settings.Display.darkModeTitle) {
                        Toggle("", isOn: $settings.darkModeEnabled)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                    SettingRow(icon: "textformat.size",
                               iconColor: AppColors.accentCyan,
                               title: L10n.Settings.Display.fontSizeTitle) {
                        Picker("", selection: $settings.fontSize) {
                            ForEach(FontSize.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 210)
                    }
                    SettingRow(icon: "scalemass.fill",
                               iconColor: AppColors.accentTeal,
                               title: "Weight Unit") {
                        Picker("", selection: $settings.weightUnit) {
                            ForEach(WeightUnit.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    SettingRow(icon: "thermometer.medium",
                               iconColor: AppColors.statusCritical,
                               title: "Temperature Unit") {
                        Picker("", selection: $settings.temperatureUnit) {
                            ForEach(TemperatureUnit.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    SettingRow(icon: "speaker.wave.2.fill",
                               iconColor: AppColors.brandPrimary,
                               title: "Tap Sound") {
                        Toggle("", isOn: $settings.tapSoundEnabled)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                }

                // ── SECURITY ──────────────────────────────────────────────
                menuSection(header: L10n.Settings.Security.sectionTitle) {
                    SettingRow(icon: "lock.fill", iconColor: AppColors.statusWarning,
                               title: L10n.Settings.Security.autoLockTitle) {
                        Picker("", selection: $settings.autoLock) {
                            ForEach(AutoLock.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
                    }
                    SettingRow(icon: "play.circle.fill", iconColor: AppColors.textSecondary,
                               title: L10n.Settings.Security.demoTitle) {
                        Toggle("", isOn: Binding(
                            get: { settings.demoDataEnabled },
                            set: { _ in settings.attemptEnableDemoData() }
                        ))
                        .labelsHidden()
                        .tint(AppColors.brandPrimary)
                    }
                }

                // ── PRIVACY ───────────────────────────────────────────────
                menuSection(header: L10n.Settings.Privacy.sectionTitle) {
                    SettingRow(icon: "envelope.fill", iconColor: AppColors.statusInfo,
                               title: L10n.Settings.Privacy.promoEmailTitle) {
                        Toggle("", isOn: $settings.allowPromotionalEmails)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                }

                // ── HELP & INFORMATION ────────────────────────────────────
                menuSection(header: L10n.Menu.sectionHelp) {
                    MenuNavRow(
                        icon:      "questionmark.circle.fill",
                        iconColor: AppColors.accentTeal,
                        title:     L10n.Menu.faq,
                        subtitle:  L10n.Menu.subtitleFAQ,
                        action:    onFAQ
                    )
                    MenuNavRow(
                        icon:      "doc.text.fill",
                        iconColor: AppColors.accentViolet,
                        title:     L10n.Menu.indicationsForUse,
                        subtitle:  L10n.Menu.subtitleIFU,
                        action:    onIFU
                    )
                    MenuNavRow(
                        icon:      "headphones.circle.fill",
                        iconColor: AppColors.accentCyan,
                        title:     L10n.Menu.support,
                        subtitle:  L10n.Menu.subtitleSupport,
                        action:    onSupport
                    )
                }
            }
            .padding(.horizontal, AppMetrics.spacing40)
            .padding(.bottom, AppMetrics.spacing48)
        }
        .background(AppColors.surfaceBackground)
        .alert(L10n.Settings.Demo.sheetTitle, isPresented: $settings.showDemoCodeEntry) {
            TextField(L10n.Settings.Demo.fieldPH, text: $settings.demoCodeInput)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            Button(L10n.Settings.Demo.unlockButton) { settings.submitDemoCode() }
            Button(L10n.Common.cancel, role: .cancel) { settings.cancelDemoCode() }
        } message: {
            Text(settings.demoCodeError ?? L10n.Settings.Demo.sheetSubtitle)
        }
    }

    // MARK: - Section builder

    @ViewBuilder
    private func menuSection<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing10) {
            HStack(spacing: AppMetrics.spacing8) {
                Text(header.uppercased())
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                    .tracking(1.2)
                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.5))
                    .frame(height: 1)
            }
            VStack(spacing: AppMetrics.spacing6) {
                content()
            }
        }
    }
}

// MARK: - Setting Row (inline control: Toggle / Picker)

private struct SettingRow<Control: View>: View {

    let icon:      String
    let iconColor: Color
    let title:     String
    let control:   Control

    init(icon: String, iconColor: Color, title: String, @ViewBuilder control: () -> Control) {
        self.icon      = icon
        self.iconColor = iconColor
        self.title     = title
        self.control   = control()
    }

    var body: some View {
        HStack(spacing: AppMetrics.spacing14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.13))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            control
        }
        .padding(.horizontal, AppMetrics.spacing16)
        .padding(.vertical, AppMetrics.spacing12)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppMetrics.radiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .stroke(AppColors.borderSubtle.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Menu Nav Row (navigates to another screen)

private struct MenuNavRow: View {

    let icon:      String
    let iconColor: Color
    let title:     String
    let subtitle:  String
    let action:    () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppMetrics.spacing16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(title)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.borderSubtle)
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.vertical, AppMetrics.spacing16)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .stroke(AppColors.borderSubtle.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(MenuButtonStyle())
    }
}

// MARK: - Press animation

private struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.975 : 1, anchor: .center)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
