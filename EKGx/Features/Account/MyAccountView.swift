//
//  MyAccountView.swift
//  EKGx
//
//  My Account — iPad landscape single-column scroll layout.
//
//  ┌──────────────────────────────────────────────────────────────────────┐
//  │  ← Dashboard   My Account   ···   [Discard Changes]  [Save Changes] │
//  ├──────────────────────────────────────────────────────────────────────┤
//  │                                                                      │
//  │   [Avatar]  Profile Picture                                          │
//  │                                                                      │
//  │   Personal Information   ──────────────────────────────────────      │
//  │   First Name  /  Last Name                                           │
//  │   Email  /  Confirm Email                                            │
//  │                                                                      │
//  │   Security  ───────────────────────────────────────────────────      │
//  │   [Set PIN Code]  [Change Password]                                  │
//  │                                                                      │
//  │   Danger Zone  ────────────────────────────────────────────────      │
//  │   [Deactivate Account]                                               │
//  └──────────────────────────────────────────────────────────────────────┘
//

import SwiftUI

// MARK: - MyAccountView

struct MyAccountView: View {

    @State private var viewModel: MyAccountViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    init(viewModel: MyAccountViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AccountNavBar(viewModel: viewModel)

                ScrollView {
                    VStack(alignment: .leading, spacing: isCompact ? AppMetrics.spacing20 : AppMetrics.spacing32) {

                        ProfilePictureSection(viewModel: viewModel)

                        AccountFormCard(
                            title: L10n.Account.Personal.sectionTitle,
                            subtitle: L10n.Account.Personal.sectionSubtitle
                        ) {
                            PersonalInfoSection(viewModel: viewModel)
                        }

                        AccountFormCard(
                            title: L10n.Account.Security.sectionTitle,
                            subtitle: L10n.Account.Security.sectionSubtitle
                        ) {
                            SecurityActionsSection(viewModel: viewModel)
                        }

                        DangerZoneSection(viewModel: viewModel)

                        Color.clear.frame(height: AppMetrics.spacing32)
                    }
                    .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing48)
                    .padding(.vertical, isCompact ? AppMetrics.spacing20 : AppMetrics.spacing32)
                    .frame(maxWidth: isCompact ? .infinity : 860)
                    .frame(maxWidth: .infinity)
                }
            }

            // iPad overlays only — iPhone uses native .sheet below
            if !isCompact {
                if viewModel.showSetPinSheet {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    SetPinSheet(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                if viewModel.showChangePasswordSheet {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    ChangePasswordSheet(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.showSetPinSheet)
        .animation(.easeInOut(duration: 0.22), value: viewModel.showChangePasswordSheet)
        // iPhone: native bottom sheets with built-in keyboard avoidance
        .sheet(isPresented: Binding(
            get: { isCompact && viewModel.showSetPinSheet },
            set: { if !$0 { viewModel.showSetPinSheet = false } }
        )) {
            SetPinSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { isCompact && viewModel.showChangePasswordSheet },
            set: { if !$0 { viewModel.showChangePasswordSheet = false } }
        )) {
            ChangePasswordSheet(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert(L10n.Account.Danger.alertTitle, isPresented: $viewModel.showDeactivateAlert) {
            Button(L10n.Account.Danger.alertCancel, role: .cancel) {}
            Button(L10n.Account.Danger.alertConfirm, role: .destructive) { viewModel.executeDeactivate() }
        } message: {
            Text(L10n.Account.Danger.alertMessage)
        }
        .onAppear { viewModel.activate() }
    }
}

// MARK: - Nav Bar

private struct AccountNavBar: View {

    let viewModel: MyAccountViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        if isCompact { compactLayout } else { regularLayout }
    }

    // MARK: Regular (iPad) layout

    private var regularLayout: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing16) {
            Button(action: { viewModel.navigateBack() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text(L10n.Home.Nav.menuButton)
                }
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppMetrics.spacing16)
                .padding(.vertical, AppMetrics.spacing8)
                .background(AppColors.borderSubtle.opacity(0.5))
                .cornerRadius(AppMetrics.radiusMedium)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Account.Nav.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Account.Nav.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            if viewModel.hasUnsavedChanges {
                HStack(spacing: AppMetrics.spacing6) {
                    Circle()
                        .fill(AppColors.statusWarning)
                        .frame(width: 7, height: 7)
                    Text(L10n.Account.Nav.unsavedChanges)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.statusWarning)
                }
                .padding(.horizontal, AppMetrics.spacing12)
                .padding(.vertical, AppMetrics.spacing6)
                .background(AppColors.statusWarning.opacity(0.08))
                .clipShape(Capsule())
            }

            Button(action: { viewModel.discardChanges() }) {
                Text(L10n.Account.Nav.discardChanges)
                    .font(AppTypography.callout)
                    .foregroundStyle(
                        viewModel.hasUnsavedChanges
                            ? AppColors.statusCritical
                            : AppColors.textSecondary.opacity(0.4)
                    )
            }
            .disabled(!viewModel.hasUnsavedChanges)

            Button(action: { viewModel.saveChanges() }) {
                Text(L10n.Account.Nav.saveChanges)
                    .font(AppTypography.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppMetrics.spacing20)
                    .padding(.vertical, AppMetrics.spacing10)
                    .background(
                        viewModel.hasUnsavedChanges
                            ? AppColors.brandPrimary
                            : AppColors.borderSubtle
                    )
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

    // MARK: Compact (iPhone) layout

    private var compactLayout: some View {
        HStack(spacing: AppMetrics.spacing12) {
            Button(action: { viewModel.navigateBack() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(AppColors.borderSubtle.opacity(0.5))
                    .cornerRadius(AppMetrics.radiusMedium)
            }
            .buttonStyle(.hapticPlain)

            Text(L10n.Account.Nav.title)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)

            if viewModel.hasUnsavedChanges {
                Button(action: { viewModel.discardChanges() }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.statusCritical)
                        .frame(width: 36, height: 36)
                        .background(AppColors.statusCritical.opacity(0.08))
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)
            }

            Button(action: { viewModel.saveChanges() }) {
                Text(L10n.Account.Nav.saveChanges)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppMetrics.spacing14)
                    .padding(.vertical, AppMetrics.spacing8)
                    .background(
                        viewModel.hasUnsavedChanges
                            ? AppColors.brandPrimary
                            : AppColors.borderSubtle
                    )
                    .cornerRadius(AppMetrics.radiusMedium)
            }
            .disabled(!viewModel.hasUnsavedChanges)
            .animation(.easeInOut(duration: 0.2), value: viewModel.hasUnsavedChanges)
        }
        .padding(.horizontal, AppMetrics.spacing16)
        .frame(height: 52)
        .background(AppColors.surfaceCard)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Reusable Card Wrapper

private struct AccountFormCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title    = title
        self.subtitle = subtitle
        self.content  = content()
    }

    var body: some View {
        let hPad: CGFloat = isCompact ? AppMetrics.spacing16 : AppMetrics.spacing24
        let vPad: CGFloat = isCompact ? AppMetrics.spacing14 : AppMetrics.spacing20
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(title)
                    .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, hPad)
            .padding(.top, vPad)
            .padding(.bottom, isCompact ? AppMetrics.spacing12 : AppMetrics.spacing16)

            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.6))
                .frame(height: 1)

            content
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
        }
        .background(AppColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .strokeBorder(AppColors.borderSubtle.opacity(0.6), lineWidth: AppMetrics.borderWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Profile Picture Section

private struct ProfilePictureSection: View {

    @Bindable var viewModel: MyAccountViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        let avatarSize: CGFloat = isCompact ? 72 : 96
        return HStack(spacing: isCompact ? AppMetrics.spacing16 : AppMetrics.spacing24) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let data = viewModel.profileImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [AppColors.brandPrimary, AppColors.brandSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Text(initials)
                                .font(.system(size: isCompact ? 22 : 32, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(AppColors.borderSubtle, lineWidth: AppMetrics.borderWidth))

                Button(action: { viewModel.requestProfileImageChange() }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.brandPrimary)
                            .frame(width: isCompact ? 24 : 30, height: isCompact ? 24 : 30)
                        Image(systemName: "camera.fill")
                            .font(.system(size: isCompact ? 10 : 13, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.hapticPlain)
                .offset(x: 3, y: 3)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text("\(viewModel.firstName) \(viewModel.lastName)")
                    .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.facilityName)
                    .font(isCompact ? AppTypography.phoneCallout : AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)

                Button(L10n.Account.Profile.changePhoto) {
                    viewModel.requestProfileImageChange()
                }
                .font(isCompact ? AppTypography.phoneCaption : AppTypography.captionBold)
                .foregroundStyle(AppColors.brandPrimary)
                .padding(.top, AppMetrics.spacing4)
            }

            Spacer()
        }
    }

    private var initials: String {
        let f = viewModel.firstName.prefix(1).uppercased()
        let l = viewModel.lastName.prefix(1).uppercased()
        return "\(f)\(l)"
    }
}

// MARK: - Personal Info Section

private struct PersonalInfoSection: View {

    @Bindable var viewModel: MyAccountViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        VStack(spacing: AppMetrics.spacing16) {
            if isCompact {
                VStack(spacing: AppMetrics.spacing12) {
                    firstNameField
                    lastNameField
                }
            } else {
                HStack(spacing: AppMetrics.spacing16) {
                    firstNameField
                    lastNameField
                }
            }
            ELockedField(
                label: L10n.Account.Personal.workEmail,
                value: viewModel.email,
                systemImage: "envelope"
            )
        }
    }

    private var firstNameField: some View {
        ETextField(
            label: L10n.Account.Personal.firstName,
            placeholder: L10n.Account.Personal.firstNamePH,
            systemImage: "person",
            text: $viewModel.firstName,
            errorMessage: viewModel.firstNameError,
            autocapitalization: .characters
        )
    }

    private var lastNameField: some View {
        ETextField(
            label: L10n.Account.Personal.lastName,
            placeholder: L10n.Account.Personal.lastNamePH,
            systemImage: "person",
            text: $viewModel.lastName,
            errorMessage: viewModel.lastNameError,
            autocapitalization: .characters
        )
    }
}

