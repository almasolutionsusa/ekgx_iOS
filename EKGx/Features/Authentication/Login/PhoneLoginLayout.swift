//
//  PhoneLoginLayout.swift
//  EKGx
//
//  Single-column login screen for iPhone (horizontalSizeClass == .compact).
//

import SwiftUI

// MARK: - Phone Login Layout

struct PhoneLoginLayout: View {

    @Bindable var viewModel: LoginViewModel
    @FocusState private var focusedField: LoginViewModel.Field?
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var isEmailMode: Bool

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        let anyPinSet = LocalUserRegistry.shared.all.contains { $0.hasPin }
        _isEmailMode = State(initialValue: !anyPinSet)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                phoneHeader
                formScroll
            }
            .ignoresSafeArea(.container, edges: .top)
            darkModeToggle
            if viewModel.isLoading {
                LoadingOverlay()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            }
        }
    }

    private var darkModeToggle: some View {
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
        .padding(.trailing, AppMetrics.spacing16)
    }

    // MARK: - Form Scroll (header is fixed above, only form scrolls)

    private var formScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                formContent
                    .background(AppColors.surfaceBackground)
                    .padding(.bottom, 35)
            }
            .background(AppColors.surfaceBackground)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: focusedField) { _, newValue in
                guard let field = newValue else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(field, anchor: nil)
                    }
                }
            }
        }
    }

    // MARK: - Hero Header

    private var phoneHeader: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.surfaceSidebar, AppColors.surfaceBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            ECGGridOverlay(animated: false)
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: AppMetrics.spacing8) {
                    AppImages.logo
                        .resizable()
                        .scaledToFit()
                        .frame(height: 55)
                        .onTapGesture(count: 2) {
                            viewModel.uuidSendSuccess = nil
                            viewModel.showUUIDAlert = true
                        }
                    Text(L10n.Branding.tagline)
                        .font(AppTypography.phoneFootnote)
                        .foregroundStyle(AppColors.textOnDark.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                Spacer()
                if viewModel.organizationName != nil || viewModel.facilityName != nil {
                    FacilityBadge(
                        organizationName: viewModel.organizationName,
                        facilityName: viewModel.facilityName
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.4), value: viewModel.facilityName)
                    .padding(.bottom, AppMetrics.spacing20)
                }
            }
        }
        .frame(height: 220)
    }

    // MARK: - Form + Footer

    private var formContent: some View {
        VStack(spacing: 0) {
            if isEmailMode {
                PhoneEmailSection(viewModel: viewModel, focusedField: $focusedField)
            } else {
                PhonePinSection(viewModel: viewModel)
            }
            phoneFooter
        }
    }

    // MARK: - Footer

    private var phoneFooter: some View {
        VStack(spacing: AppMetrics.spacing12) {
            SecondaryButton(
                title: isEmailMode ? L10n.Auth.Login.pinButton : L10n.Auth.Login.pinBackToEmail
            ) {
                focusedField = nil
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isEmailMode { viewModel.cancelPinLogin() }
                    isEmailMode.toggle()
                }
            }
            .padding(.horizontal, AppMetrics.spacing24)

            Button { viewModel.startEmergency() } label: {
                VStack(alignment: .center, spacing: 2) {
                    HStack {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(L10n.Emergency.buttonTitle)
                            .font(AppTypography.phoneBodyMedium)
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.Emergency.buttonSubtitle)
                        .font(AppTypography.phoneCaption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, AppMetrics.spacing16)
                .frame(minHeight: AppMetrics.buttonHeight + 6)
                .background(AppColors.statusCritical.opacity(0.07))
                .cornerRadius(AppMetrics.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .strokeBorder(AppColors.statusCritical.opacity(0.25), lineWidth: 3)
                )
            }
            .buttonStyle(.hapticPlain)
            .padding(.horizontal, AppMetrics.spacing24)
            .padding(.top)
            
            HStack {
                Spacer()
                Text(L10n.Auth.Login.noAccount)
                    .font(AppTypography.phoneFootnote)
                    .foregroundStyle(AppColors.textSecondary)
                Button(L10n.Auth.Login.registerButton) {
                    viewModel.navigateToRegister()
                }
                .buttonStyle(.hapticPlain)
                .font(AppTypography.phoneFootnote)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.brandPrimary)
                Spacer()
            }
            .padding(.bottom, AppMetrics.spacing8)
        }
    }
}

