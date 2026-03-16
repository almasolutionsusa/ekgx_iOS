//
//  LoadingOverlay.swift
//  EKGx
//
//  Full-screen loading overlay with a blurred background and branded spinner.
//

import SwiftUI

struct LoadingOverlay: View {

    var message: String = L10n.Common.loading

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .allowsHitTesting(true)

            VStack(spacing: AppMetrics.spacing16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.brandPrimary))
                    .scaleEffect(1.4)

                Text(message)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(AppMetrics.spacing32)
            .background(.ultraThinMaterial)
            .cornerRadius(AppMetrics.radiusLarge)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
        }
        .transition(.opacity)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.surfaceBackground.ignoresSafeArea()
        LoadingOverlay()
    }
}
