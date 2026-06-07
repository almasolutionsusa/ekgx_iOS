//
//  LoginView.swift
//  EKGx
//
//  Split-panel iPad login screen.
//  Left panel: branding & illustration.
//  Right panel: login form.
//

import SwiftUI

// MARK: - Root

struct LoginView: View {

    @State private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                LoginBrandingPanel(
                    organizationName: viewModel.organizationName,
                    facilityName: viewModel.facilityName,
                    onLogoDoubleTap: {
                        viewModel.uuidSendSuccess = nil
                        viewModel.showUUIDAlert = true
                    }
                )
                .frame(width: geometry.size.width * AppMetrics.sidebarWidthRatio)

                LoginFormPanel(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
        .background(AppColors.surfaceBackground)
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .task {
            for _ in 0..<20 {
                viewModel.refreshFacilityInfo()
                if viewModel.facilityName != nil { break }
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
            }
        }
        .sheet(isPresented: $viewModel.showForgotPassword) {
            ForgotPasswordSheet(viewModel: viewModel)
        }
        .alert("App UUID", isPresented: $viewModel.showUUIDAlert) {
            Button(viewModel.isSendingUUID ? "Sending…" : "Send by Email") {
                viewModel.sendUUIDByEmail()
            }
            .disabled(viewModel.isSendingUUID)
            Button("Close", role: .cancel) { }
        } message: {
            if let success = viewModel.uuidSendSuccess {
                Text(success
                     ? "Sent successfully."
                     : "Failed to send. Please try again.\n\n\(viewModel.appUUID)")
            } else {
                Text(viewModel.appUUID)
            }
        }
    }
}

// MARK: - Branding Panel (Left)

private struct LoginBrandingPanel: View {

    let organizationName: String?
    let facilityName: String?
    var onLogoDoubleTap: (() -> Void)? = nil

    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppColors.surfaceSidebar,
                    AppColors.surfaceBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative ECG grid lines with travelling shimmer
            ECGGridOverlay()

            // Content
            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Logo area
                VStack(alignment: .leading, spacing: AppMetrics.spacing20) {
                    // App icon placeholder
                    VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                        AppImages.logo
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .onTapGesture(count: 2) { onLogoDoubleTap?() }

                        Text(L10n.Branding.tagline)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textOnDark.opacity(0.7))
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Facility / org badge — always reserves its height so the logo above never jumps
                ZStack(alignment: .bottomLeading) {
                    Color.clear.frame(height: 64)   // constant placeholder — both spacers stay stable
                    if organizationName != nil || facilityName != nil {
                        FacilityBadge(
                            organizationName: organizationName,
                            facilityName: facilityName
                        )
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.4), value: facilityName)
                    }
                }
                .padding(.bottom, AppMetrics.spacing20)

                // Animated ECG pulse indicator
                HStack(spacing: AppMetrics.spacing8) {
                    Circle()
                        .fill(AppColors.ecgWaveform)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseAnimation ? 1.4 : 1.0)
                        .opacity(pulseAnimation ? 0.6 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )

                    Text(L10n.Branding.poweredBy)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textOnDark.opacity(0.5))
                }
                .padding(.bottom, AppMetrics.spacing48)
            }
            .padding(.horizontal, AppMetrics.spacing40)
        }
        .onAppear { pulseAnimation = true }
    }
}

// MARK: - Facility Badge

private struct FacilityBadge: View {

    let organizationName: String?
    let facilityName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let org = organizationName {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary.opacity(0.8))
                    Text(org)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textOnDark.opacity(0.55))
                        .lineLimit(1)
                }
                .padding(.bottom, AppMetrics.spacing6)
            }

            if let facility = facilityName {
                HStack(spacing: AppMetrics.spacing8) {
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.ecgWaveform.opacity(0.9))
                    Text(facility)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textOnDark.opacity(0.9))
                        .lineLimit(1)
                }
            }
        }
    }
}

// MARK: - ECG Grid Overlay (decorative + shimmer)

private struct ECGGridOverlay: View {

    @State private var startDate: Date? = nil

    private let delay:      Double = 0.75
    private let sweepIn:    Double = 0.35
    // sweep-out starts when sweep-in hits 80% (no hold pause)
    private let sweepOut:   Double = 0.35

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                // elapsed since onAppear, minus initial delay
                let elapsed: Double = {
                    guard let start = startDate else { return -1 }
                    return timeline.date.timeIntervalSince(start) - delay
                }()

