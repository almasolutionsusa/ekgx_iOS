//
//  PhoneRegisterLayout.swift
//  EKGx
//
//  Single-column registration screen for iPhone (horizontalSizeClass == .compact).
//

import SwiftUI

struct PhoneRegisterLayout: View {

    @Bindable var viewModel: RegisterViewModel
    @FocusState private var focus: RegisterViewModel.Field?
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        ZStack(alignment: .top) {
            if viewModel.registrationSucceeded {
                phoneSuccessView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                VStack(spacing: 0) {
                    phoneHeader
                    formScroll
                }
                .ignoresSafeArea(.container, edges: .top)
                .transition(.opacity)
            }

            if !viewModel.registrationSucceeded {
                topOverlay
            }

            if viewModel.isLoading {
                LoadingOverlay()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.registrationSucceeded)
    }

    // MARK: - Top Overlay

    private var topOverlay: some View {
        HStack {
            Button { viewModel.navigateToLogin() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text(L10n.Auth.Register.signInLink)
                        .font(AppTypography.phoneCallout)
                }
                .foregroundStyle(AppColors.textOnDark.opacity(0.85))
                .padding(.horizontal, AppMetrics.spacing12)
                .frame(height: 32)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
            }
            .buttonStyle(.hapticPlain)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.3)) { isDarkMode.toggle() }
            } label: {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.textOnDark.opacity(0.8))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.hapticPlain)
        }
        .padding(.horizontal, AppMetrics.spacing16)
    }

    // MARK: - Form Scroll (header is fixed above, only form scrolls)

    private var formScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                phoneFormContent
                    .background(AppColors.surfaceBackground)
                    .padding(.bottom, 35)
            }
            .background(AppColors.surfaceBackground)
            .scrollDismissesKeyboard(.interactively)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { focus = .firstName }
            }
            .onChange(of: focus) { _, newValue in
                guard let field = newValue else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(field, anchor: nil)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var phoneHeader: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.surfaceSidebar, AppColors.surfaceBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            ECGGridOverlay(animated: false)
            VStack(spacing: AppMetrics.spacing8) {
                Spacer()
                Spacer(minLength: 20)
                AppImages.logo
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)
                Text(L10n.Auth.Register.title)
                    .font(AppTypography.phoneTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
            }
        }
        .frame(height: 170)
    }

    // MARK: - Form Content

    private var phoneFormContent: some View {
        VStack(alignment: .leading, spacing: 0) {

//            Text(L10n.Auth.Register.subtitle)
//                .font(AppTypography.phoneFootnote)
//                .foregroundStyle(AppColors.textSecondary)
//                .frame(maxWidth: .infinity, alignment: .center)
//                .padding(.top, AppMetrics.spacing16)
//                .padding(.bottom, AppMetrics.spacing20)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTypography.phoneCaption)
                    .foregroundStyle(AppColors.statusCritical)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppMetrics.spacing8)
                    .padding(.horizontal, AppMetrics.spacing12)
                    .background(AppColors.statusCritical.opacity(0.08))
                    .cornerRadius(AppMetrics.radiusSmall)
                    .padding(.bottom, AppMetrics.spacing16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
            }

            sectionLabel(L10n.Auth.Register.sectionPersonal)

            VStack(spacing: AppMetrics.spacing14) {
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

            sectionLabel(L10n.Auth.Register.sectionCredentials)

            VStack(spacing: AppMetrics.spacing14) {
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

                ESecureField(
                    placeholder: L10n.Auth.Register.passwordPlaceholder,
                    text: $viewModel.password,
                    errorMessage: viewModel.passwordError
                )
                .focused($focus, equals: .password)
                .id(RegisterViewModel.Field.password)
                .onChange(of: viewModel.password) { _, _ in viewModel.clearFieldError(for: .password) }
                .onSubmit { focus = .confirmPassword }

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

            PrimaryButton(
                title: L10n.Auth.Register.registerButton,
                isLoading: viewModel.isLoading
            ) {
                focus = nil
                viewModel.register()
            }
            .padding(.top, AppMetrics.spacing28)

            (
                Text(L10n.Auth.Register.termsPrefix)
                + Text(L10n.Auth.Register.termsLink).bold()
                + Text(L10n.Auth.Register.termsSeparator)
                + Text(L10n.Auth.Register.privacyLink).bold()
            )
            .font(AppTypography.phoneCaption)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, AppMetrics.spacing12)

            HStack {
                Spacer()
                Text(L10n.Auth.Register.haveAccount)
                    .font(AppTypography.phoneFootnote)
                    .foregroundStyle(AppColors.textSecondary)
                Button(L10n.Auth.Register.signInLink) {
                    viewModel.navigateToLogin()
                }
                .buttonStyle(.hapticPlain)
                .font(AppTypography.phoneFootnote)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.brandPrimary)
                Spacer()
            }
            .padding(.top, AppMetrics.spacing16)
            .padding(.bottom, AppMetrics.spacing8)

            Spacer(minLength: 120)
        }
        .padding(.horizontal, AppMetrics.spacing24)
    }

    // MARK: - Success

    private var phoneSuccessView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: AppMetrics.spacing24) {
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.12))
                        .frame(width: 90, height: 90)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary)
                }

                VStack(spacing: AppMetrics.spacing10) {
                    Text(L10n.Auth.Register.successTitle)
                        .font(AppTypography.phoneTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L10n.Auth.Register.successMessage(viewModel.email))
                        .font(AppTypography.phoneCallout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                PrimaryButton(title: L10n.Auth.Register.successBackToLogin) {
                    viewModel.navigateToLogin()
                }

                (
                    Text("Didn't receive an email within 5 minutes? Contact us at ")
                        .foregroundStyle(AppColors.textSecondary)
                    + Text("support@ekgx.com")
                        .foregroundStyle(AppColors.brandPrimary)
                )
                .font(AppTypography.phoneCaption)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            }
            .padding(.horizontal, AppMetrics.spacing24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surfaceBackground)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppTypography.phoneCaption)
            .foregroundStyle(AppColors.textSecondary)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppMetrics.spacing20)
            .padding(.bottom, AppMetrics.spacing10)
    }
}
