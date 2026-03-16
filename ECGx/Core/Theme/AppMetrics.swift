//
//  AppMetrics.swift
//  ECGx
//
//  Spacing, corner radii, and sizing constants for the ECGx design system.
//  Maintain visual consistency by referencing these values exclusively.
//

import CoreGraphics

struct AppMetrics {

    // MARK: - Spacing Scale (4pt base grid)

    static let spacing2:  CGFloat = 2
    static let spacing4:  CGFloat = 4
    static let spacing6:  CGFloat = 6
    static let spacing8:  CGFloat = 8
    static let spacing10: CGFloat = 10
    static let spacing12: CGFloat = 12
    static let spacing14: CGFloat = 14
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing28: CGFloat = 28
    static let spacing32: CGFloat = 32
    static let spacing40: CGFloat = 40
    static let spacing48: CGFloat = 48
    static let spacing56: CGFloat = 56
    static let spacing64: CGFloat = 64

    // MARK: - Corner Radii

    static let radiusSmall:  CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge:  CGFloat = 16
    static let radiusXLarge: CGFloat = 24

    // MARK: - Component Sizes

    static let buttonHeight:    CGFloat = 56
    static let textFieldHeight: CGFloat = 56
    static let iconSizeSmall:   CGFloat = 16
    static let iconSizeMedium:  CGFloat = 24
    static let iconSizeLarge:   CGFloat = 32

    // MARK: - Borders

    static let borderWidth:       CGFloat = 1.0
    static let borderWidthFocused: CGFloat = 2.0

    // MARK: - Layout

    static let formMaxWidth:      CGFloat = 440
    static let registerFormMaxWidth: CGFloat = 720
    static let sidebarWidthRatio: CGFloat = 0.38
    static let cardPadding:       CGFloat = 32
    static let sideMenuWidth:     CGFloat = 320
    static let navBarHeight:      CGFloat = 68
}
