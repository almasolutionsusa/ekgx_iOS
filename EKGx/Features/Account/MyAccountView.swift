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
//  │   Work Email  /  Phone                                               │
//  │                                                                      │
//  │   Address  ────────────────────────────────────────────────────      │
//  │   Address Line 1 / 2 / City / State / Zip / Country                 │
//  │                                                                      │
//  │   Facility & Role  ────────────────────────────────────────────      │
//  │   Current Facility (Menu) / Department / Role                        │
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
                            title: L10n.Account.Address.sectionTitle,
                            subtitle: L10n.Account.Address.sectionSubtitle
                        ) {
                            AddressSection(viewModel: viewModel)
                        }

                        AccountFormCard(
                            title: L10n.Account.Facility.sectionTitle,
                            subtitle: L10n.Account.Facility.sectionSubtitle
                        ) {
                            FacilityRoleSection(viewModel: viewModel)
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
        }
        .sheet(isPresented: $viewModel.showSetPinSheet) {
            SetPinSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showChangePasswordSheet) {
            ChangePasswordSheet(viewModel: viewModel)
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

    var body: some View {
        HStack(alignment: .center, spacing: AppMetrics.spacing16) {
            Button(action: { viewModel.navigateBack() }) {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text(L10n.Home.Nav.menuButton) // "Dashboard" back label reuses common back concept
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
                Text(viewModel.currentFacility.rawValue)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                Text(viewModel.role)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.brandPrimary)

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
            HStack(spacing: AppMetrics.spacing16) {
                ETextField(
                    label: L10n.Account.Personal.workEmail,
                    placeholder: L10n.Account.Personal.workEmailPH,
                    systemImage: "envelope",
                    text: $viewModel.workEmail,
                    errorMessage: viewModel.emailError,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                ETextField(
                    label: L10n.Account.Personal.phone,
                    placeholder: L10n.Account.Personal.phonePH,
                    systemImage: "phone",
                    text: $viewModel.phone,
                    errorMessage: viewModel.phoneError,
                    keyboardType: .phonePad,
                    textContentType: .telephoneNumber
                )
            }
        }
    }
}

// MARK: - Address Section

private struct AddressSection: View {

    @Bindable var viewModel: MyAccountViewModel

    var body: some View {
        VStack(spacing: AppMetrics.spacing16) {
            ETextField(
                label: L10n.Account.Address.line1,
                placeholder: L10n.Account.Address.line1PH,
                systemImage: "mappin",
                text: $viewModel.addressLine1,
                autocapitalization: .sentences
            )
            ETextField(
                label: L10n.Account.Address.line2,
                placeholder: L10n.Account.Address.line2PH,
                systemImage: "mappin.and.ellipse",
                text: $viewModel.addressLine2,
                autocapitalization: .sentences
            )
            HStack(spacing: AppMetrics.spacing16) {
                ETextField(
                    label: L10n.Account.Address.city,
                    placeholder: L10n.Account.Address.cityPH,
                    systemImage: "building.2",
                    text: $viewModel.city,
                    autocapitalization: .words
                )
                ETextField(
                    label: L10n.Account.Address.state,
                    placeholder: L10n.Account.Address.statePH,
                    systemImage: "map",
                    text: $viewModel.state,
                    autocapitalization: .characters
                )
                .frame(maxWidth: 160)
                ETextField(
                    label: L10n.Account.Address.zip,
                    placeholder: L10n.Account.Address.zipPH,
                    systemImage: "number",
                    text: $viewModel.zipCode,
                    keyboardType: .numbersAndPunctuation
                )
                .frame(maxWidth: 200)
            }
            ETextField(
                label: L10n.Account.Address.country,
                placeholder: L10n.Account.Address.countryPH,
                systemImage: "globe",
                text: $viewModel.country,
                autocapitalization: .words
            )
        }
    }
}

// MARK: - Facility & Role Section

private struct FacilityRoleSection: View {

    @Bindable var viewModel: MyAccountViewModel

    var body: some View {
        VStack(spacing: AppMetrics.spacing16) {

            VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                Text(L10n.Account.Facility.currentFacility.uppercased())
                    .font(AppTypography.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
                    .tracking(0.5)

                Menu {
                    ForEach(MyAccountViewModel.Facility.allCases) { facility in
                        Button {
                            viewModel.currentFacility = facility
                        } label: {
                            HStack {
                                Text(facility.rawValue)
                                if viewModel.currentFacility == facility {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "building.2.crop.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: AppMetrics.iconSizeMedium)

                        Text(viewModel.currentFacility.rawValue)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .padding(.horizontal, AppMetrics.spacing16)
                    .frame(height: AppMetrics.textFieldHeight)
                    .background(AppColors.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                            .strokeBorder(AppColors.borderSubtle, lineWidth: AppMetrics.borderWidth)
                    )
                }
            }

            HStack(spacing: AppMetrics.spacing16) {
                ETextField(
                    label: L10n.Account.Facility.department,
                    placeholder: L10n.Account.Facility.departmentPH,
                    systemImage: "staroflife",
                    text: $viewModel.department,
                    autocapitalization: .words
                )
                ETextField(
                    label: L10n.Account.Facility.role,
                    placeholder: L10n.Account.Facility.rolePH,
                    systemImage: "person.badge.clock",
                    text: $viewModel.role,
                    autocapitalization: .words
                )
            }
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
                title: L10n.Account.Security.setPinTitle,
                subtitle: L10n.Account.Security.setPinSubtitle,
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
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                        Text(L10n.Account.Pin.sheetTitle)
                            .font(AppTypography.title2)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(L10n.Account.Pin.sheetSubtitle)
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
                .padding(.horizontal, AppMetrics.spacing40)
                .padding(.top, AppMetrics.spacing32)
                .padding(.bottom, AppMetrics.spacing24)

                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.6))
                    .frame(height: 1)
                    .padding(.horizontal, AppMetrics.spacing40)

                VStack(alignment: .leading, spacing: AppMetrics.spacing20) {

                    ZStack {
                        RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                            .fill(AppColors.brandPrimary.opacity(0.1))
                            .frame(width: 64, height: 64)
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(AppColors.brandPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppMetrics.spacing8)

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
                        PrimaryButton(title: L10n.Account.Pin.submitButton, isLoading: viewModel.isSubmittingPin) { viewModel.submitPin() }
                    }
                }
                .padding(.horizontal, AppMetrics.spacing40)
                .padding(.top, AppMetrics.spacing28)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)

                Spacer()
            }
        }
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
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing4) {
                        Text(L10n.Account.Password.sheetTitle)
                            .font(AppTypography.title2)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(L10n.Account.Password.sheetSubtitle)
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
                .padding(.horizontal, AppMetrics.spacing40)
                .padding(.top, AppMetrics.spacing32)
                .padding(.bottom, AppMetrics.spacing24)

                Rectangle()
                    .fill(AppColors.borderSubtle.opacity(0.6))
                    .frame(height: 1)
                    .padding(.horizontal, AppMetrics.spacing40)

                VStack(alignment: .leading, spacing: AppMetrics.spacing20) {

                    ZStack {
                        RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                            .fill(AppColors.statusWarning.opacity(0.1))
                            .frame(width: 64, height: 64)
                        Image(systemName: "key.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppColors.statusWarning)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppMetrics.spacing8)

                    VStack(spacing: AppMetrics.spacing12) {
                        PasswordFieldView(
                            label: L10n.Account.Password.fieldCurrent,
                            placeholder: L10n.Account.Password.fieldCurrentPH,
                            text: $viewModel.currentPassword,
                            focusedField: $focusedField,
                            fieldTag: .current
                        )
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
                        PrimaryButton(title: L10n.Account.Password.submitButton, isLoading: false) { viewModel.submitPasswordChange() }
                    }
                }
                .padding(.horizontal, AppMetrics.spacing40)
                .padding(.top, AppMetrics.spacing28)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)

                Spacer()
            }
        }
        .onAppear { focusedField = .current }
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