                // For each grid line (diagPos 0→1), compute its glow brightness
                // Phase 1 (sweepIn):  front edge advances 0→1, lines behind it stay ON
                // Phase 2 (hold):     all lines ON
                // Phase 3 (sweepOut): a dark edge advances 0→1, lines behind it turn OFF
                let glowFront: CGFloat = {
                    guard elapsed > 0 else { return -1 }           // delay: nothing lit
                    let p = elapsed / sweepIn
                    return p < 1.0 ? CGFloat(p) : 1.0             // 0→1 then clamp
                }()

                let darkFront: CGFloat = {
                    // Start sweep-out when sweep-in reaches 80% (sweepIn * 0.8)
                    let outStart = sweepIn * 0.8
                    guard elapsed > outStart else { return -1 }
                    let p = (elapsed - outStart) / sweepOut
                    return p < 1.0 ? CGFloat(p) : 1.0
                }()

                Canvas { context, size in
                    let spacing:   CGFloat = 28
                    let glowColor = AppColors.accentCyan
                    let baseColor = Color.white

                    let edgeSoftness: CGFloat = 0.12  // fade zone width (0=hard, higher=softer)

                    func brightness(for diagPos: CGFloat) -> CGFloat {
                        guard glowFront >= 0 else { return 0 }

                        // Fade in at the leading edge of the sweep-in front
                        let inFade  = min(1.0, max(0.0, (glowFront - diagPos) / edgeSoftness))

                        // Fade out at the leading edge of the sweep-out front
                        let outFade: CGFloat = darkFront >= 0
                            ? min(1.0, max(0.0, (diagPos - darkFront) / edgeSoftness))
                            : 1.0

                        return inFade * outFade
                    }

                    var x: CGFloat = 0
                    while x <= size.width {
                        let b = brightness(for: x / size.width)
                        let color = b > 0 ? glowColor.opacity(0.08 + 0.55 * b) : baseColor.opacity(0.05)
                        context.stroke(
                            Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height)) },
                            with: .color(color), lineWidth: b > 0 ? 1.5 : 1
                        )
                        x += spacing
                    }

                    var y: CGFloat = 0
                    while y <= size.height {
                        let b = brightness(for: y / size.height)
                        let color = b > 0 ? glowColor.opacity(0.08 + 0.55 * b) : baseColor.opacity(0.05)
                        context.stroke(
                            Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y)) },
                            with: .color(color), lineWidth: b > 0 ? 1.5 : 1
                        )
                        y += spacing
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear { startDate = Date() }
    }
}

// MARK: - Form Panel (Right)