// MARK: - Security Actions Section

private struct SecurityActionsSection: View {

    let viewModel: MyAccountViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        if isCompact {
            VStack(spacing: 10) {
                pinButton
                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.5))
                    .frame(height: 1)
                    .padding(.horizontal, -AppMetrics.spacing24)
                passwordButton
            }
        } else {
            HStack(spacing: AppMetrics.spacing16) {
                pinButton
                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.6))
                    .frame(width: 1, height: 56)
                passwordButton
            }
        }
    }

    private var pinButton: some View {
        SecurityActionButton(
            icon: "lock.circle.fill",
            iconColor: AppColors.brandPrimary,
            title: viewModel.hasPin ? L10n.Account.Security.changePinTitle : L10n.Account.Security.setPinTitle,
            subtitle: viewModel.hasPin ? L10n.Account.Security.changePinSubtitle : L10n.Account.Security.setPinSubtitle,
            action: { viewModel.openSetPin() }
        )
    }

    private var passwordButton: some View {
        SecurityActionButton(
            icon: "key.fill",
            iconColor: AppColors.statusWarning,
            title: L10n.Account.Security.changePassTitle,
            subtitle: L10n.Account.Security.changePassSubtitle,
            action: { viewModel.openChangePassword() }
        )
    }
}

private struct SecurityActionButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppMetrics.spacing12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: isCompact ? 36 : 44, height: isCompact ? 36 : 44)
                    Image(systemName: icon)
                        .font(.system(size: isCompact ? 15 : 19, weight: .medium))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing2) {
                    Text(title)
                        .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.hapticPlain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Danger Zone Section

private struct DangerZoneSection: View {

    let viewModel: MyAccountViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        let hPad: CGFloat = isCompact ? AppMetrics.spacing16 : AppMetrics.spacing24
        let vPad: CGFloat = isCompact ? AppMetrics.spacing14 : AppMetrics.spacing20
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(L10n.Account.Danger.sectionTitle)
                    .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.title3)
                    .foregroundStyle(AppColors.statusCritical)
                Text(L10n.Account.Danger.sectionSubtitle)
                    .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, hPad)
            .padding(.top, vPad)
            .padding(.bottom, isCompact ? AppMetrics.spacing12 : AppMetrics.spacing16)

            Rectangle()
                .fill(AppColors.statusCritical.opacity(0.2))
                .frame(height: 1)

            HStack(spacing: AppMetrics.spacing12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(AppColors.statusCritical.opacity(0.1))
                        .frame(width: isCompact ? 36 : 44, height: isCompact ? 36 : 44)
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: isCompact ? 15 : 18, weight: .medium))
                        .foregroundStyle(AppColors.statusCritical)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing2) {
                    Text(L10n.Account.Danger.deactivateTitle)
                        .font(isCompact ? AppTypography.phoneBodyMedium : AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.statusCritical)
                    Text(L10n.Account.Danger.deactivateSubtitle)
                        .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Button(action: { viewModel.confirmDeactivate() }) {
                    Text(L10n.Account.Danger.deactivateButton)
                        .font(isCompact ? AppTypography.phoneCallout : AppTypography.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, isCompact ? AppMetrics.spacing12 : AppMetrics.spacing20)
                        .padding(.vertical, isCompact ? AppMetrics.spacing8 : AppMetrics.spacing10)
                        .background(AppColors.statusCritical)
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.hapticPlain)
            }
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
        }
        .background(AppColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .strokeBorder(AppColors.statusCritical.opacity(0.25), lineWidth: AppMetrics.borderWidth)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Set PIN Sheet

private struct SetPinSheet: View {

    @Bindable var viewModel: MyAccountViewModel
    @FocusState private var focusedField: PinField?
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    enum PinField { case pin, confirm }

    var body: some View {
        let hPad: CGFloat = isCompact ? AppMetrics.spacing20 : AppMetrics.spacing32
        let iconSize: CGFloat = isCompact ? 44 : 56
        let iconFont: CGFloat = isCompact ? 20 : 26
        return VStack(alignment: .leading, spacing: 0) {

            HStack {
                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(viewModel.hasPin ? L10n.Account.Pin.changeSheetTitle : L10n.Account.Pin.sheetTitle)
                        .font(isCompact ? AppTypography.phoneTitle : AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(viewModel.hasPin ? L10n.Account.Pin.changeSheetSubtitle : L10n.Account.Pin.sheetSubtitle)
                        .font(isCompact ? AppTypography.phoneCallout : AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Button { viewModel.cancelPin() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(AppColors.borderSubtle.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.hapticPlain)
            }
            .padding(.horizontal, hPad)
            .padding(.top, isCompact ? AppMetrics.spacing20 : AppMetrics.spacing28)
            .padding(.bottom, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing20)

            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.6))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: isCompact ? AppMetrics.spacing16 : AppMetrics.spacing20) {

                if !isCompact {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                            .fill(AppColors.brandPrimary.opacity(0.1))
                            .frame(width: iconSize, height: iconSize)
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: iconFont, weight: .medium))
                            .foregroundStyle(AppColors.brandPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppMetrics.spacing4)
                }

                VStack(spacing: AppMetrics.spacing12) {
                    PinInputField(
                        label: L10n.Account.Pin.fieldNew,
                        placeholder: L10n.Account.Pin.fieldNewPH,
                        text: $viewModel.pinInput,
                        focusedField: $focusedField,
                        fieldTag: .pin
                    )
                    PinInputField(
                        label: L10n.Account.Pin.fieldConfirm,
                        placeholder: L10n.Account.Pin.fieldConfirmPH,
                        text: $viewModel.pinConfirm,
                        focusedField: $focusedField,
                        fieldTag: .confirm
                    )

                    if let error = viewModel.pinError {
                        HStack(spacing: AppMetrics.spacing4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                            Text(error)
                                .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                        }
                        .foregroundStyle(AppColors.statusCritical)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.pinError)

                HStack(spacing: AppMetrics.spacing12) {
                    SecondaryButton(title: L10n.Common.cancel) { viewModel.cancelPin() }
                    PrimaryButton(title: viewModel.hasPin ? L10n.Account.Pin.changeSubmitButton : L10n.Account.Pin.submitButton) { viewModel.submitPin() }
                }
            }
            .padding(.horizontal, hPad)
            .padding(.top, isCompact ? AppMetrics.spacing20 : AppMetrics.spacing24)
            .padding(.bottom, isCompact ? AppMetrics.spacing24 : AppMetrics.spacing32)
        }
        .background(AppColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
        .shadow(color: .black.opacity(0.2), radius: 28, x: 0, y: 12)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .strokeBorder(AppColors.borderSubtle.opacity(0.5), lineWidth: AppMetrics.borderWidth)
        )
        .frame(maxWidth: 520)
        .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing32)
        .onAppear { focusedField = .pin }
    }
}

