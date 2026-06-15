//
//  PhoneMenuLayout.swift
//  EKGx
//
//  Single-column menu / settings for iPhone:
//  dark profile header → scrollable settings sections → logout button.
//

import SwiftUI

struct PhoneMenuLayout: View {

    @Bindable var viewModel: MenuViewModel
    @Bindable var settings:  SettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            profileHeader
            settingsScroll
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing16) {
            // Nav row
            HStack {
                Button(action: viewModel.close) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)

                Spacer()

                AppImages.logo
                    .resizable()
                    .scaledToFit()
                    .frame(height: 25)
                    .opacity(0.8)
            }

            // Avatar + info row
            HStack(alignment: .center, spacing: AppMetrics.spacing16) {
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.22))
                        .frame(width: 60, height: 60)
                    Circle()
                        .stroke(AppColors.brandPrimary.opacity(0.4), lineWidth: 2)
                        .frame(width: 60, height: 60)
                    Text(viewModel.initials)
                        .font(AppTypography.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(viewModel.fullName)
                        .font(AppTypography.phoneBodyMedium)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(viewModel.email)
                        .font(AppTypography.phoneCaption)
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)

                    HStack(spacing: AppMetrics.spacing8) {
                        if !viewModel.role.isEmpty {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(AppColors.brandPrimary)
                                    .frame(width: 5, height: 5)
                                Text(viewModel.role)
                                    .font(AppTypography.phoneCaption)
                                    .foregroundStyle(AppColors.brandPrimary)
                            }
                            .padding(.horizontal, AppMetrics.spacing8)
                            .padding(.vertical, 3)
                            .background(AppColors.brandPrimary.opacity(0.15))
                            .cornerRadius(20)
                        }

                        if !viewModel.facilityName.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.35))
                                Text(viewModel.facilityName)
                                    .font(AppTypography.phoneCaption)
                                    .foregroundStyle(.white.opacity(0.45))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(.top, 54)
        .padding(.horizontal, AppMetrics.spacing20)
        .padding(.bottom, AppMetrics.spacing24)
        .background(
            LinearGradient(
                colors: [AppColors.surfaceSidebar, AppColors.surfaceSidebar.opacity(0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .overlay(ecgDecoration)
    }

    // MARK: - Settings Scroll

    private var settingsScroll: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppMetrics.spacing24) {

                // ── ACCOUNT ──────────────────────────────────────────────
                section(header: L10n.Menu.sectionAccount) {
                    PhoneMenuNavRow(
                        icon: "person.circle.fill", iconColor: AppColors.brandPrimary,
                        title: L10n.Menu.myAccount, subtitle: L10n.Menu.subtitleMyAccount,
                        action: viewModel.goToMyAccount
                    )
                }

                // ── EKG SIGNAL ────────────────────────────────────────────
                section(header: L10n.Settings.ECG.sectionTitle) {
                    PhoneSettingRow(icon: "waveform.path.ecg", iconColor: AppColors.brandPrimary,
                                    title: L10n.Settings.ECG.emgTitle) {
                        Picker("", selection: $settings.emgFilter) {
                            ForEach(EMGFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.brandPrimary)
                    }
                    PhoneSettingRow(icon: "arrow.up.to.line", iconColor: AppColors.accentTeal,
                                    title: L10n.Settings.ECG.highPassTitle) {
                        Picker("", selection: $settings.highPass) {
                            ForEach(HighPassFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.brandPrimary)
                    }
                    PhoneSettingRow(icon: "arrow.down.to.line", iconColor: AppColors.accentCyan,
                                    title: L10n.Settings.ECG.lowPassTitle) {
                        Picker("", selection: $settings.lowPass) {
                            ForEach(LowPassFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.brandPrimary)
                    }
                    PhoneSettingRow(icon: "bolt.fill", iconColor: AppColors.statusWarning,
                                    title: L10n.Settings.ECG.acNotchTitle) {
                        Picker("", selection: $settings.acNotch) {
                            ForEach(ACNotch.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    PhoneSettingRow(icon: "list.number", iconColor: AppColors.accentViolet,
                                    title: L10n.Settings.ECG.minnesotaTitle) {
                        Toggle("", isOn: $settings.minnesotaCodeEnabled)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                    PhoneSettingRow(icon: "eye.fill", iconColor: AppColors.brandSecondary,
                                    title: L10n.Settings.ECG.leadV5Title) {
                        Toggle("", isOn: $settings.showLeadV5)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                }

                // ── DISPLAY ───────────────────────────────────────────────
                section(header: L10n.Settings.Display.sectionTitle) {
                    PhoneSettingRow(icon: "moon.fill",
                                    iconColor: Color(red: 0.38, green: 0.29, blue: 0.88),
                                    title: L10n.Settings.Display.darkModeTitle) {
                        Toggle("", isOn: $settings.darkModeEnabled)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                    PhoneSettingRow(icon: "textformat.size", iconColor: AppColors.accentCyan,
                                    title: L10n.Settings.Display.fontSizeTitle) {
                        Picker("", selection: $settings.fontSize) {
                            ForEach(FontSize.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.brandPrimary)
                    }
                    PhoneSettingRow(icon: "scalemass.fill", iconColor: AppColors.accentTeal,
                                    title: "Weight Unit") {
                        Picker("", selection: $settings.weightUnit) {
                            ForEach(WeightUnit.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                    PhoneSettingRow(icon: "thermometer.medium", iconColor: AppColors.statusCritical,
                                    title: "Temperature Unit") {
                        Picker("", selection: $settings.temperatureUnit) {
                            ForEach(TemperatureUnit.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                    PhoneSettingRow(icon: "speaker.wave.2.fill", iconColor: AppColors.brandPrimary,
                                    title: "Tap Sound") {
                        Toggle("", isOn: $settings.tapSoundEnabled)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                }

                // ── SECURITY ──────────────────────────────────────────────
                section(header: L10n.Settings.Security.sectionTitle) {
                    PhoneSettingRow(icon: "lock.fill", iconColor: AppColors.statusWarning,
                                    title: L10n.Settings.Security.autoLockTitle) {
                        Picker("", selection: $settings.autoLock) {
                            ForEach(AutoLock.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.brandPrimary)
                    }
                    PhoneSettingRow(icon: "play.circle.fill", iconColor: AppColors.textSecondary,
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
                section(header: L10n.Settings.Privacy.sectionTitle) {
                    PhoneSettingRow(icon: "envelope.fill", iconColor: AppColors.statusInfo,
                                    title: L10n.Settings.Privacy.promoEmailTitle) {
                        Toggle("", isOn: $settings.allowPromotionalEmails)
                            .labelsHidden()
                            .tint(AppColors.brandPrimary)
                    }
                }

                // ── HELP & INFORMATION ────────────────────────────────────
                section(header: L10n.Menu.sectionHelp) {
                    PhoneMenuNavRow(
                        icon: "questionmark.circle.fill", iconColor: AppColors.accentTeal,
                        title: L10n.Menu.faq, subtitle: L10n.Menu.subtitleFAQ,
                        action: viewModel.goToFAQ
                    )
                    PhoneMenuNavRow(
                        icon: "doc.text.fill", iconColor: AppColors.accentViolet,
                        title: L10n.Menu.indicationsForUse, subtitle: L10n.Menu.subtitleIFU,
                        action: viewModel.goToIFU
                    )
                    PhoneMenuNavRow(
                        icon: "headphones.circle.fill", iconColor: AppColors.accentCyan,
                        title: L10n.Menu.support, subtitle: L10n.Menu.subtitleSupport,
                        action: viewModel.goToSupport
                    )
                }

                // ── LOGOUT ────────────────────────────────────────────────
                Button(action: viewModel.confirmLogout) {
                    HStack(spacing: AppMetrics.spacing10) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                        Text(L10n.Menu.logout)
                            .font(AppTypography.phoneBodyMedium)
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
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.top, AppMetrics.spacing28)
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
    private func section<Content: View>(
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

    // MARK: - ECG decoration

    private var ecgDecoration: some View {
        GeometryReader { geo in
            Path { path in
                let w  = geo.size.width
                let cy = geo.size.height * 0.68
                let s  = w / 14.0
                path.move(to: CGPoint(x: 0, y: cy))
                path.addLine(to: CGPoint(x: s * 2,  y: cy))
                path.addLine(to: CGPoint(x: s * 3,  y: cy - 14))
                path.addLine(to: CGPoint(x: s * 4,  y: cy + 36))
                path.addLine(to: CGPoint(x: s * 5,  y: cy - 48))
                path.addLine(to: CGPoint(x: s * 6,  y: cy + 36))
                path.addLine(to: CGPoint(x: s * 7,  y: cy - 14))
                path.addLine(to: CGPoint(x: s * 8,  y: cy))
                path.addLine(to: CGPoint(x: s * 10, y: cy))
                path.addLine(to: CGPoint(x: s * 11, y: cy - 8))
                path.addLine(to: CGPoint(x: s * 12, y: cy + 8))
                path.addLine(to: CGPoint(x: s * 13, y: cy))
                path.addLine(to: CGPoint(x: w,       y: cy))
            }
            .stroke(
                AppColors.brandPrimary.opacity(0.1),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Phone Setting Row

private struct PhoneSettingRow<Control: View>: View {

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
        HStack(spacing: AppMetrics.spacing12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(iconColor.opacity(0.13))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(AppTypography.phoneBodyMedium)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            control
        }
        .padding(.horizontal, AppMetrics.spacing14)
        .padding(.vertical, AppMetrics.spacing12)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppMetrics.radiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .stroke(AppColors.borderSubtle.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Phone Nav Row

private struct PhoneMenuNavRow: View {

    let icon:      String
    let iconColor: Color
    let title:     String
    let subtitle:  String
    let action:    () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppMetrics.spacing14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(title)
                        .font(AppTypography.phoneBodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.phoneCaption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.borderSubtle)
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .padding(.vertical, AppMetrics.spacing14)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .stroke(AppColors.borderSubtle.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.hapticPlain)
    }
}
