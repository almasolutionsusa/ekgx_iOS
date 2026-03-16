//
//  View+Extensions.swift
//  ECGx
//
//  Reusable SwiftUI view modifiers for the ECGx design system.
//

import SwiftUI

extension View {

    /// Applies the hospital card surface style — white background, rounded corners, subtle shadow.
    func eCardStyle() -> some View {
        self
            .background(AppColors.surfaceCard)
            .cornerRadius(AppMetrics.radiusLarge)
            .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
    }

    /// Hides the view conditionally while preserving its layout frame.
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }

    /// Applies a shimmer / loading placeholder overlay.
    func redactedLoading(_ isLoading: Bool) -> some View {
        self.redacted(reason: isLoading ? .placeholder : [])
    }
}