private struct PinInputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focusedField: FocusState<SetPinSheet.PinField?>.Binding
    let fieldTag: SetPinSheet.PinField

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }
    var isFocused: Bool { focusedField.wrappedValue == fieldTag }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(label.uppercased())
                .font(isCompact ? AppTypography.phoneCaption : AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.5)

            SecureField(placeholder, text: $text)
                .font(isCompact ? AppTypography.phoneBody : AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .keyboardType(.numberPad)
                .focused(focusedField, equals: fieldTag)
                .padding(.horizontal, AppMetrics.spacing16)
                .frame(height: isCompact ? 44 : AppMetrics.textFieldHeight)
                .background(AppColors.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(
                            isFocused ? AppColors.borderFocused : AppColors.borderSubtle,
                            lineWidth: isFocused ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                        )
                )
                .onChange(of: text) { _, newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(6))
                    if digits != newValue { text = digits }
                }
        }
    }
}

// MARK: - Change Password Sheet

private struct ChangePasswordSheet: View {

    @Bindable var viewModel: MyAccountViewModel
    @FocusState private var focusedField: PasswordField?
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    enum PasswordField { case current, new, confirm }

    var body: some View {
        let hPad: CGFloat = isCompact ? AppMetrics.spacing20 : AppMetrics.spacing32
        let iconSize: CGFloat = isCompact ? 44 : 56
        let iconFont: CGFloat = isCompact ? 20 : 24
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                        Text(viewModel.passwordStep == .verify
                             ? L10n.Account.Password.verifyTitle
                             : L10n.Account.Password.sheetTitle)
                            .font(isCompact ? AppTypography.phoneTitle : AppTypography.title2)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(viewModel.passwordStep == .verify
                             ? L10n.Account.Password.verifySubtitle
                             : L10n.Account.Password.sheetSubtitle)
                            .font(isCompact ? AppTypography.phoneCallout : AppTypography.callout)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Button { viewModel.cancelPasswordChange() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(AppColors.borderSubtle.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.hapticPlain)
                }
                .padding(.horizontal, hPad)
                .padding(.top, isCompact ? AppMetrics.spacing20 : AppMetrics.spacing28)
                .padding(.bottom, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing20)

                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.6))
                    .frame(height: 1)

                if viewModel.passwordStep == .verify {
                    verifyStep(hPad: hPad, iconSize: iconSize, iconFont: iconFont)
                } else {
                    setNewStep(hPad: hPad, iconSize: iconSize, iconFont: iconFont)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
        .shadow(color: .black.opacity(0.2), radius: 28, x: 0, y: 12)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .strokeBorder(AppColors.borderSubtle.opacity(0.5), lineWidth: AppMetrics.borderWidth)
        )
        .frame(maxWidth: 520)
        .padding(.horizontal, isCompact ? AppMetrics.spacing16 : AppMetrics.spacing32)
        .onAppear { focusedField = .current }
        .onChange(of: viewModel.passwordStep) { _, step in
            focusedField = step == .verify ? .current : .new
        }
    }

    private func verifyStep(hPad: CGFloat, iconSize: CGFloat, iconFont: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? AppMetrics.spacing14 : AppMetrics.spacing20) {
            if !isCompact {
                ZStack {
                    RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                        .fill(AppColors.brandPrimary.opacity(0.1))
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: iconFont, weight: .medium))
                        .foregroundStyle(AppColors.brandPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppMetrics.spacing4)
            }

            // Locked email
            ELockedField(
                label: L10n.Account.Personal.workEmail,
                value: viewModel.email,
                systemImage: "envelope"
            )

            PasswordFieldView(
                label: L10n.Account.Password.fieldCurrent,
                placeholder: L10n.Account.Password.fieldCurrentPH,
                text: $viewModel.verifyPasswordInput,
                focusedField: $focusedField,
                fieldTag: .current
            )

            if let error = viewModel.verifyError {
                HStack(spacing: AppMetrics.spacing4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                }
                .foregroundStyle(AppColors.statusCritical)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: AppMetrics.spacing12) {
                SecondaryButton(title: L10n.Common.cancel) { viewModel.cancelPasswordChange() }
                PrimaryButton(title: L10n.Account.Password.verifyButton) {
                    viewModel.verifyCurrentPassword()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.verifyError)
        .padding(.horizontal, hPad)
        .padding(.top, isCompact ? AppMetrics.spacing20 : AppMetrics.spacing24)
        .padding(.bottom, isCompact ? AppMetrics.spacing24 : AppMetrics.spacing32)
    }

    private func setNewStep(hPad: CGFloat, iconSize: CGFloat, iconFont: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: isCompact ? AppMetrics.spacing14 : AppMetrics.spacing20) {
            if !isCompact {
                ZStack {
                    RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                        .fill(AppColors.statusWarning.opacity(0.1))
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: "key.fill")
                        .font(.system(size: iconFont, weight: .medium))
                        .foregroundStyle(AppColors.statusWarning)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppMetrics.spacing4)
            }

            VStack(spacing: AppMetrics.spacing12) {
                PasswordFieldView(
                    label: L10n.Account.Password.fieldNew,
                    placeholder: L10n.Account.Password.fieldNewPH,
                    text: $viewModel.newPassword,
                    focusedField: $focusedField,
                    fieldTag: .new
                )
                PasswordFieldView(
                    label: L10n.Account.Password.fieldConfirm,
                    placeholder: L10n.Account.Password.fieldConfirmPH,
                    text: $viewModel.confirmPassword,
                    focusedField: $focusedField,
                    fieldTag: .confirm
                )

                if let error = viewModel.passwordError {
                    HStack(spacing: AppMetrics.spacing4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                        Text(error)
                            .font(isCompact ? AppTypography.phoneCaption : AppTypography.caption)
                    }
                    .foregroundStyle(AppColors.statusCritical)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.passwordError)

            HStack(spacing: AppMetrics.spacing12) {
                SecondaryButton(title: L10n.Common.cancel) { viewModel.cancelPasswordChange() }
                    .disabled(viewModel.isChangingPassword)
                PrimaryButton(title: L10n.Account.Password.submitButton, isLoading: viewModel.isChangingPassword) {
                    viewModel.submitPasswordChange()
                }
            }
        }
        .padding(.horizontal, hPad)
        .padding(.top, isCompact ? AppMetrics.spacing20 : AppMetrics.spacing24)
        .padding(.bottom, isCompact ? AppMetrics.spacing24 : AppMetrics.spacing32)
    }
}

