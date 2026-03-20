//
//  FeatureCard.swift
//  EKGx
//
//  Bold feature card — colored gradient header stripe with large icon.
//

import SwiftUI

struct FeatureCard: View {

    let systemImage: String
    let title: String
    let subtitle: String
    let accentColor: Color
    var isEnabled: Bool = true
    let action: () -> Void

    private var effectiveColor: Color { isEnabled ? accentColor : AppColors.textSecondary }

    var body: some View {
        Button(action: { if isEnabled { action() } }) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Colored header stripe
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [effectiveColor, effectiveColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 110)

                    // Faded decorative icon
                    Image(systemName: systemImage)
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(.white.opacity(0.12))
                        .offset(x: 60, y: 20)

                    // Foreground icon badge
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 56, height: 56)
                        Image(systemName: isEnabled ? systemImage : "lock.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.leading, AppMetrics.spacing24)
                    .padding(.bottom, AppMetrics.spacing16)
                }

                // ── Text content
                VStack(alignment: .leading, spacing: AppMetrics.spacing8) {
                    Text(title)
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(subtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    HStack(spacing: AppMetrics.spacing6) {
                        Text(isEnabled ? L10n.Common.open : L10n.Home.Card.deviceRequired)
                            .font(AppTypography.captionBold)
                        Image(systemName: isEnabled ? "arrow.right" : "antenna.radiowaves.left.and.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(effectiveColor)
                }
                .padding(.horizontal, AppMetrics.spacing24)
                .padding(.top, AppMetrics.spacing20)
                .padding(.bottom, AppMetrics.spacing24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.radiusXLarge))
            .shadow(color: effectiveColor.opacity(isEnabled ? 0.18 : 0.08), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .buttonStyle(FeatureCardButtonStyle())
    }
}

// MARK: - Press Animation

private struct FeatureCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: AppMetrics.spacing20) {
        FeatureCard(
            systemImage: "waveform.path.ecg",
            title: "ECG Recording",
            subtitle: "Capture and monitor live cardiac waveforms in real time",
            accentColor: AppColors.brandPrimary,
            action: {}
        )
        FeatureCard(
            systemImage: "person.2.fill",
            title: "Patients",
            subtitle: "Search, add, and manage patient records and history",
            accentColor: AppColors.brandSecondary,
            action: {}
        )
        FeatureCard(
            systemImage: "cloud.fill",
            title: "Cloud & Reports",
            subtitle: "Sync recordings and generate clinical PDF reports",
            accentColor: AppColors.statusInfo,
            action: {}
        )
    }
    .frame(height: 320)
    .padding(32)
    .background(AppColors.surfaceBackground)
}
