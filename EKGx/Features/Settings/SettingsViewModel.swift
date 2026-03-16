//
//  SettingsViewModel.swift
//  EKGx
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - ECG Signal

    var minnesotaCodeEnabled: Bool = false
    var showLeadV5: Bool           = true
    var emgFilter: EMGFilter       = .off
    var highPass: HighPassFilter   = .hz005
    var lowPass: LowPassFilter     = .hz100
    var acNotch: ACNotch           = .hz060

    // MARK: - Display

    var darkModeEnabled: Bool = false

    // MARK: - Privacy

    var allowPromotionalEmails: Bool = false

    // MARK: - Security

    var demoDataEnabled: Bool  = false
    var autoLock: AutoLock     = .threeMinutes

    // MARK: - Demo code gate
    var showDemoCodeEntry: Bool   = false
    var demoCodeInput: String     = ""
    var demoCodeError: String?    = nil
    private let demoUnlockCode    = "DEMO2025"

    // MARK: - Unsaved changes tracking

    private var savedState: SettingsSnapshot = .init()
    var hasUnsavedChanges: Bool {
        currentSnapshot != savedState
    }

    // MARK: - Dependencies

    private let router: AppRouter

    init(router: AppRouter) {
        self.router = router
        savedState = currentSnapshot
    }

    // MARK: - Sections

    enum Section: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case ecgSignal   = "ECG Signal"
        case display     = "Display"
        case privacy     = "Privacy"
        case security    = "Security"

        var systemImage: String {
            switch self {
            case .ecgSignal: return "waveform.path.ecg"
            case .display:   return "sun.max"
            case .privacy:   return "hand.raised"
            case .security:  return "lock.shield"
            }
        }
    }

    // MARK: - Actions

    func saveChanges() {
        savedState = currentSnapshot
        // Persist via @AppStorage or API call here
    }

    func discardChanges() {
        apply(snapshot: savedState)
    }

    func navigateBack() {
        router.navigate(to: .dashboard)
    }

    // MARK: - Demo code

    func attemptEnableDemoData() {
        if demoDataEnabled {
            demoDataEnabled = false
        } else {
            showDemoCodeEntry = true
            demoCodeInput = ""
            demoCodeError = nil
        }
    }

    func submitDemoCode() {
        if demoCodeInput.uppercased() == demoUnlockCode {
            demoDataEnabled    = true
            showDemoCodeEntry  = false
            demoCodeInput      = ""
            demoCodeError      = nil
        } else {
            demoCodeError = L10n.Settings.Security.demoError
        }
    }

    func cancelDemoCode() {
        showDemoCodeEntry = false
        demoCodeInput     = ""
        demoCodeError     = nil
    }

    // MARK: - Snapshot

    private var currentSnapshot: SettingsSnapshot {
        SettingsSnapshot(
            minnesotaCodeEnabled:    minnesotaCodeEnabled,
            showLeadV5:              showLeadV5,
            emgFilter:               emgFilter,
            highPass:                highPass,
            lowPass:                 lowPass,
            acNotch:                 acNotch,
            darkModeEnabled:         darkModeEnabled,
            allowPromotionalEmails:  allowPromotionalEmails,
            demoDataEnabled:         demoDataEnabled,
            autoLock:                autoLock
        )
    }

    private func apply(snapshot: SettingsSnapshot) {
        minnesotaCodeEnabled   = snapshot.minnesotaCodeEnabled
        showLeadV5             = snapshot.showLeadV5
        emgFilter              = snapshot.emgFilter
        highPass               = snapshot.highPass
        lowPass                = snapshot.lowPass
        acNotch                = snapshot.acNotch
        darkModeEnabled        = snapshot.darkModeEnabled
        allowPromotionalEmails = snapshot.allowPromotionalEmails
        demoDataEnabled        = snapshot.demoDataEnabled
        autoLock               = snapshot.autoLock
    }
}

// MARK: - Snapshot (Equatable for change detection)

private struct SettingsSnapshot: Equatable {
    var minnesotaCodeEnabled:   Bool            = false
    var showLeadV5:             Bool            = true
    var emgFilter:              EMGFilter       = .off
    var highPass:               HighPassFilter  = .hz005
    var lowPass:                LowPassFilter   = .hz100
    var acNotch:                ACNotch         = .hz060
    var darkModeEnabled:        Bool            = false
    var allowPromotionalEmails: Bool            = false
    var demoDataEnabled:        Bool            = false
    var autoLock:               AutoLock        = .threeMinutes
}

// MARK: - Option Enums

enum EMGFilter: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case off    = "Off"
    case weak   = "Weak"
    case strong = "Strong"
}

enum HighPassFilter: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case hz000 = "0.0 Hz"
    case hz005 = "0.05 Hz"
    case hz008 = "0.08 Hz"
    case hz010 = "0.1 Hz"
}

enum LowPassFilter: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case hz000 = "0 Hz"
    case hz040 = "40 Hz"
    case hz070 = "70 Hz"
    case hz100 = "100 Hz"
}

enum ACNotch: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case hz000 = "Off"
    case hz050 = "50 Hz"
    case hz060 = "60 Hz"
}

enum AutoLock: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case disabled     = "Disabled"
    case threeMinutes = "3 min"
    case fiveMinutes  = "5 min"
}
