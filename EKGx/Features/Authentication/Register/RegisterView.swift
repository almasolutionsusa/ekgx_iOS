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
        .onAppear { viewModel.activate() }
    }
}

// MARK: - Resolved Facility Field (read-only, fetched from server)

private struct ResolvedFacilityField: View {

    @Bindable var viewModel: RegisterViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
            Text(L10n.Auth.Register.facilityLabel)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: AppMetrics.spacing12) {
                Image(systemName: "building.2")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(viewModel.facilityNotAssigned
                                     ? AppColors.statusCritical
                                     : AppColors.brandPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.isLoadingFacility {
                        Text(L10n.Auth.Register.facilityLoading)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                    } else if viewModel.facilityNotAssigned {
                        Text(L10n.Auth.Register.facilityNotAssigned)
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.statusCritical)
                    } else if !viewModel.facilityName.isEmpty {
                        Text(viewModel.facilityName)
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        if !viewModel.organizationName.isEmpty {
                            Text(viewModel.organizationName)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    } else {
                        Text(L10n.Auth.Register.facilityPlaceholder)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                Spacer()

                if viewModel.isLoadingFacility {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                } else if !viewModel.facilityNotAssigned && !viewModel.facilityName.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.statusSuccess)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, AppMetrics.spacing16)
            .frame(height: AppMetrics.textFieldHeight)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                    .strokeBorder(
                        viewModel.facilityNotAssigned
                            ? AppColors.statusCritical
                            : AppColors.borderSubtle,
                        lineWidth: AppMetrics.borderWidth
                    )
            )
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
        ScrollViewReader { proxy in
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
                        .id(RegisterViewModel.Field.firstName)
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
                        .id(RegisterViewModel.Field.lastName)
                        .onChange(of: viewModel.lastName) { _, _ in viewModel.clearFieldError(for: .lastName) }
                        .onSubmit { focus = .phone }
                    }

                }

                Spacer(minLength: AppMetrics.spacing24)

                // ── Section 2: Professional Details
                FormSectionHeader(title: L10n.Auth.Register.sectionProfessional)

                VStack(spacing: AppMetrics.spacing14) {
                    ResolvedFacilityField(viewModel: viewModel)

                    DropdownPicker(
                        label: L10n.Auth.Register.titleLabel,
                        placeholder: L10n.Auth.Register.titlePlaceholder,
                        systemImage: "person.text.rectangle",
                        selection: $viewModel.title,
                        options: viewModel.titles,
                        displayText: { $0 },
                        errorMessage: viewModel.titleError
                    )
                    .id(RegisterViewModel.Field.title)
                    .onChange(of: viewModel.title) { _, _ in viewModel.clearFieldError(for: .title) }

                    DropdownPicker(
                        label: L10n.Auth.Register.degreeLabel,
                        placeholder: L10n.Auth.Register.degreePlaceholder,
                        systemImage: "graduationcap",
                        selection: $viewModel.degree,
                        options: viewModel.degrees,
                        displayText: { $0 },
                        errorMessage: viewModel.degreeError
                    )
                    .id(RegisterViewModel.Field.degree)
                    .onChange(of: viewModel.degree) { _, _ in viewModel.clearFieldError(for: .degree) }

                    OptionalTextField(
                        label: L10n.Auth.Register.phoneLabel,
                        placeholder: L10n.Auth.Register.phonePlaceholder,
                        systemImage: "phone",
                        text: $viewModel.phone,
                        keyboardType: .phonePad
                    )
                    .focused($focus, equals: .phone)
                    .id(RegisterViewModel.Field.phone)
                    .onSubmit { focus = .npi }

                    OptionalTextField(
                        label: L10n.Auth.Register.npiLabel,
                        placeholder: L10n.Auth.Register.npiPlaceholder,
                        systemImage: "number",
                        text: $viewModel.npi,
                        keyboardType: .numberPad
                    )
                    .focused($focus, equals: .npi)
                    .id(RegisterViewModel.Field.npi)
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
                    .id(RegisterViewModel.Field.email)
                    .onChange(of: viewModel.email) { _, _ in viewModel.clearFieldError(for: .email) }
                    .onSubmit { focus = .confirmEmail }

                    ETextField(
                        label: L10n.Auth.Register.confirmEmailLabel,
                        placeholder: L10n.Auth.Register.confirmEmailPlaceholder,
                        systemImage: "checkmark.seal",
                        text: $viewModel.confirmEmail,
                        errorMessage: viewModel.confirmEmailError,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )
                    .focused($focus, equals: .confirmEmail)
                    .id(RegisterViewModel.Field.confirmEmail)
                    .onChange(of: viewModel.confirmEmail) { _, _ in viewModel.clearFieldError(for: .confirmEmail) }
                    .onSubmit { focus = .password }

                    ESecureField(
                        label: L10n.Auth.Register.passwordLabel,
                        placeholder: L10n.Auth.Register.passwordPlaceholder,
                        text: $viewModel.password,
                        errorMessage: viewModel.passwordError
                    )
                    .focused($focus, equals: .password)
                    .id(RegisterViewModel.Field.password)
                    .onChange(of: viewModel.password) { _, _ in viewModel.clearFieldError(for: .password) }
                    .onSubmit { focus = .confirmPassword }

                    ESecureField(
                        label: L10n.Auth.Register.confirmPasswordLabel,
                        placeholder: L10n.Auth.Register.confirmPasswordPlaceholder,
                        text: $viewModel.confirmPassword,
                        errorMessage: viewModel.confirmPasswordError
                    )
                    .focused($focus, equals: .confirmPassword)
                    .id(RegisterViewModel.Field.confirmPassword)
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

                // Extra scroll runway so bottom fields can scroll above the keyboard
                Spacer(minLength: 400)
            }
            .padding(.horizontal, AppMetrics.spacing40)
            .frame(maxWidth: AppMetrics.registerFormMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.surfaceBackground)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: focus) { _, newValue in
            guard let field = newValue else { return }
            // Small delay so the keyboard has started appearing before we scroll
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(field, anchor: .top)
                }
            }
        }
        } // ScrollViewReader
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
    let diContainer = AppDIContainer()
    let router      = AppRouter()
    RegisterView(viewModel: diContainer.makeRegisterViewModel(router: router))
}
