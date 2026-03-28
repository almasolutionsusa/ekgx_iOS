//
//  AppMetrics.swift
//  EKGx
//
//  Spacing, corner radii, and sizing constants for the EKGx design system.
//  Sized for iPad hospital use — generous touch targets, clear visual rhythm.
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

    static let radiusSmall:  CGFloat = 10
    static let radiusMedium: CGFloat = 14
    static let radiusLarge:  CGFloat = 20
    static let radiusXLarge: CGFloat = 28

    // MARK: - Component Sizes — iPad-optimised touch targets

    static let buttonHeight:    CGFloat = 64
    static let textFieldHeight: CGFloat = 64
    static let iconSizeSmall:   CGFloat = 20
    static let iconSizeMedium:  CGFloat = 28
    static let iconSizeLarge:   CGFloat = 38

    // MARK: - Borders

    static let borderWidth:        CGFloat = 1.5
    static let borderWidthFocused: CGFloat = 2.5

    // MARK: - Layout

    static let formMaxWidth:          CGFloat = 500
    static let registerFormMaxWidth:  CGFloat = 800
    static let sidebarWidthRatio:     CGFloat = 0.38
    static let cardPadding:           CGFloat = 36
    static let sideMenuWidth:         CGFloat = 360
    static let navBarHeight:          CGFloat = 76
}
