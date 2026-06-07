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

    init(viewModel: MyAccountViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AccountNavBar(viewModel: viewModel)

                ScrollView {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing32) {

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
                    .padding(.horizontal, AppMetrics.spacing48)
                    .padding(.vertical, AppMetrics.spacing32)
                    .frame(maxWidth: 860)
                    .frame(maxWidth: .infinity)
                }
            }

            // PIN overlay
            if viewModel.showSetPinSheet {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                SetPinSheet(viewModel: viewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            // Change Password overlay — ZStack so it survives background transitions
            if viewModel.showChangePasswordSheet {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                ChangePasswordSheet(viewModel: viewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.showSetPinSheet)
        .animation(.easeInOut(duration: 0.22), value: viewModel.showChangePasswordSheet)
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

    var body: some View {
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
}

// MARK: - Reusable Card Wrapper

private struct AccountFormCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title    = title
        self.subtitle = subtitle
        self.content  = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(title)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppMetrics.spacing24)
            .padding(.top, AppMetrics.spacing20)
            .padding(.bottom, AppMetrics.spacing16)

            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.6))
                .frame(height: 1)

            content
                .padding(.horizontal, AppMetrics.spacing24)
                .padding(.vertical, AppMetrics.spacing20)
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

    var body: some View {
        HStack(spacing: AppMetrics.spacing24) {
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
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(AppColors.borderSubtle, lineWidth: AppMetrics.borderWidth))

                Button(action: { viewModel.requestProfileImageChange() }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.brandPrimary)
                            .frame(width: 30, height: 30)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: 4)
            }

            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text("\(viewModel.firstName) \(viewModel.lastName)")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.facilityName)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)

                Button(L10n.Account.Profile.changePhoto) {
                    viewModel.requestProfileImageChange()
                }
                .font(AppTypography.captionBold)
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

    var body: some View {
        VStack(spacing: AppMetrics.spacing16) {
            HStack(spacing: AppMetrics.spacing16) {
                ETextField(
                    label: L10n.Account.Personal.firstName,
                    placeholder: L10n.Account.Personal.firstNamePH,
                    systemImage: "person",
                    text: $viewModel.firstName,
                    errorMessage: viewModel.firstNameError,
                    autocapitalization: .words
                )
                ETextField(
                    label: L10n.Account.Personal.lastName,
                    placeholder: L10n.Account.Personal.lastNamePH,
                    systemImage: "person",
                    text: $viewModel.lastName,
                    errorMessage: viewModel.lastNameError,
                    autocapitalization: .words
                )
            }
            ELockedField(
                label: L10n.Account.Personal.workEmail,
                value: viewModel.email,
                systemImage: "envelope"
            )
        }
    }
}

// MARK: - Security Actions Section

private struct SecurityActionsSection: View {

    let viewModel: MyAccountViewModel

    var body: some View {
        HStack(spacing: AppMetrics.spacing16) {
            SecurityActionButton(
                icon: "lock.circle.fill",
                iconColor: AppColors.brandPrimary,
                title: (viewModel.hasPin) ? L10n.Account.Security.changePinTitle : L10n.Account.Security.setPinTitle,
                subtitle: (viewModel.hasPin) ? L10n.Account.Security.changePinSubtitle : L10n.Account.Security.setPinSubtitle,
                action: { viewModel.openSetPin() }
            )

            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.6))
                .frame(width: 1, height: 56)

            SecurityActionButton(
                icon: "key.fill",
                iconColor: AppColors.statusWarning,
                title: L10n.Account.Security.changePassTitle,
                subtitle: L10n.Account.Security.changePassSubtitle,
                action: { viewModel.openChangePassword() }
            )
        }
    }
}

private struct SecurityActionButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppMetrics.spacing14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 19, weight: .medium))
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

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Danger Zone Section

private struct DangerZoneSection: View {

