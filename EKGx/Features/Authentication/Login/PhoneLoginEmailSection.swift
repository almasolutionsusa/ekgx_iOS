//
//  PhoneLoginEmailSection.swift
//  EKGx
//

import SwiftUI

struct PhoneEmailSection: View {

    @Bindable var viewModel: LoginViewModel
    var focusedField: FocusState<LoginViewModel.Field?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader
            fieldsStack
            forgotPasswordRow
            errorBanner
            loginButton
        }
        .padding(.horizontal, AppMetrics.spacing24)
    }

    // MARK: - Sub-views

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: AppMetrics.spacing6) {
            Text(L10n.Auth.Login.title)
                .font(AppTypography.phoneTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(L10n.Auth.Login.subtitle)
                .font(AppTypography.phoneFootnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, AppMetrics.spacing28)
        .padding(.bottom, AppMetrics.spacing20)
    }

    private var fieldsStack: some View {
        VStack(spacing: AppMetrics.spacing16) {
            ZStack(alignment: .topLeading) {
                ETextField(
                    placeholder: L10n.Auth.Login.emailPlaceholder,
                    systemImage: "person",
                    text: $viewModel.email,
                    errorMessage: viewModel.emailError,
                    keyboardType: .default,
                    textContentType: .username
                )
                .focused(focusedField, equals: .email)
                .id(LoginViewModel.Field.email)
                .onChange(of: viewModel.email) { _, _ in
                    viewModel.clearFieldError(for: .email)
                    viewModel.updateSuggestions()
                }
                .onSubmit {
                    focusedField.wrappedValue = .password
                    viewModel.dismissSuggestions()
                }

                if viewModel.showSuggestions {
                    suggestionsDropdown
                }
            }

            ESecureField(
                placeholder: L10n.Auth.Login.passwordPlaceholder,
                text: $viewModel.password,
                errorMessage: viewModel.passwordError
            )
            .focused(focusedField, equals: .password)
            .id(LoginViewModel.Field.password)
            .onChange(of: viewModel.password) { _, _ in
                viewModel.clearFieldError(for: .password)
                viewModel.dismissSuggestions()
            }
            .onSubmit { focusedField.wrappedValue = nil; viewModel.login() }
        }
    }

    private var forgotPasswordRow: some View {
        HStack {
            Spacer()
            Button(L10n.Auth.Login.forgotPassword) {
                focusedField.wrappedValue = nil
                viewModel.openForgotPassword()
            }
            .buttonStyle(.hapticPlain)
            .font(AppTypography.phoneSubheadline)
            .foregroundStyle(AppColors.accentTeal)
        }
        .padding(.top, AppMetrics.spacing12)
        .padding(.bottom, AppMetrics.spacing20)
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(AppTypography.phoneCaption)
                .foregroundStyle(AppColors.statusCritical)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, AppMetrics.spacing8)
                .padding(.horizontal, AppMetrics.spacing12)
                .background(AppColors.statusCritical.opacity(0.08))
                .cornerRadius(AppMetrics.radiusSmall)
                .padding(.bottom, AppMetrics.spacing12)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
        }
    }

    private var loginButton: some View {
        PrimaryButton(
            title: L10n.Auth.Login.loginButton,
            isLoading: viewModel.isLoading
        ) {
            focusedField.wrappedValue = nil
            viewModel.login()
        }
        .padding(.vertical, AppMetrics.spacing20)
        .padding(.top)
    }

    private var suggestionsDropdown: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                Button {
                    viewModel.selectSuggestion(suggestion)
                    focusedField.wrappedValue = .password
                } label: {
                    HStack(spacing: AppMetrics.spacing12) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textSecondary)
                        Text(suggestion)
                            .font(AppTypography.phoneCallout)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, AppMetrics.spacing16)
                    .padding(.vertical, AppMetrics.spacing10)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.hapticPlain)
                if suggestion != viewModel.suggestions.last {
                    Divider().padding(.horizontal, AppMetrics.spacing16)
                }
            }
        }
        .background(AppColors.surfaceCard)
        .cornerRadius(AppMetrics.radiusMedium)
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                .strokeBorder(AppColors.borderSubtle, lineWidth: AppMetrics.borderWidth)
        )
        .offset(y: AppMetrics.textFieldHeight + AppMetrics.spacing4)
        .zIndex(10)
    }
}
