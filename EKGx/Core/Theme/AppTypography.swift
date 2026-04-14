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

    static let largeTitle       = Font.custom("Montserrat-Bold",      size: 48)
    static let title1           = Font.custom("Montserrat-SemiBold",  size: 38)
    static let title1Extra      = Font.custom("Montserrat-ExtraBold", size: 38)
    static let title2           = Font.custom("Montserrat-SemiBold",  size: 30)
    static let title3           = Font.custom("Montserrat-SemiBold",  size: 26)

    // MARK: - Body (Roboto)

    static let body         = Font.custom("Roboto-Regular",  size: 22)
    static let bodyMedium   = Font.custom("Roboto-Medium",   size: 22)
    static let bodySemibold = Font.custom("Roboto-SemiBold", size: 22)
    static let callout      = Font.custom("Roboto-Regular",  size: 20)
    static let calloutBold  = Font.custom("Roboto-SemiBold", size: 20)

    // MARK: - Supporting (Roboto)

    static let subheadline = Font.custom("Roboto-Regular",  size: 19)
    static let footnote    = Font.custom("Roboto-Regular",  size: 17)
    static let caption     = Font.custom("Roboto-Regular",  size: 16)
    static let captionBold = Font.custom("Roboto-SemiBold", size: 16)

    // MARK: - Monospaced (Vitals & ECG Values)

    static let vitalsLarge = Font.system(size: 44, weight: .bold,   design: .monospaced)
    static let vitals      = Font.system(size: 34, weight: .bold,   design: .monospaced)
    static let vitalsSmall = Font.system(size: 22, weight: .medium, design: .monospaced)
}
