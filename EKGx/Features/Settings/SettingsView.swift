//
//  SettingsView.swift
//  EKGx
//
//  Settings — iPad landscape master-detail layout.
//
//  ┌──────────────────┬────────────────────────────────────────────────────┐
//  │  SETTINGS        │  ECG Signal                                         │
//  │  ──────────      │  ─────────────────────────────────────────────────  │
//  │  ECG Signal  ▶   │  Minnesota Code    [toggle]                         │
//  │  Display         │  Show Lead V5      [toggle]                         │
//  │  Privacy         │  EMG Filter        [Off ▾]                          │
//  │  Security        │  High Pass         [0.05 Hz ▾]                      │
//  │                  │  Low Pass          [100 Hz ▾]                       │
//  │                  │  AC Notch          [60 Hz ▾]                        │
//  └──────────────────┴────────────────────────────────────────────────────┘
//

import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {

    @State private var viewModel: SettingsViewModel
    @State private var selectedSection: SettingsViewModel.Section = .ecgSignal

    init(viewModel: SettingsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                SettingsNavBar(viewModel: viewModel)

                HStack(spacing: 0) {
                    // ── LEFT: Section list
                    SectionPanel(
                        selectedSection: $selectedSection,
                        hasUnsavedChanges: viewModel.hasUnsavedChanges
                    )
                    .frame(width: 260)

                    Rectangle()
                        .fill(AppColors.borderSubtle.opacity(0.6))
                        .frame(width: 1)
                        .ignoresSafeArea(edges: .bottom)

                    // ── RIGHT: Section content
                    ScrollView {
                        sectionContent
                            .padding(.horizontal, AppMetrics.spacing40)
                            .padding(.vertical, AppMetrics.spacing32)
                            .frame(maxWidth: 760)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $viewModel.showDemoCodeEntry) {
            DemoCodeSheet(viewModel: viewModel)
        }
    }

    // MARK: - Section router

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .ecgSignal: ECGSignalSection(viewModel: viewModel)
        case .display:   DisplaySection(viewModel: viewModel)
        case .privacy:   PrivacySection(viewModel: viewModel)
        case .security:  SecuritySection(viewModel: viewModel)
        }
    }
}

// MARK: - Nav Bar

private struct SettingsNavBar: View {

    let viewModel: SettingsViewModel

    var body: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing16) {
            Button(action: { viewModel.navigateBack() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text(L10n.Home.Nav.menuButton)
                        .font(AppTypography.callout)
                }
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppMetrics.spacing16)
                .padding(.vertical, AppMetrics.spacing8)
                .background(AppColors.borderSubtle.opacity(0.5))
                .cornerRadius(AppMetrics.radiusMedium)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Settings.Nav.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Settings.Nav.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            // Unsaved changes indicator
            if viewModel.hasUnsavedChanges {
                HStack(spacing: AppMetrics.spacing6) {
                    Circle()
                        .fill(AppColors.statusWarning)
                        .frame(width: 7, height: 7)
                    Text(L10n.Settings.Nav.unsavedChanges)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.statusWarning)
                }
                .padding(.horizontal, AppMetrics.spacing12)
                .padding(.vertical, AppMetrics.spacing6)
                .background(AppColors.statusWarning.opacity(0.08))
                .clipShape(Capsule())
            }

            // Discard
            Button(action: { viewModel.discardChanges() }) {
                Text(L10n.Settings.Nav.discardChanges)
                    .font(AppTypography.callout)
                    .foregroundStyle(viewModel.hasUnsavedChanges ? AppColors.statusCritical : AppColors.textSecondary.opacity(0.4))
            }
            .disabled(!viewModel.hasUnsavedChanges)

            // Save
            Button(action: { viewModel.saveChanges() }) {
                Text(L10n.Settings.Nav.saveChanges)
                    .font(AppTypography.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppMetrics.spacing20)
                    .padding(.vertical, AppMetrics.spacing10)
                    .background(viewModel.hasUnsavedChanges ? AppColors.brandPrimary : AppColors.borderSubtle)
                    .cornerRadius(AppMetrics.radiusMedium)
            }
            .disabled(!viewModel.hasUnsavedChanges)
            .animation(.easeInOut(duration: 0.2), value: viewModel.hasUnsavedChanges)
        }
        .padding(.horizontal, AppMetrics.spacing32)
        .frame(height: AppMetrics.navBarHeight)
        .background(AppColors.surfaceCard)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Section Panel (left)

private struct SectionPanel: View {

    @Binding var selectedSection: SettingsViewModel.Section
    let hasUnsavedChanges: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.Settings.Panel.categories.uppercased())
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .tracking(1)
                .padding(.horizontal, AppMetrics.spacing24)
                .padding(.top, AppMetrics.spacing24)
                .padding(.bottom, AppMetrics.spacing12)

            ForEach(SettingsViewModel.Section.allCases) { section in
                SectionRow(
                    section: section,
                    isSelected: selectedSection == section
                ) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedSection = section
                    }
                }
            }

            Spacer()
        }
        .background(AppColors.surfaceCard)
    }
}

