//
//  PhoneLoginPinSection.swift
//  EKGx
//

import SwiftUI

struct PhonePinSection: View {

    @Bindable var viewModel: LoginViewModel

    var body: some View {
        VStack(spacing: 0) {
            pinHeader
            pinDots
            pinFeedback
            PinNumericKeypad(
                onDigit:      { viewModel.keypadInput($0) },
                onDelete:     { viewModel.keypadDelete() },
                buttonHeight: 56,
                spacing:      10
            )
            .disabled(viewModel.isLoading)
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.bottom, AppMetrics.spacing20)
        }
    }

    private var pinHeader: some View {
        VStack(spacing: AppMetrics.spacing6) {
            Text(L10n.Auth.Login.title)
                .font(AppTypography.phoneTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(L10n.Auth.Login.pinTitle)
                .font(AppTypography.phoneCallout)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, AppMetrics.spacing16)
        .padding(.bottom, AppMetrics.spacing12)
    }

    private var pinDots: some View {
        HStack(spacing: AppMetrics.spacing16) {
            ForEach(0..<6, id: \.self) { index in
                ZStack {
                    Circle()
                        .stroke(
                            index < viewModel.pinInput.count
                                ? AppColors.brandSecondary
                                : AppColors.borderSubtle,
                            lineWidth: 2
                        )
                        .frame(width: 18, height: 18)
                    if index < viewModel.pinInput.count {
                        Circle()
                            .fill(AppColors.brandSecondary)
                            .frame(width: 11, height: 11)
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: viewModel.pinInput.count)
            }
        }
        .padding(.bottom, AppMetrics.spacing12)
    }

    private var pinFeedback: some View {
        Group {
            if let error = viewModel.pinError {
                Text(error)
                    .font(AppTypography.phoneCaption)
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
    }
}
