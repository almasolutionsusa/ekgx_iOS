//
//  AppColors.swift
//  EKGx
//
//  Semantic color tokens for the iCardio Triage design system.
//  All colors are backed by named Color Sets in Assets.xcassets.
//

import SwiftUI

/// The single source of truth for every color used in EKGx.
/// Consume via static properties — never use literal hex values in views.
struct AppColors {

    // MARK: - Accent

    /// Primary teal accent #2DD4BF — CTA gradient start, logo dot, active states.
    static let accentTeal   = Color("AccentTeal")

    /// Cyan accent #38BDF8 — CTA gradient end, info indicators, glow effects.
    static let accentCyan   = Color("AccentCyan")

    /// Violet accent #A78BFA — tertiary highlights, avatar palette.
    static let accentViolet = Color("AccentViolet")

    // MARK: - Brand (aliases for legacy call sites)

    /// = accentTeal. Primary CTA color; use gradient via PrimaryButton.
    static let brandPrimary     = Color("BrandPrimary")

    /// Pressed / hover variant of brandPrimary.
    static let brandPrimaryDark = Color("BrandPrimaryDark")

    /// = accentCyan. Secondary highlights and status info.
    static let brandSecondary   = Color("BrandSecondary")

    // MARK: - Surfaces

    /// App / scene background #0A1220.
    static let surfaceBackground = Color("SurfaceBackground")

    /// Card surface #111C2E.
    static let surfaceCard       = Color("SurfaceCard")

    /// Elevated card / header / sidebar #16243A.
    static let surfaceSidebar    = Color("SurfaceSidebar")

    // MARK: - Text

    /// Primary text on dark surfaces #E6EDF7.
    static let textPrimary    = Color("TextPrimary")

    /// Secondary / muted text #93A4BE.
    static let textSecondary  = Color("TextSecondary")

    /// Tertiary / disabled text #5D6E89.
    static let textTertiary   = Color("TextTertiary")

    /// Text/icon on top of teal/cyan accent fills #06121E.
    static let onAccent       = Color("OnAccent")

    /// Legacy alias for onAccent — text on dark overlay surfaces.
    static let textOnDark     = Color("TextOnDark")

    // MARK: - Borders & Dividers

    /// Default border and divider #1F2F4A.
    static let borderSubtle  = Color("BorderSubtle")

    /// Focused input ring — accentTeal.
    static let borderFocused = Color("BorderFocused")

    // MARK: - Status

    /// Success / connected / ready #22C55E.
    static let statusSuccess  = Color("StatusSuccess")

    /// Warning / caution #F59E0B.
    static let statusWarning  = Color("StatusWarning")

    /// Critical / error #EF4444.
    static let statusCritical = Color("StatusCritical")

    /// Informational badges #38BDF8.
    static let statusInfo     = Color("StatusInfo")

    // MARK: - ECG Waveform

    /// Live ECG trace — accentTeal #2DD4BF.
    static let ecgWaveform   = Color("ECGWaveform")

    /// ECG chart background — backgroundDeep #0A1220.
    static let ecgBackground = Color("ECGBackground")

    // MARK: - Gradient helpers

    /// Standard CTA gradient: accentTeal → accentCyan, left to right.
    static let ctaGradient = LinearGradient(
        colors: [accentTeal, accentCyan],
        startPoint: .leading,
        endPoint: .trailing
    )
}
