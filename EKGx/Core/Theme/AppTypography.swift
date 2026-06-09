//
//  AppTypography.swift
//  EKGx
//
//  Font scale — Montserrat (titles) + Roboto (body).
//  Sized for iPad hospital use: large, readable at arm's length.
//

import SwiftUI

struct AppTypography {

    // MARK: - Headings (Montserrat)
    // relativeTo: lets these scale when .dynamicTypeSize is applied at the root.

    static let largeTitle  = Font.custom("Montserrat-Bold",      size: 48, relativeTo: .largeTitle)
    static let title1      = Font.custom("Montserrat-SemiBold",  size: 38, relativeTo: .title)
    static let title1Extra = Font.custom("Montserrat-ExtraBold", size: 38, relativeTo: .title)
    static let title2      = Font.custom("Montserrat-SemiBold",  size: 30, relativeTo: .title2)
    static let title3      = Font.custom("Montserrat-SemiBold",  size: 26, relativeTo: .title3)

    // MARK: - Body (Roboto)

    static let body         = Font.custom("Roboto-Regular",  size: 22, relativeTo: .body)
    static let bodyMedium   = Font.custom("Roboto-Medium",   size: 22, relativeTo: .body)
    static let bodySemibold = Font.custom("Roboto-SemiBold", size: 22, relativeTo: .body)
    static let callout      = Font.custom("Roboto-Regular",  size: 20, relativeTo: .callout)
    static let calloutBold  = Font.custom("Roboto-SemiBold", size: 20, relativeTo: .callout)

    // MARK: - Supporting (Roboto)

    static let subheadline = Font.custom("Roboto-Regular",  size: 19, relativeTo: .subheadline)
    static let subheadline2 = Font.custom("Roboto-SemiBold",  size: 19, relativeTo: .subheadline)

    static let footnote    = Font.custom("Roboto-Regular",  size: 17, relativeTo: .footnote)
    static let caption     = Font.custom("Roboto-Regular",  size: 16, relativeTo: .caption)
    static let captionBold = Font.custom("Roboto-SemiBold", size: 16, relativeTo: .caption)

    // MARK: - Monospaced (Vitals & ECG Values)

    static let vitalsLarge = Font.system(size: 44, weight: .bold,   design: .monospaced)
    static let vitals      = Font.system(size: 34, weight: .bold,   design: .monospaced)
    static let vitalsSmall = Font.system(size: 22, weight: .medium, design: .monospaced)
}