private struct SectionRow: View {

    let section: SettingsViewModel.Section
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppMetrics.spacing14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? AppColors.brandPrimary : AppColors.borderSubtle.opacity(0.5))
                        .frame(width: 34, height: 34)
                    Image(systemName: section.systemImage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
                }

                Text(section.rawValue)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(isSelected ? AppColors.brandPrimary : AppColors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary)
                }
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.vertical, AppMetrics.spacing14)
            .background(isSelected ? AppColors.brandPrimary.opacity(0.06) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared Components

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
            Text(title)
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
            Text(subtitle)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.bottom, AppMetrics.spacing8)
    }
}

private struct SettingsCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(spacing: 0) { content }
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(AppColors.borderSubtle.opacity(0.6), lineWidth: AppMetrics.borderWidth)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

private struct ToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppMetrics.spacing16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing2) {
                    Text(title)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.brandPrimary))
                    .labelsHidden()
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.vertical, AppMetrics.spacing16)

            if showDivider {
                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.5))
                    .frame(height: 1)
                    .padding(.leading, AppMetrics.spacing76)
            }
        }
    }
}

private struct PickerRow<T: RawRepresentable & CaseIterable & Identifiable & Hashable>: View where T.RawValue == String {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var selection: T
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppMetrics.spacing16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing2) {
                    Text(title)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Menu {
                    ForEach(Array(T.allCases as! [T])) { option in
                        Button {
                            selection = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if selection == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: AppMetrics.spacing6) {
                        Text(selection.rawValue)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.brandPrimary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppColors.brandPrimary)
                    }
                    .padding(.horizontal, AppMetrics.spacing14)
                    .padding(.vertical, AppMetrics.spacing8)
                    .background(AppColors.brandPrimary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusSmall))
                }
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.vertical, AppMetrics.spacing16)

            if showDivider {
                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.5))
                    .frame(height: 1)
                    .padding(.leading, AppMetrics.spacing76)
            }
        }
    }
}

// MARK: - ECG Signal Section

private struct ECGSignalSection: View {

    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing28) {

            SectionHeader(
                title: L10n.Settings.ECG.sectionTitle,
                subtitle: L10n.Settings.ECG.sectionSubtitle
            )

            // Toggles
            SettingsCard {
                ToggleRow(
                    icon: "list.clipboard",
                    iconColor: AppColors.brandPrimary,
                    title: L10n.Settings.ECG.minnesotaTitle,
                    subtitle: L10n.Settings.ECG.minnesotaSubtitle,
                    isOn: $viewModel.minnesotaCodeEnabled
                )
                ToggleRow(
                    icon: "waveform",
                    iconColor: AppColors.brandSecondary,
                    title: L10n.Settings.ECG.leadV5Title,
                    subtitle: L10n.Settings.ECG.leadV5Subtitle,
                    isOn: $viewModel.showLeadV5,
                    showDivider: false
                )
            }

            // Filters
            SettingsCard {
                PickerRow(
                    icon: "antenna.radiowaves.left.and.right",
                    iconColor: AppColors.statusWarning,
                    title: L10n.Settings.ECG.emgTitle,
                    subtitle: L10n.Settings.ECG.emgSubtitle,
                    selection: $viewModel.emgFilter
                )
                PickerRow(
                    icon: "arrow.up.right",
                    iconColor: AppColors.statusInfo,
                    title: L10n.Settings.ECG.highPassTitle,
                    subtitle: L10n.Settings.ECG.highPassSubtitle,
                    selection: $viewModel.highPass
                )
                PickerRow(
                    icon: "arrow.down.right",
                    iconColor: AppColors.statusInfo,
                    title: L10n.Settings.ECG.lowPassTitle,
                    subtitle: L10n.Settings.ECG.lowPassSubtitle,
                    selection: $viewModel.lowPass
                )
                PickerRow(
                    icon: "poweroutlet.type.b",
                    iconColor: AppColors.statusCritical,
                    title: L10n.Settings.ECG.acNotchTitle,
                    subtitle: L10n.Settings.ECG.acNotchSubtitle,
                    selection: $viewModel.acNotch,
                    showDivider: false
                )
            }
        }
    }
}

// MARK: - Display Section

private struct DisplaySection: View {

    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing28) {

            SectionHeader(
                title: L10n.Settings.Display.sectionTitle,
                subtitle: L10n.Settings.Display.sectionSubtitle
            )

            SettingsCard {
                ToggleRow(
                    icon: "moon.fill",
                    iconColor: Color(red: 0.45, green: 0.31, blue: 0.82),
                    title: L10n.Settings.Display.darkModeTitle,
                    subtitle: L10n.Settings.Display.darkModeSubtitle,
                    isOn: $viewModel.darkModeEnabled,
                    showDivider: false
                )
            }
        }
    }
}

