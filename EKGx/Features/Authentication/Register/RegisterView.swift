//
//  RegisterView.swift
//  EKGx
//
//  Full registration form — split-panel layout.
//  Left: branding. Right: scrollable multi-section form.
//

import SwiftUI

// MARK: - Root

struct RegisterView: View {

    @State private var viewModel: RegisterViewModel

    init(viewModel: RegisterViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                RegisterBrandingPanel(onBack: { viewModel.navigateToLogin() })
                    .frame(width: geometry.size.width * 0.26)

                RegisterFormPanel(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .background(AppColors.surfaceBackground)
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            }
        }
    }
}

// MARK: - Branding Panel

private struct RegisterBrandingPanel: View {

    let onBack: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.surfaceSidebar, Color(red: 0.04, green: 0.18, blue: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: AppMetrics.spacing20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                            .fill(AppColors.brandPrimary)
                            .frame(width: 72, height: 72)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                        Text(L10n.Auth.Register.title)
                            .font(AppTypography.title1)
                            .foregroundStyle(AppColors.textOnDark)
                        Text(L10n.Auth.Register.subtitle)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textOnDark.opacity(0.7))
                    }
                }

                Spacer()

                Button(action: onBack) {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text(L10n.Auth.Register.signInLink)
                            .font(AppTypography.callout)
                    }
                    .foregroundStyle(AppColors.textOnDark.opacity(0.6))
                }
                .padding(.bottom, AppMetrics.spacing48)
            }
            .padding(.horizontal, AppMetrics.spacing40)
        }
    }
}

// MARK: - Form Panel

private struct RegisterFormPanel: View {

    @Bindable var viewModel: RegisterViewModel
    @FocusState private var focus: RegisterViewModel.Field?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                Spacer(minLength: AppMetrics.spacing40)

                // Header
                VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                    Text(L10n.Auth.Register.title)
                        .font(AppTypography.title1)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.Auth.Register.subtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: AppMetrics.spacing24)

                // Error banner
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error) {
                        withAnimation { viewModel.errorMessage = nil }
                    }
                    .padding(.bottom, AppMetrics.spacing20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
                }

                // ── Section 1: Personal Information
                FormSectionHeader(title: L10n.Auth.Register.sectionPersonal)

                VStack(spacing: AppMetrics.spacing14) {
                    HStack(spacing: AppMetrics.spacing14) {
                        ETextField(
                            label: L10n.Auth.Register.firstNameLabel,
                            placeholder: L10n.Auth.Register.firstNamePlaceholder,
                            systemImage: "person",
                            text: $viewModel.firstName,
                            errorMessage: viewModel.firstNameError,
                            textContentType: .givenName,
                            autocapitalization: .words
                        )
                        .focused($focus, equals: .firstName)
                        .onChange(of: viewModel.firstName) { _, _ in viewModel.clearFieldError(for: .firstName) }
                        .onSubmit { focus = .lastName }

                        ETextField(
                            label: L10n.Auth.Register.lastNameLabel,
                            placeholder: L10n.Auth.Register.lastNamePlaceholder,
                            systemImage: nil,
                            text: $viewModel.lastName,
                            errorMessage: viewModel.lastNameError,
                            textContentType: .familyName,
                            autocapitalization: .words
                        )
                        .focused($focus, equals: .lastName)
                        .onChange(of: viewModel.lastName) { _, _ in viewModel.clearFieldError(for: .lastName) }
                        .onSubmit { focus = .title }
                    }

                    HStack(spacing: AppMetrics.spacing14) {
                        OptionalTextField(
                            label: L10n.Auth.Register.titleLabel,
                            placeholder: L10n.Auth.Register.titlePlaceholder,
                            systemImage: "person.text.rectangle",
                            text: $viewModel.title
                        )
                        .focused($focus, equals: .title)
                        .onSubmit { focus = .degree }

                        OptionalTextField(
                            label: L10n.Auth.Register.degreeLabel,
                            placeholder: L10n.Auth.Register.degreePlaceholder,
                            systemImage: "graduationcap",
                            text: $viewModel.degree
                        )
                        .focused($focus, equals: .degree)
                        .onSubmit { focus = .department }
                    }
                }

                Spacer(minLength: AppMetrics.spacing24)

                // ── Section 2: Professional Details
                FormSectionHeader(title: L10n.Auth.Register.sectionProfessional)

                VStack(spacing: AppMetrics.spacing14) {
                    DropdownPicker(
                        label: L10n.Auth.Register.facilityLabel,
                        placeholder: L10n.Auth.Register.facilityPlaceholder,
                        systemImage: "building.2",
                        selection: $viewModel.facility,
                        options: Facility.allCases,
                        displayText: { $0.label },
                        errorMessage: viewModel.facilityError
                    )
                    .onChange(of: viewModel.facility) { _, _ in viewModel.clearFieldError(for: .facility) }

                    DropdownPicker(
                        label: L10n.Auth.Register.roleLabel,
                        placeholder: L10n.Auth.Register.rolePlaceholder,
                        systemImage: "stethoscope",
                        selection: $viewModel.role,
                        options: UserRole.allCases,
                        displayText: { $0.label },
                        errorMessage: viewModel.roleError
                    )
                    .onChange(of: viewModel.role) { _, _ in viewModel.clearFieldError(for: .role) }

                    ETextField(
                        label: L10n.Auth.Register.departmentLabel,
                        placeholder: L10n.Auth.Register.departmentPlaceholder,
                        systemImage: "cross.case",
                        text: $viewModel.department,
                        errorMessage: viewModel.departmentError,
                        autocapitalization: .words
                    )
                    .focused($focus, equals: .department)
                    .onChange(of: viewModel.department) { _, _ in viewModel.clearFieldError(for: .department) }
                    .onSubmit { focus = .npi }

                    OptionalTextField(
                        label: L10n.Auth.Register.npiLabel,
                        placeholder: L10n.Auth.Register.npiPlaceholder,
                        systemImage: "number",
                        text: $viewModel.npi,
                        keyboardType: .numberPad
                    )
                    .focused($focus, equals: .npi)
                    .onSubmit { focus = .email }
                }

                Spacer(minLength: AppMetrics.spacing24)

                // ── Section 3: Account Credentials
                FormSectionHeader(title: L10n.Auth.Register.sectionCredentials)

                VStack(spacing: AppMetrics.spacing14) {
                    ETextField(
                        label: L10n.Auth.Register.emailLabel,
                        placeholder: L10n.Auth.Register.emailPlaceholder,
                        systemImage: "envelope",
                        text: $viewModel.email,
                        errorMessage: viewModel.emailError,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )
                    .focused($focus, equals: .email)
                    .onChange(of: viewModel.email) { _, _ in viewModel.clearFieldError(for: .email) }
                    .onSubmit { focus = .confirmEmail }

                    ETextField(
                        label: L10n.Auth.Register.confirmEmailLabel,
                        placeholder: L10n.Auth.Register.confirmEmailPlaceholder,
                        systemImage: "envelope.badge.checkmark",
                        text: $viewModel.confirmEmail,
                        errorMessage: viewModel.confirmEmailError,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )
                    .focused($focus, equals: .confirmEmail)
                    .onChange(of: viewModel.confirmEmail) { _, _ in viewModel.clearFieldError(for: .confirmEmail) }
                    .onSubmit { focus = .password }

                    ESecureField(
                        label: L10n.Auth.Register.passwordLabel,
                        placeholder: L10n.Auth.Register.passwordPlaceholder,
                        text: $viewModel.password,
                        errorMessage: viewModel.passwordError
                    )
                    .focused($focus, equals: .password)
                    .onChange(of: viewModel.password) { _, _ in viewModel.clearFieldError(for: .password) }
                    .onSubmit { focus = .confirmPassword }

                    ESecureField(
                        label: L10n.Auth.Register.confirmPasswordLabel,
                        placeholder: L10n.Auth.Register.confirmPasswordPlaceholder,
                        text: $viewModel.confirmPassword,
                        errorMessage: viewModel.confirmPasswordError
                    )
                    .focused($focus, equals: .confirmPassword)
                    .onChange(of: viewModel.confirmPassword) { _, _ in viewModel.clearFieldError(for: .confirmPassword) }
                    .onSubmit { focus = nil; viewModel.register() }
                }

                Spacer(minLength: AppMetrics.spacing32)

                // CTA
                PrimaryButton(
                    title: L10n.Auth.Register.registerButton,
                    isLoading: viewModel.isLoading
                ) {
                    focus = nil
                    viewModel.register()
                }

                // Back to login
                HStack {
                    Spacer()
                    Text(L10n.Auth.Register.haveAccount)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                    Button(L10n.Auth.Register.signInLink) {
                        viewModel.navigateToLogin()
                    }
                    .font(AppTypography.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.brandPrimary)
                    Spacer()
                }
                .padding(.top, AppMetrics.spacing20)

                Spacer(minLength: AppMetrics.spacing48)
            }
            .padding(.horizontal, AppMetrics.spacing40)
            .frame(maxWidth: AppMetrics.registerFormMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.surfaceBackground)
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - FormSectionHeader