private struct PasswordFieldView: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focusedField: FocusState<ChangePasswordSheet.PasswordField?>.Binding
    let fieldTag: ChangePasswordSheet.PasswordField

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }
    var isFocused: Bool { focusedField.wrappedValue == fieldTag }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(label.uppercased())
                .font(isCompact ? AppTypography.phoneCaption : AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.5)

            SecureField(placeholder, text: $text)
                .font(isCompact ? AppTypography.phoneBody : AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .focused(focusedField, equals: fieldTag)
                .padding(.horizontal, AppMetrics.spacing16)
                .frame(height: isCompact ? 44 : AppMetrics.textFieldHeight)
                .background(AppColors.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(
                            isFocused ? AppColors.borderFocused : AppColors.borderSubtle,
                            lineWidth: isFocused ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                        )
                )
        }
    }
}

// MARK: - Locked (read-only) Field

private struct ELockedField: View {
    let label: String
    let value: String
    var systemImage: String? = nil

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(label)
                .font(isCompact ? AppTypography.phoneCaption : AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: AppMetrics.spacing12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: AppMetrics.iconSizeSmall, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: AppMetrics.iconSizeMedium)
                }
                Text(value.isEmpty ? "—" : value)
                    .font(isCompact ? AppTypography.phoneBody : AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: AppMetrics.iconSizeSmall, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .frame(height: isCompact ? 44 : AppMetrics.textFieldHeight)
            .background(AppColors.surfaceCard.opacity(0.6))
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
        }
    }
}