// MARK: - Privacy Section

private struct PrivacySection: View {

    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing28) {

            SectionHeader(
                title: L10n.Settings.Privacy.sectionTitle,
                subtitle: L10n.Settings.Privacy.sectionSubtitle
            )

            SettingsCard {
                ToggleRow(
                    icon: "envelope",
                    iconColor: AppColors.statusInfo,
                    title: L10n.Settings.Privacy.promoEmailTitle,
                    subtitle: L10n.Settings.Privacy.promoEmailSubtitle,
                    isOn: $viewModel.allowPromotionalEmails,
                    showDivider: false
                )
            }
        }
    }
}

// MARK: - Security Section

private struct SecuritySection: View {

    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing28) {

            SectionHeader(
                title: L10n.Settings.Security.sectionTitle,
                subtitle: L10n.Settings.Security.sectionSubtitle
            )

            SettingsCard {
                PickerRow(
                    icon: "lock.rotation",
                    iconColor: AppColors.brandPrimary,
                    title: L10n.Settings.Security.autoLockTitle,
                    subtitle: L10n.Settings.Security.autoLockSubtitle,
                    selection: $viewModel.autoLock
                )

                // Demo Data — custom row with code gate
                DemoDataRow(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Demo Data Row

private struct DemoDataRow: View {

    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppMetrics.spacing16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(AppColors.statusSuccess.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "play.rectangle.on.rectangle")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppColors.statusSuccess)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing2) {
                    HStack(spacing: AppMetrics.spacing8) {
                        Text(L10n.Settings.Security.demoTitle)
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        if viewModel.demoDataEnabled {
                            Text(L10n.Settings.Security.demoActiveBadge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppColors.statusSuccess)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.statusSuccess.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    Text(L10n.Settings.Security.demoSubtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.demoDataEnabled },
                    set: { _ in viewModel.attemptEnableDemoData() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: AppColors.statusSuccess))
                .labelsHidden()
            }
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.vertical, AppMetrics.spacing16)
        }
    }
}

// MARK: - Demo Code Sheet

private struct DemoCodeSheet: View {

    @Bindable var viewModel: SettingsViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                        Text(L10n.Settings.Demo.sheetTitle)
                            .font(AppTypography.title2)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(L10n.Settings.Demo.sheetSubtitle)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Button { viewModel.cancelDemoCode() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(AppColors.borderSubtle.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppMetrics.spacing40)
                .padding(.top, AppMetrics.spacing32)
                .padding(.bottom, AppMetrics.spacing24)

                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.6))
                    .frame(height: 1)
                    .padding(.horizontal, AppMetrics.spacing40)

                VStack(alignment: .leading, spacing: AppMetrics.spacing20) {
                    // Code icon
                    ZStack {
                        RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                            .fill(AppColors.statusSuccess.opacity(0.1))
                            .frame(width: 64, height: 64)
                        Image(systemName: "key.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppColors.statusSuccess)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppMetrics.spacing8)

                    // Code input
                    VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                        Text(L10n.Settings.Demo.fieldLabel.uppercased())
                            .font(AppTypography.captionBold)
                            .foregroundStyle(AppColors.textSecondary)
                            .tracking(0.5)

                        HStack {
                            SecureField(L10n.Settings.Demo.fieldPH, text: $viewModel.demoCodeInput)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textPrimary)
                                .focused($isFocused)
                                .onSubmit { viewModel.submitDemoCode() }
                                .submitLabel(.done)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(.horizontal, AppMetrics.spacing16)
                        .frame(height: AppMetrics.textFieldHeight)
                        .background(AppColors.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                                .strokeBorder(
                                    viewModel.demoCodeError != nil ? AppColors.statusCritical : AppColors.borderSubtle,
                                    lineWidth: viewModel.demoCodeError != nil ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                                )
                        )

                        if let error = viewModel.demoCodeError {
                            HStack(spacing: AppMetrics.spacing4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                Text(error)
                                    .font(AppTypography.caption)
                            }
                            .foregroundStyle(AppColors.statusCritical)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: viewModel.demoCodeError)

                    // Actions
                    HStack(spacing: AppMetrics.spacing12) {
                        SecondaryButton(title: L10n.Common.cancel) { viewModel.cancelDemoCode() }
                        PrimaryButton(title: L10n.Settings.Demo.unlockButton, isLoading: false) { viewModel.submitDemoCode() }
                    }
                }
                .padding(.horizontal, AppMetrics.spacing40)
                .padding(.top, AppMetrics.spacing28)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)

                Spacer()
            }
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - AppMetrics spacing76

private extension AppMetrics {
    static let spacing76: CGFloat = 76
}

// MARK: - Preview

#Preview {
    let router = AppRouter()
    SettingsView(viewModel: SettingsViewModel(router: router))
        .environment(router)
}