    let viewModel: MyAccountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                Text(L10n.Account.Danger.sectionTitle)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.statusCritical)
                Text(L10n.Account.Danger.sectionSubtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppMetrics.spacing24)
            .padding(.top, AppMetrics.spacing20)
            .padding(.bottom, AppMetrics.spacing16)

            Rectangle()
                .fill(AppColors.statusCritical.opacity(0.2))
                .frame(height: 1)

            HStack(spacing: AppMetrics.spacing16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.statusCritical.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.statusCritical)
                }

                VStack(alignment: .leading, spacing: AppMetrics.spacing2) {
                    Text(L10n.Account.Danger.deactivateTitle)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.statusCritical)
                    Text(L10n.Account.Danger.deactivateSubtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Button(action: { viewModel.confirmDeactivate() }) {
                    Text(L10n.Account.Danger.deactivateButton)
                        .font(AppTypography.callout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppMetrics.spacing20)
                        .padding(.vertical, AppMetrics.spacing10)
                        .background(AppColors.statusCritical)
                        .cornerRadius(AppMetrics.radiusMedium)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppMetrics.spacing24)
            .padding(.vertical, AppMetrics.spacing20)
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

    enum PinField { case pin, confirm }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                    Text(viewModel.hasPin ? L10n.Account.Pin.changeSheetTitle : L10n.Account.Pin.sheetTitle)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(viewModel.hasPin ? L10n.Account.Pin.changeSheetSubtitle : L10n.Account.Pin.sheetSubtitle)
                        .font(AppTypography.callout)
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
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppMetrics.spacing32)
            .padding(.top, AppMetrics.spacing28)
            .padding(.bottom, AppMetrics.spacing20)

            Rectangle()
                .fill(AppColors.borderSubtle.opacity(0.6))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: AppMetrics.spacing20) {

                ZStack {
                    RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                        .fill(AppColors.brandPrimary.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(AppColors.brandPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppMetrics.spacing4)

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
                                .font(AppTypography.caption)
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
            .padding(.horizontal, AppMetrics.spacing32)
            .padding(.top, AppMetrics.spacing24)
            .padding(.bottom, AppMetrics.spacing32)
        }
        .background(AppColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusLarge))
        .shadow(color: .black.opacity(0.2), radius: 28, x: 0, y: 12)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                .strokeBorder(AppColors.borderSubtle.opacity(0.5), lineWidth: AppMetrics.borderWidth)
        )
        .frame(maxWidth: 520)
        .padding(.horizontal, AppMetrics.spacing32)
        .onAppear { focusedField = .pin }
    }
}

private struct PinInputField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focusedField: FocusState<SetPinSheet.PinField?>.Binding
    let fieldTag: SetPinSheet.PinField

    var isFocused: Bool { focusedField.wrappedValue == fieldTag }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(label.uppercased())
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.5)

            SecureField(placeholder, text: $text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .keyboardType(.numberPad)
                .focused(focusedField, equals: fieldTag)
                .padding(.horizontal, AppMetrics.spacing16)
                .frame(height: AppMetrics.textFieldHeight)
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

// MARK: - Change Password Sheet

private struct ChangePasswordSheet: View {

    @Bindable var viewModel: MyAccountViewModel
    @FocusState private var focusedField: PasswordField?

    enum PasswordField { case current, new, confirm }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                        Text(viewModel.passwordStep == .verify
                             ? L10n.Account.Password.verifyTitle
                             : L10n.Account.Password.sheetTitle)
                            .font(AppTypography.title2)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(viewModel.passwordStep == .verify
                             ? L10n.Account.Password.verifySubtitle
                             : L10n.Account.Password.sheetSubtitle)
                            .font(AppTypography.callout)
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
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppMetrics.spacing32)
                .padding(.top, AppMetrics.spacing28)
                .padding(.bottom, AppMetrics.spacing20)

                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.6))
                    .frame(height: 1)

                if viewModel.passwordStep == .verify {
                    verifyStep
                } else {
                    setNewStep
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
        .padding(.horizontal, AppMetrics.spacing32)
        .onAppear { focusedField = .current }
        .onChange(of: viewModel.passwordStep) { _, step in
            focusedField = step == .verify ? .current : .new
        }
    }

    private var verifyStep: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing20) {
            ZStack {
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .fill(AppColors.brandPrimary.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppColors.brandPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppMetrics.spacing4)

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
                        .font(AppTypography.caption)
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
        .padding(.horizontal, AppMetrics.spacing32)
        .padding(.top, AppMetrics.spacing24)
        .padding(.bottom, AppMetrics.spacing32)
    }

    private var setNewStep: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing20) {
            ZStack {
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .fill(AppColors.statusWarning.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "key.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppColors.statusWarning)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppMetrics.spacing4)

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
                            .font(AppTypography.caption)
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
        .padding(.horizontal, AppMetrics.spacing32)
        .padding(.top, AppMetrics.spacing24)
        .padding(.bottom, AppMetrics.spacing32)
    }
}

private struct PasswordFieldView: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var focusedField: FocusState<ChangePasswordSheet.PasswordField?>.Binding
    let fieldTag: ChangePasswordSheet.PasswordField

    var isFocused: Bool { focusedField.wrappedValue == fieldTag }

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(label.uppercased())
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .tracking(0.5)

            SecureField(placeholder, text: $text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .focused(focusedField, equals: fieldTag)
                .padding(.horizontal, AppMetrics.spacing16)
                .frame(height: AppMetrics.textFieldHeight)
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

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(label)
                .font(AppTypography.captionBold)
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
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: AppMetrics.iconSizeSmall, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .frame(height: AppMetrics.textFieldHeight)
            .background(AppColors.surfaceCard.opacity(0.6))
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
        }
    }
}
