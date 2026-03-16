//
//  AppTypography.swift
//  EKGx
//
//  Font scale — Montserrat (titles) + Roboto (body).
//

import SwiftUI

struct AppTypography {

    // MARK: - Headings (Montserrat)

    static let largeTitle  = Font.custom("Montserrat-Bold",     size: 40)
    static let title1      = Font.custom("Montserrat-SemiBold", size: 32)
    static let title1Extra      = Font.custom("Montserrat-ExtraBold", size: 32)
    static let title2      = Font.custom("Montserrat-SemiBold", size: 26)
    static let title3      = Font.custom("Montserrat-SemiBold", size: 22)

    // MARK: - Body (Roboto)

    static let body         = Font.custom("Roboto-Regular",  size: 19)
    static let bodyMedium   = Font.custom("Roboto-Medium",   size: 19)
    static let bodySemibold = Font.custom("Roboto-SemiBold", size: 19)
    static let callout      = Font.custom("Roboto-Regular",  size: 18)

    // MARK: - Supporting (Roboto)

    static let subheadline = Font.custom("Roboto-Regular",  size: 17)
    static let footnote    = Font.custom("Roboto-Regular",  size: 15)
    static let caption     = Font.custom("Roboto-Regular",  size: 14)
    static let captionBold = Font.custom("Roboto-SemiBold", size: 14)

    // MARK: - Monospaced (Vitals & ECG Values)

    static let vitalsLarge = Font.system(size: 36, weight: .bold,   design: .monospaced)
    static let vitals      = Font.system(size: 28, weight: .bold,   design: .monospaced)
    static let vitalsSmall = Font.system(size: 18, weight: .medium, design: .monospaced)
}