private struct LoginFormPanel: View {

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
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: AppMetrics.spacing48)

                        if isEmailMode {
                            emailSection(proxy: proxy)
                        } else {
                            pinSection
                        }

                        Spacer(minLength: AppMetrics.spacing20)

                        SecondaryButton(
                            title: isEmailMode ? L10n.Auth.Login.pinButton : L10n.Auth.Login.pinBackToEmail
                        ) {
                            focusedField = nil
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isEmailMode { viewModel.cancelPinLogin() }
                                isEmailMode.toggle()
                            }
                        }
                        .padding(.bottom, AppMetrics.spacing12)

                        // EKG Emergency
                        Button { viewModel.startEmergency() } label: {
                            HStack(spacing: AppMetrics.spacing10) {
                                Image(systemName: "cross.case.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("EKG Emergency")
                                    .font(AppTypography.bodyMedium)
                            }
                            .foregroundStyle(AppColors.statusCritical)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppMetrics.buttonHeight)
                            .background(AppColors.statusCritical.opacity(0.07))
                            .cornerRadius(AppMetrics.radiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                                    .strokeBorder(AppColors.statusCritical.opacity(0.25), lineWidth: AppMetrics.borderWidth)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, AppMetrics.spacing24)

                        HStack {
                            Spacer()
                            Text(L10n.Auth.Login.noAccount)
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColors.textSecondary)
                            Button(L10n.Auth.Login.registerButton) {
                                viewModel.navigateToRegister()
                            }
                            .font(AppTypography.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.brandPrimary)
                            Spacer()
                        }

                        Spacer(minLength: AppMetrics.spacing48)
                    }
                    .padding(.horizontal, AppMetrics.spacing48)
                    .frame(maxWidth: AppMetrics.formMaxWidth)
                    .frame(maxWidth: .infinity)
                }
                .background(AppColors.surfaceBackground)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focusedField) { _, newValue in
                    guard let field = newValue else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(field, anchor: .top)
                        }
                    }
                }
            }

            // Dark mode toggle
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { isDarkMode.toggle() }
            } label: {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(AppColors.surfaceCard)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .padding(.top, AppMetrics.spacing20)
            .padding(.trailing, AppMetrics.spacing24)
        }
    }

    // MARK: - PIN Section

    private var pinSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppMetrics.spacing8) {
                Text(L10n.Auth.Login.pinTitle)
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Auth.Login.pinSubtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, AppMetrics.spacing28)

            HStack(spacing: AppMetrics.spacing20) {
                ForEach(0..<6, id: \.self) { index in
                    ZStack {
                        Circle()
                            .stroke(
                                index < viewModel.pinInput.count
                                    ? AppColors.brandPrimary
                                    : AppColors.borderSubtle,
                                lineWidth: 2
                            )
                            .frame(width: 20, height: 20)
                        if index < viewModel.pinInput.count {
                            Circle()
                                .fill(AppColors.brandPrimary)
                                .frame(width: 12, height: 12)
                        }
                    }
                    .animation(.easeInOut(duration: 0.15), value: viewModel.pinInput.count)
                }
            }
            .padding(.bottom, AppMetrics.spacing12)

            Group {
                if let error = viewModel.pinError {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.statusCritical)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.pinError)
                } else if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                } else {
                    Color.clear
                }
            }
            .frame(height: 20)
            .padding(.bottom, AppMetrics.spacing16)

            PinNumericKeypad(
                onDigit:  { viewModel.keypadInput($0) },
                onDelete: { viewModel.keypadDelete() }
            )
            .disabled(viewModel.isLoading)
            .padding(.bottom, AppMetrics.spacing20)
        }
    }

    // MARK: - Email Section

    @ViewBuilder
    private func emailSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                Text(L10n.Auth.Login.title)
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Auth.Login.subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.bottom, AppMetrics.spacing32)

            // Error banner
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    withAnimation { viewModel.errorMessage = nil }
                }
                .padding(.bottom, AppMetrics.spacing24)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
            }

            // Fields
            VStack(spacing: AppMetrics.spacing20) {
                ZStack(alignment: .topLeading) {
                    ETextField(
                        label: L10n.Auth.Login.emailLabel,
                        placeholder: L10n.Auth.Login.emailPlaceholder,
                        systemImage: "person",
                        text: $viewModel.email,
                        errorMessage: viewModel.emailError,
                        keyboardType: .default,
                        textContentType: .username
                    )
                    .focused($focusedField, equals: .email)
                    .id(LoginViewModel.Field.email)
                    .onChange(of: viewModel.email) { _, _ in
                        viewModel.clearFieldError(for: .email)
                        viewModel.updateSuggestions()
                    }
                    .onSubmit { focusedField = .password; viewModel.dismissSuggestions() }

                    if viewModel.showSuggestions {
                        VStack(spacing: 0) {
                            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                                Button {
                                    viewModel.selectSuggestion(suggestion)
                                    focusedField = .password
                                } label: {
                                    HStack(spacing: AppMetrics.spacing12) {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 14))
                                            .foregroundStyle(AppColors.textSecondary)
                                        Text(suggestion)
                                            .font(AppTypography.callout)
                                            .foregroundStyle(AppColors.textPrimary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, AppMetrics.spacing16)
                                    .padding(.vertical, AppMetrics.spacing12)
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
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

                ESecureField(
                    label: L10n.Auth.Login.passwordLabel,
                    placeholder: L10n.Auth.Login.passwordPlaceholder,
                    text: $viewModel.password,
                    errorMessage: viewModel.passwordError
                )
                .focused($focusedField, equals: .password)
                .id(LoginViewModel.Field.password)
                .onChange(of: viewModel.password) { _, _ in
                    viewModel.clearFieldError(for: .password)
                    viewModel.dismissSuggestions()
                }
                .onSubmit { focusedField = nil; viewModel.login() }
            }

            // Forgot password
            HStack {
                Spacer()
                Button(L10n.Auth.Login.forgotPassword) {
                    focusedField = nil
                    viewModel.openForgotPassword()
                }
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.brandPrimary)
            }
            .padding(.top, AppMetrics.spacing12)
            .padding(.bottom, AppMetrics.spacing28)

            // Login button
            PrimaryButton(
                title: L10n.Auth.Login.loginButton,
                isLoading: viewModel.isLoading
            ) {
                focusedField = nil
                viewModel.login()
            }
            .padding(.bottom, AppMetrics.spacing20)
        }
    }
}

