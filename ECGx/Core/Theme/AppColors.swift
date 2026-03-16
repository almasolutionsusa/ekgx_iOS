//
//  AppColors.swift
//  ECGx
//
//  Semantic color tokens for the ECGx hospital design system.
//  All colors are backed by named Color Sets in Assets.xcassets so
//  they automatically adapt to light/dark mode if needed.
//

import SwiftUI

/// The single source of truth for every color used in ECGx.
/// Consume via static properties — never use literal hex values in views.
struct AppColors {

    // MARK: - Brand

    /// Primary brand blue — used for primary actions, active states, and key UI elements.
    static let brandPrimary     = Color("BrandPrimary")

    /// Darker variant of brandPrimary — pressed / hover states.
    static let brandPrimaryDark = Color("BrandPrimaryDark")

    /// Teal accent — secondary highlights, ECG status indicators.
    static let brandSecondary   = Color("BrandSecondary")

    // MARK: - Surfaces

    /// Main app background — cool off-white that reduces eye fatigue.
    static let surfaceBackground = Color("SurfaceBackground")

    /// Card / panel surface — pure white for elevated content areas.
    static let surfaceCard       = Color("SurfaceCard")

    /// Navigation sidebar / branding panel — deep navy.
    static let surfaceSidebar    = Color("SurfaceSidebar")

    // MARK: - Text

    /// Primary body text — near-black for maximum readability.
    static let textPrimary    = Color("TextPrimary")

    /// Secondary / supporting text — medium gray for labels and placeholders.
    static let textSecondary  = Color("TextSecondary")

    /// Text rendered on dark surfaces (sidebar, overlays).
    static let textOnDark     = Color("TextOnDark")

    // MARK: - Borders & Dividers

    /// Default field border and divider lines.
    static let borderSubtle  = Color("BorderSubtle")

    /// Focused input ring — matches brandPrimary for visual consistency.
    static let borderFocused = Color("BorderFocused")

    // MARK: - Status

    /// Normal / healthy readings.
    static let statusSuccess  = Color("StatusSuccess")

    /// Borderline / attention-required readings. Never used decoratively.
    static let statusWarning  = Color("StatusWarning")

    /// Critical / emergency values. High-contrast red.
    static let statusCritical = Color("StatusCritical")

    /// Informational badges and secondary indicators.
    static let statusInfo     = Color("StatusInfo")

    // MARK: - ECG Waveform

    /// Live ECG trace line — bright mint green on dark background.
    static let ecgWaveform   = Color("ECGWaveform")

    /// ECG chart background — dark navy for clinical paper aesthetic.
    static let ecgBackground = Color("ECGBackground")
}
