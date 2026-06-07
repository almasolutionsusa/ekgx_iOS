//
//  RegisterView.swift
//  EKGx
//
//  Registration form — split-panel layout.
//  Left: branding. Right: scrollable form or post-registration success screen.
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

                if viewModel.registrationSucceeded {
                    RegisterSuccessPanel(email: viewModel.email, onBackToLogin: { viewModel.navigateToLogin() })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                } else {
                    RegisterFormPanel(viewModel: viewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .background(AppColors.surfaceBackground)
        .animation(.easeInOut(duration: 0.35), value: viewModel.registrationSucceeded)
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
                colors: [AppColors.surfaceSidebar, AppColors.surfaceBackground],
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

// MARK: - Success Panel

private struct RegisterSuccessPanel: View {

    let email: String
    let onBackToLogin: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppMetrics.spacing24) {
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.12))
                        .frame(width: 96, height: 96)
                    Image(systemName: "envelope.badge.checkmark.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary)
                }

                VStack(spacing: AppMetrics.spacing10) {
                    Text(L10n.Auth.Register.successTitle)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L10n.Auth.Register.successMessage(email))
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                PrimaryButton(title: L10n.Auth.Register.successBackToLogin) {
                    onBackToLogin()
                }
                .frame(maxWidth: 320)
            }
            .padding(.horizontal, AppMetrics.spacing48)

            Spacer()
        }
        .frame(maxWidth: AppMetrics.registerFormMaxWidth)
        .frame(maxWidth: .infinity)
        .background(AppColors.surfaceBackground)
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

                VStack(spacing: AppMetrics.spacing14) {

                    // First + Last name
                    HStack(spacing: AppMetrics.spacing14) {
                        ETextField(
                            label: L10n.Auth.Register.firstNameLabel,
                            placeholder: L10n.Auth.Register.firstNamePlaceholder,
                            systemImage: "person",
                            text: $viewModel.firstName,
                            errorMessage: viewModel.firstNameError,
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
                            autocapitalization: .words
                        )
                        .focused($focus, equals: .lastName)
                        .id(RegisterViewModel.Field.lastName)
                        .onChange(of: viewModel.lastName) { _, _ in viewModel.clearFieldError(for: .lastName) }
                        .onSubmit { focus = .email }
                    }

                    // Email
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

                    // Confirm Email
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

                    // Password
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

                    // Confirm Password
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

                // Extra scroll runway so bottom fields clear the keyboard
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(field, anchor: .top)
                }
            }
        }
        } // ScrollViewReader
    }
}

// MARK: - Preview

#Preview {
    let diContainer = AppDIContainer()
    let router      = AppRouter()
    RegisterView(viewModel: diContainer.makeRegisterViewModel(router: router))
}
