//
//  LockOverlayView.swift
//  EKGx
//
//  Popup overlay shown on top of the active screen when the session is
//  auto-locked. Fully blocks interaction with the underlying view.
//
//  PIN mode  (loginMethod == "PIN"):
//    Shows PIN dots. Only the currently logged-in user's PIN is accepted.
//    Any other PIN → "Incorrect PIN" error even if valid for another user.
//
//  Email mode (loginMethod != "PIN"):
//    No PIN entry — user must log out and re-authenticate.
//

import SwiftUI

// MARK: - LockOverlayView

struct LockOverlayView: View {

    let diContainer: AppDIContainer
    let router: AppRouter

    @State private var pinInput: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSubmitting: Bool = false

    private var loginMethod: String? {
        diContainer.authService.loginData?.loginMethod
    }

    private var isPinUser: Bool {
        loginMethod?.uppercased() == "PIN"
    }

    private var lockedUserId: Int64? {
        diContainer.authService.loginData?.user.id
    }

    var body: some View {
        ZStack {
            // Full-screen blur — fully obscures underlying patient data.
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Card
            VStack(spacing: AppMetrics.spacing20) {

                // Icon + title
                VStack(spacing: AppMetrics.spacing12) {
                    ZStack {
                        Circle()
                            .fill(AppColors.brandPrimary.opacity(0.12))
                            .frame(width: 64, height: 64)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(AppColors.brandPrimary)
                    }

                    Text(L10n.AutoLock.title)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(isPinUser ? L10n.AutoLock.subtitle : L10n.AutoLock.subtitleEmailUser)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if isPinUser {
                    // PIN dots
                    HStack(spacing: AppMetrics.spacing20) {
                        ForEach(0..<6, id: \.self) { index in
                            ZStack {
                                Circle()
                                    .stroke(
                                        index < pinInput.count
                                            ? AppColors.brandPrimary
                                            : AppColors.borderSubtle,
                                        lineWidth: 2
                                    )
                                    .frame(width: 22, height: 22)
                                if index < pinInput.count {
                                    Circle()
                                        .fill(AppColors.brandPrimary)
                                        .frame(width: 14, height: 14)
                                }
                            }
                            .animation(.easeInOut(duration: 0.15), value: pinInput.count)
                        }
                    }
                    .padding(.top, AppMetrics.spacing4)

                    // Error / loading
                    Group {
                        if let error = errorMessage {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.statusCritical)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: errorMessage)
                        } else if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                        } else {
                            Color.clear.frame(height: 16)
                        }
                    }
                    .frame(height: 20)

                    // Numeric keypad
                    PinNumericKeypad(
                        onDigit:  { keypadInput($0) },
                        onDelete: { keypadDelete() }
                    )
                    .disabled(isSubmitting)
                }

                // Logout button
                Button(action: logoutAndReturnToLogin) {
                    Text(L10n.AutoLock.logoutButton)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.brandPrimary)
                }
                .buttonStyle(.plain)
                .padding(.top, AppMetrics.spacing4)
            }
            .padding(.horizontal, AppMetrics.spacing24)
            .padding(.vertical, AppMetrics.spacing28)
            .frame(maxWidth: 420)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .shadow(color: .black.opacity(0.3), radius: 28, x: 0, y: 12)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(AppColors.borderSubtle.opacity(0.6), lineWidth: AppMetrics.borderWidth)
            )
            .padding(.horizontal, AppMetrics.spacing32)
        }
    }

    // MARK: - Keypad Actions

    private func keypadInput(_ digit: String) {
        guard pinInput.count < 6 else { return }
        pinInput += digit
        errorMessage = nil
        if pinInput.count == 6 {
            Task { await submit() }
        }
    }

    private func keypadDelete() {
        guard !pinInput.isEmpty else { return }
        pinInput.removeLast()
        errorMessage = nil
    }

    // MARK: - Actions

    private func submit() async {
        guard pinInput.count == 6 else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let expectedUserId = lockedUserId
        let appUuid = diContainer.checkinService.appUuid

        do {
            try await diContainer.authService.pinLogin(pin: pinInput, appUuid: appUuid)

            // Verify the PIN belongs to the currently locked user
            let returnedUserId = diContainer.authService.loginData?.user.id
            guard returnedUserId == expectedUserId else {
                // Wrong user's PIN — re-authenticate as the original user is no longer possible,
                // so reject and force logout.
                errorMessage = L10n.AutoLock.errorWrongUser
                pinInput = ""
                try? await diContainer.authService.logout()
                return
            }

            pinInput = ""
            diContainer.autoLockManager.unlock()
        } catch let error as AuthError {
            errorMessage = error.errorDescription
            pinInput = ""
        } catch {
            errorMessage = L10n.Auth.Login.errorGeneric
            pinInput = ""
        }
    }

    private func logoutAndReturnToLogin() {
        Task {
            try? await diContainer.authService.logout()
            diContainer.autoLockManager.stop()
            router.navigate(to: .login)
        }
    }
}
