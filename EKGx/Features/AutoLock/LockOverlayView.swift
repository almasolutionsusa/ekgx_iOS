//
//  LockOverlayView.swift
//  EKGx
//
//  Popup overlay shown on top of the active screen when the session is
//  auto-locked. Fully blocks interaction with the underlying view — no taps
//  pass through. User unlocks with their PIN and resumes exactly where they
//  left off.
//

import SwiftUI

// MARK: - LockOverlayView

struct LockOverlayView: View {

    let diContainer: AppDIContainer
    let router: AppRouter

    @State private var pinInput: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSubmitting: Bool = false
    @FocusState private var pinFocused: Bool

    var body: some View {
        ZStack {
            // Blocking backdrop — swallows ALL touches behind the card.
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { pinFocused = true }

            // Card
            VStack(spacing: AppMetrics.spacing24) {

                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.brandPrimary.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary)
                }

                // Title + subtitle
                VStack(spacing: AppMetrics.spacing8) {
                    Text(L10n.AutoLock.title)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(L10n.AutoLock.subtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

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

                // Hidden input
                SecureField("", text: $pinInput)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($pinFocused)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onChange(of: pinInput) { _, newValue in
                        let digits = newValue.filter(\.isNumber)
                        if digits.count > 6 {
                            pinInput = String(digits.prefix(6))
                        } else if digits != newValue {
                            pinInput = digits
                        }
                        errorMessage = nil
                        if pinInput.count == 6 {
                            Task { await submit() }
                        }
                    }

                // Error
                if let error = errorMessage {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.statusCritical)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppMetrics.spacing20)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: errorMessage)
                } else if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                }

                // Sign out escape hatch
                Button(action: logoutAndReturnToLogin) {
                    Text(L10n.AutoLock.logoutButton)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.brandPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(AppMetrics.spacing32)
            .frame(maxWidth: 420)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .shadow(color: .black.opacity(0.3), radius: 28, x: 0, y: 12)
            .overlay(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .strokeBorder(AppColors.borderSubtle.opacity(0.6), lineWidth: AppMetrics.borderWidth)
            )
            .padding(.horizontal, AppMetrics.spacing40)
        }
        .onAppear { pinFocused = true }
    }

    // MARK: - Actions

    private func submit() async {
        guard pinInput.count == 6 else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let appUuid = diContainer.checkinService.appUuid
        do {
            try await diContainer.authService.pinLogin(pin: pinInput, appUuid: appUuid)
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
