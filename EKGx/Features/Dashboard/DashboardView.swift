//
//  DashboardView.swift
//  EKGx
//
//  Main dashboard — placeholder until ECG recording and patient management
//  features are implemented in subsequent iterations.
//

import SwiftUI

struct DashboardView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            AppColors.surfaceBackground.ignoresSafeArea()

            VStack(spacing: AppMetrics.spacing24) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(AppColors.brandPrimary)

                VStack(spacing: AppMetrics.spacing8) {
                    Text(L10n.Branding.appName)
                        .font(AppTypography.title1)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("ECG Recording & Analysis Dashboard")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Text("Dashboard coming soon.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .italic()
            }
        }
    }
}

#Preview {
    DashboardView()
        .environment(AppRouter())
}
