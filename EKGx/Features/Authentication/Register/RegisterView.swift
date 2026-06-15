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
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(viewModel: RegisterViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if sizeClass == .compact {
                PhoneRegisterLayout(viewModel: viewModel)
            } else {
                iPadLayout
            }
        }
        .alert(L10n.Auth.Register.noInternetTitle, isPresented: $viewModel.showNoInternetAlert) {
            Button(L10n.Auth.Register.noInternetOpenWifi) {
                if let url = URL(string: "App-Prefs:WIFI"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(L10n.Common.cancel, role: .cancel) { }
        } message: {
            Text(L10n.Auth.Register.noInternetMessage)
        }
    }

    private var iPadLayout: some View {
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
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.surfaceSidebar, AppColors.surfaceBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 0) {
                Button(action: onBack) {
                    HStack(spacing: AppMetrics.spacing8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text(L10n.Auth.Register.signInLink)
                            .font(AppTypography.callout)
                    }
                    .foregroundStyle(AppColors.textOnDark.opacity(0.6))
                }
                .padding(.top, AppMetrics.spacing48)

                Spacer()

                VStack(alignment: .leading, spacing: AppMetrics.spacing20) {
                    VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                        AppImages.logo
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)

                        Text(L10n.Auth.Register.subtitle)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textOnDark.opacity(0.7))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, AppMetrics.spacing40)
            .padding(.bottom, keyboardHeight)
            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
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
                    Image(systemName: "checkmark.circle.fill")
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

                (Text("Didn't receive an email within 5 minutes? Contact us at ")
                    .foregroundStyle(AppColors.textSecondary)
                 + Text("support@ekgx.com")
                    .foregroundStyle(AppColors.brandPrimary)
                )
                .font(AppTypography.caption)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
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

                Spacer(minLength: AppMetrics.spacing20)

                // Header
                VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
                    Text(L10n.Auth.Register.title)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
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
                            placeholder: L10n.Auth.Register.firstNamePlaceholder,
                            systemImage: "person",
                            text: $viewModel.firstName,
                            errorMessage: viewModel.firstNameError,
                            autocapitalization: .characters
                        )
                        .focused($focus, equals: .firstName)
                        .id(RegisterViewModel.Field.firstName)
                        .onChange(of: viewModel.firstName) { _, _ in viewModel.clearFieldError(for: .firstName) }
                        .onSubmit { focus = .lastName }

                        ETextField(
                            placeholder: L10n.Auth.Register.lastNamePlaceholder,
                            systemImage: nil,
                            text: $viewModel.lastName,
                            errorMessage: viewModel.lastNameError,
                            autocapitalization: .characters
                        )
                        .focused($focus, equals: .lastName)
                        .id(RegisterViewModel.Field.lastName)
                        .onChange(of: viewModel.lastName) { _, _ in viewModel.clearFieldError(for: .lastName) }
                        .onSubmit { focus = .email }
                    }

                    // Email
                    ETextField(
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
                        placeholder: L10n.Auth.Register.confirmPasswordPlaceholder,
                        text: $viewModel.confirmPassword,
                        errorMessage: viewModel.confirmPasswordError
                    )
                    .focused($focus, equals: .confirmPassword)
                    .id(RegisterViewModel.Field.confirmPassword)
                    .onChange(of: viewModel.confirmPassword) { _, _ in viewModel.clearFieldError(for: .confirmPassword) }
                    .onSubmit { focus = nil; viewModel.register() }
                }

                Spacer(minLength: AppMetrics.spacing14)

                // CTA
                PrimaryButton(
                    title: L10n.Auth.Register.registerButton,
                    isLoading: viewModel.isLoading
                ) {
                    focus = nil
                    viewModel.register()
                }

                // Terms notice
                (
                    Text(L10n.Auth.Register.termsPrefix)
                    + Text(L10n.Auth.Register.termsLink).bold()
                    + Text(L10n.Auth.Register.termsSeparator)
                    + Text(L10n.Auth.Register.privacyLink).bold()
                )
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, AppMetrics.spacing8)

                // Extra scroll runway so bottom fields clear the keyboard
                Spacer(minLength: 400)
            }
            .padding(.horizontal, AppMetrics.spacing40)
            .frame(maxWidth: AppMetrics.registerFormMaxWidth)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.surfaceBackground)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { focus = .firstName }
        }
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