// MARK: - Numeric Keypad

struct PinNumericKeypad: View {

    let onDigit:  (String) -> Void
    let onDelete: () -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["",  "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(maxWidth: .infinity).frame(height: 72)
                        } else if key == "⌫" {
                            keyButton(key: key, isDelete: true)
                        } else {
                            keyButton(key: key, isDelete: false)
                        }
                    }
                }
            }
        }
    }

    private func keyButton(key: String, isDelete: Bool) -> some View {
        Button {
            if isDelete { onDelete() } else { onDigit(key) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isDelete
                          ? AppColors.brandPrimary.opacity(0.08)
                          : AppColors.surfaceCard)
                    .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 2)

                if isDelete {
                    Image(systemName: "delete.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(AppColors.brandPrimary)
                } else {
                    Text(key)
                        .font(.custom("Roboto-Medium", size: 28))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

// MARK: - Forgot Password Sheet

private struct ForgotPasswordSheet: View {

    @Bindable var viewModel: LoginViewModel
    @FocusState private var emailFocused: Bool

    var body: some View {
        VStack(spacing: 0) {

            // Handle
            Capsule()
                .fill(AppColors.borderSubtle)
                .frame(width: 40, height: 4)
                .padding(.top, AppMetrics.spacing16)
                .padding(.bottom, AppMetrics.spacing32)

            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.10))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.rotation")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColors.brandPrimary)
            }
            .padding(.bottom, AppMetrics.spacing20)

            // Title & subtitle
            VStack(spacing: AppMetrics.spacing8) {
                Text(L10n.Auth.Login.forgotPasswordTitle)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text(L10n.Auth.Login.forgotPasswordSubtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppMetrics.spacing32)
            }
            .padding(.bottom, AppMetrics.spacing32)

            // Success state
            if let success = viewModel.forgotSuccessMessage {
                HStack(spacing: AppMetrics.spacing12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.statusSuccess)
                        .font(.system(size: 22))
                    Text(success)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.statusSuccess)
                }
                .padding(AppMetrics.spacing16)
                .background(AppColors.statusSuccess.opacity(0.08))
                .cornerRadius(AppMetrics.radiusMedium)
                .padding(.horizontal, AppMetrics.spacing32)
                .padding(.bottom, AppMetrics.spacing24)

                Button(L10n.Common.dismiss) {
                    viewModel.cancelForgotPassword()
                }
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.brandPrimary)

            } else {
                // Email field
                VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                    Text(L10n.Auth.Login.forgotPasswordEmailLabel)
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.textSecondary)

                    TextField(L10n.Auth.Login.emailPlaceholder, text: $viewModel.forgotEmail)
                        .font(AppTypography.body)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($emailFocused)
                        .padding(.horizontal, AppMetrics.spacing16)
                        .frame(height: AppMetrics.textFieldHeight)
                        .background(AppColors.surfaceCard)
                        .cornerRadius(AppMetrics.radiusMedium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                                .strokeBorder(
                                    viewModel.forgotEmailError != nil ? AppColors.statusCritical :
                                    emailFocused ? AppColors.borderFocused : AppColors.borderSubtle,
                                    lineWidth: emailFocused ? AppMetrics.borderWidthFocused : AppMetrics.borderWidth
                                )
                        )

                    if let error = viewModel.forgotEmailError {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.statusCritical)
                    }
                }
                .padding(.horizontal, AppMetrics.spacing32)

                // Error banner
                if let error = viewModel.forgotErrorMessage {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.statusCritical)
                        .padding(.top, AppMetrics.spacing8)
                        .padding(.horizontal, AppMetrics.spacing32)
                }

                // Send button
                PrimaryButton(
                    title: L10n.Auth.Login.forgotPasswordSend,
                    isLoading: viewModel.forgotIsLoading
                ) {
                    emailFocused = false
                    viewModel.submitForgotPassword()
                }
                .padding(.horizontal, AppMetrics.spacing32)
                .padding(.top, AppMetrics.spacing24)

                // Cancel
                Button(L10n.Common.cancel) {
                    viewModel.cancelForgotPassword()
                }
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, AppMetrics.spacing16)
            }

            Spacer(minLength: AppMetrics.spacing48)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.surfaceBackground)
        .onAppear { emailFocused = true }
    }
}

// MARK: - Preview

#Preview {
    let diContainer = AppDIContainer()
    let router      = AppRouter()
    LoginView(viewModel: diContainer.makeLoginViewModel(router: router))
}
