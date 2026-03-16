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
                LoginBrandingPanel()
                    .frame(width: geometry.size.width * AppMetrics.sidebarWidthRatio)

                LoginFormPanel(viewModel: viewModel)
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
        .sheet(isPresented: $viewModel.showPinLogin) {
            PinLoginSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Branding Panel (Left)

private struct LoginBrandingPanel: View {

    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppColors.surfaceSidebar,
                    Color(red: 0.04, green: 0.18, blue: 0.35)
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
                    ZStack {
                        RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                            .fill(AppColors.brandPrimary)
                            .frame(width: 72, height: 72)

                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                        Text(L10n.Branding.appName)
                            .font(AppTypography.largeTitle)
                            .foregroundStyle(AppColors.textOnDark)

                        Text(L10n.Branding.tagline)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textOnDark.opacity(0.7))
                            .lineLimit(2)
                    }
                }

                Spacer()

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
                    let glowColor = Color(red: 0.25, green: 0.65, blue: 1.0)
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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: AppMetrics.spacing64)

                    // Header
                    VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                        Text(L10n.Auth.Login.title)
                            .font(AppTypography.title1)
                            .foregroundStyle(AppColors.textPrimary)

                        Text(L10n.Auth.Login.subtitle)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer(minLength: AppMetrics.spacing40)

                    // Error banner
                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error) {
                            withAnimation { viewModel.errorMessage = nil }
                        }
                        .padding(.bottom, AppMetrics.spacing24)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut(duration: 0.25), value: viewModel.errorMessage)
                    }

                    // Form fields
                    VStack(spacing: AppMetrics.spacing20) {
                        ETextField(
                            label: L10n.Auth.Login.emailLabel,
                            placeholder: L10n.Auth.Login.emailPlaceholder,
                            systemImage: "envelope",
                            text: $viewModel.email,
                            errorMessage: viewModel.emailError,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )
                        .focused($focusedField, equals: .email)
                        .onChange(of: viewModel.email) { _, _ in
                            viewModel.clearFieldError(for: .email)
                        }
                        .onSubmit { focusedField = .password }

                        ESecureField(
                            label: L10n.Auth.Login.passwordLabel,
                            placeholder: L10n.Auth.Login.passwordPlaceholder,
                            text: $viewModel.password,
                            errorMessage: viewModel.passwordError
                        )
                        .focused($focusedField, equals: .password)
                        .onChange(of: viewModel.password) { _, _ in
                            viewModel.clearFieldError(for: .password)
                        }
                        .onSubmit { focusedField = nil; viewModel.login() }
                    }

                    // Forgot password
                    HStack {
                        Spacer()
                        Button(L10n.Auth.Login.forgotPassword) {
                            // TODO: navigate to password reset
                        }
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.brandPrimary)
                    }
                    .padding(.top, AppMetrics.spacing12)
                    .padding(.bottom, AppMetrics.spacing32)

                    // Primary action
                    PrimaryButton(
                        title: L10n.Auth.Login.loginButton,
                        isLoading: viewModel.isLoading
                    ) {
                        focusedField = nil
                        viewModel.login()
                    }

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(AppColors.borderSubtle)
                            .frame(height: 1)
                        Text("or")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.horizontal, AppMetrics.spacing12)
                        Rectangle()
                            .fill(AppColors.borderSubtle)
                            .frame(height: 1)
                    }
                    .padding(.vertical, AppMetrics.spacing24)

                    // PIN Login
                    SecondaryButton(title: L10n.Auth.Login.pinButton) {
                        focusedField = nil
                        viewModel.enterWithPin()
                    }

                    Spacer(minLength: AppMetrics.spacing16)

                    // Register
                    SecondaryButton(title: L10n.Auth.Login.registerButton) {
                        viewModel.navigateToRegister()
                    }

                    // Sign-in link hint
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
                    .padding(.top, AppMetrics.spacing16)

                    Spacer(minLength: AppMetrics.spacing64)
                }
                .padding(.horizontal, AppMetrics.spacing48)
                .frame(maxWidth: AppMetrics.formMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .background(AppColors.surfaceBackground)
            .scrollDismissesKeyboard(.interactively)

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
}

// MARK: - PIN Login Sheet

private struct PinLoginSheet: View {

    @Bindable var viewModel: LoginViewModel
    @FocusState private var pinFocused: Bool

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
                    .fill(AppColors.brandPrimary.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColors.brandPrimary)
            }
            .padding(.bottom, AppMetrics.spacing20)

            // Title & subtitle
            VStack(spacing: AppMetrics.spacing8) {
                Text(L10n.Auth.Login.pinTitle)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)

                Text(L10n.Auth.Login.pinSubtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppMetrics.spacing32)
            }
            .padding(.bottom, AppMetrics.spacing40)

            // PIN dot indicators
            HStack(spacing: AppMetrics.spacing20) {
                ForEach(0..<4, id: \.self) { index in
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

            // Hidden secure input field
            SecureField(L10n.Auth.Login.pinPlaceholder, text: $viewModel.pinInput)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($pinFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: viewModel.pinInput) { _, newValue in
                    // Clamp to 4 digits only
                    let digits = newValue.filter(\.isNumber)
                    if digits.count > 4 {
                        viewModel.pinInput = String(digits.prefix(4))
                    } else if digits != newValue {
                        viewModel.pinInput = digits
                    }
                    viewModel.pinError = nil
                    if viewModel.pinInput.count == 4 {
                        viewModel.submitPinLogin()
                    }
                }

            // Tap area to open keyboard
            Button {
                pinFocused = true
            } label: {
                Text(viewModel.pinInput.isEmpty ? L10n.Auth.Login.pinPlaceholder : "")
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(height: 44)
            }
            .padding(.bottom, AppMetrics.spacing8)

            // Error
            if let error = viewModel.pinError {
                Text(error)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.statusCritical)
                    .padding(.bottom, AppMetrics.spacing16)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.pinError)
            } else {
                Spacer(minLength: AppMetrics.spacing32)
            }

            // Back to email
            Button(L10n.Auth.Login.pinBackToEmail) {
                viewModel.cancelPinLogin()
            }
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.brandPrimary)
            .padding(.bottom, AppMetrics.spacing48)
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.surfaceBackground)
        .onAppear { pinFocused = true }
    }
}

// MARK: - Preview

#Preview {
    let router = AppRouter()
    let viewModel = LoginViewModel(authService: MockAuthService(), router: router)
    LoginView(viewModel: viewModel)
}