private struct FormSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(AppTypography.captionBold)
            .foregroundStyle(AppColors.brandPrimary)
            .tracking(1)
            .padding(.bottom, AppMetrics.spacing12)
    }
}

// MARK: - OptionalTextField

/// ETextField variant with an "Optional" badge in the label.
private struct OptionalTextField: View {

    let label: String
    let placeholder: String
    let systemImage: String?
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        ETextField(
            label: label,
            placeholder: placeholder,
            systemImage: systemImage,
            text: $text,
            errorMessage: nil,
            keyboardType: keyboardType
        )
        .overlay(alignment: .topTrailing) {
            Text(L10n.Auth.Register.optionalBadge)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppColors.borderSubtle.opacity(0.5))
                .clipShape(Capsule())
                .offset(y: 2)
        }
    }
}

// MARK: - DropdownPicker

private struct DropdownPicker<T: Hashable>: View {

    let label: String
    let placeholder: String
    let systemImage: String
    @Binding var selection: T?
    let options: [T]
    let displayText: (T) -> String
    var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(label)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(displayText(option)) {
                        selection = option
                    }
                }
            } label: {
                HStack(spacing: AppMetrics.spacing12) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16))
                        .foregroundStyle(selection != nil ? AppColors.brandPrimary : AppColors.textSecondary)
                        .frame(width: 20)

                    Text(selection.map(displayText) ?? placeholder)
                        .font(AppTypography.body)
                        .foregroundStyle(selection != nil ? AppColors.textPrimary : AppColors.textSecondary)

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
                        .strokeBorder(
                            errorMessage != nil ? AppColors.statusCritical : AppColors.borderSubtle,
                            lineWidth: errorMessage != nil ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                        )
                )
            }

            if let error = errorMessage {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.statusCritical)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let router = AppRouter()
    RegisterView(viewModel: RegisterViewModel(authService: MockAuthService(), router: router))
}
