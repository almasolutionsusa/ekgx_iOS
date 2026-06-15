//
//  PrimaryButton.swift
//  EKGx
//
//  Full-width CTA button with loading state support.
//

import SwiftUI

struct PrimaryButton: View {

    let title: String
    var background: Color = AppColors.brandPrimary
    var foreground: Color = AppColors.onAccent
    var useGradient: Bool = true
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var resolvedFont: Font {
        sizeClass == .compact ? AppTypography.phoneBodyMedium : AppTypography.bodyMedium
    }
    private var resolvedHeight: CGFloat {
        sizeClass == .compact ? 48 : AppMetrics.buttonHeight
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if useGradient {
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .fill(AppColors.ctaGradient.opacity(isDisabled || isLoading ? 0.5 : 1))
                } else {
                    RoundedRectangle(cornerRadius: AppMetrics.radiusMedium)
                        .fill(isDisabled || isLoading ? background.opacity(0.5) : background)
                }
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foreground))
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(resolvedFont)
                        .foregroundStyle(useGradient ? AppColors.onAccent : foreground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: resolvedHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.hapticPlain)
        .disabled(isDisabled || isLoading)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Sign In", action: {})
        PrimaryButton(title: "Sign In", isLoading: true, action: {})
        PrimaryButton(title: "Sign In", isDisabled: true, action: {})
    }
    .padding(32)
    .background(AppColors.surfaceBackground)
}
