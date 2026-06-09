//
//  SettingsViewModel.swift
//  EKGx
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {

    @ObservationIgnored private var isInitializing = true

    // MARK: - ECG Signal

    var minnesotaCodeEnabled: Bool = false {
        didSet { save(minnesotaCodeEnabled, forKey: "app.minnesotaCode") }
    }
    var showLeadV5: Bool = true {
        didSet { save(showLeadV5, forKey: "app.showLeadV5") }
    }
    var emgFilter: EMGFilter = .off {
        didSet { save(emgFilter.rawValue, forKey: "app.emgFilter") }
    }
    var highPass: HighPassFilter = .hz005 {
        didSet { save(highPass.rawValue, forKey: "app.highPass") }
    }
    var lowPass: LowPassFilter = .hz100 {
        didSet { save(lowPass.rawValue, forKey: "app.lowPass") }
    }
    var acNotch: ACNotch = .hz060 {
        didSet { save(acNotch.rawValue, forKey: "app.acNotch") }
    }

    // MARK: - Display

    var darkModeEnabled: Bool = false {
        didSet { save(darkModeEnabled, forKey: "app.darkMode") }
    }
    var tapSoundEnabled: Bool = true {
        didSet { save(tapSoundEnabled, forKey: "app.tapSound") }
    }
    var fontSize: FontSize = {
        if let saved = UserDefaults.standard.string(forKey: "app.fontSize"),
           let size  = FontSize(rawValue: saved) { return size }
        return .medium
    }() {
        didSet { UserDefaults.standard.set(fontSize.rawValue, forKey: "app.fontSize") }
    }

    // MARK: - Units

    var weightUnit: WeightUnit = .imperial {
        didSet { save(weightUnit.rawValue, forKey: "app.weightUnit") }
    }

    var temperatureUnit: TemperatureUnit = .fahrenheit {
        didSet { save(temperatureUnit.rawValue, forKey: "app.temperatureUnit") }
    }

    // MARK: - Privacy

    var allowPromotionalEmails: Bool = false {
        didSet { save(allowPromotionalEmails, forKey: "app.promoEmails") }
    }

    // MARK: - Security

    var demoDataEnabled: Bool = false {
        didSet { save(demoDataEnabled, forKey: "app.demoData") }
    }
    var autoLock: AutoLock = .threeMinutes {
        didSet { save(autoLock.rawValue, forKey: "app.autoLock") }
    }

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
    private let authService: AuthServiceProtocol

    init(router: AppRouter, authService: AuthServiceProtocol) {
        self.router      = router
        self.authService = authService
        applyServerSettings()
        applyLocalSettings()
        isInitializing = false
        savedState = currentSnapshot
    }

    private func save(_ value: some Any, forKey key: String) {
        guard !isInitializing else { return }
        UserDefaults.standard.set(value, forKey: key)
    }

    // MARK: - Server settings (from login response)

    /// Loads values from `authService.loginData?.appSettings` into the view state.
    /// Called on init, so the Settings screen reflects whatever the server
    /// returned at the most recent login.
    private func applyServerSettings() {
        guard let s = authService.loginData?.appSettings else { return }

        if let value = s.minnesotaCode { minnesotaCodeEnabled = value }

        // AC Notch enum: "OFF" | "FREQ_50HZ" | "FREQ_60HZ"
        if let raw = s.acNotch {
            switch raw.uppercased() {
            case "OFF":       acNotch = .hz000
            case "FREQ_50HZ": acNotch = .hz050
            case "FREQ_60HZ": acNotch = .hz060
            default:          break
            }
        }

        // EMG is a string from the server: "OFF" | "WEAK" | "STRONG"
        if let raw = s.emg {
            switch raw.uppercased() {
            case "OFF":    emgFilter = .off
            case "WEAK":   emgFilter = .weak
            case "STRONG": emgFilter = .strong
            default:       break
            }
        }

        // Highpass is a Double in Hz (0, 0.05, 0.08, 0.1)
        if let hp = s.highpass {
            switch hp {
            case 0.0:        highPass = .hz000
            case 0.05:       highPass = .hz005
            case 0.08:       highPass = .hz008
            case 0.1:        highPass = .hz010
            default:
                // Pick the nearest supported cutoff
                let options: [(HighPassFilter, Double)] = [
                    (.hz000, 0.0), (.hz005, 0.05), (.hz008, 0.08), (.hz010, 0.1)
                ]
                highPass = options.min(by: { abs($0.1 - hp) < abs($1.1 - hp) })?.0 ?? highPass
            }
        }

        // Lowpass is a Double in Hz (e.g. 0, 40, 70, 100, or arbitrary like 222)
        if let lp = s.lowpass {
            switch Int(lp) {
            case 0:        lowPass = .hz000
            case 40:       lowPass = .hz040
            case 70:       lowPass = .hz070
            case 100:      lowPass = .hz100
            default:
                let options: [(LowPassFilter, Double)] = [
                    (.hz000, 0), (.hz040, 40), (.hz070, 70), (.hz100, 100)
                ]
                lowPass = options.min(by: { abs($0.1 - lp) < abs($1.1 - lp) })?.0 ?? lowPass
            }
        }

        // Autolock in seconds (180 → 3 min, 300 → 5 min, 0 or unknown → 3 min minimum)
        if let secs = s.autolockSeconds {
            switch secs {
            case 300: autoLock = .fiveMinutes
            default:  autoLock = secs >= 240 ? .fiveMinutes : .threeMinutes
            }
        }
    }

    // MARK: - Local persistence (UserDefaults overrides server defaults)

    private func applyLocalSettings() {
        let ud = UserDefaults.standard
        if let raw = ud.string(forKey: "app.emgFilter"),  let v = EMGFilter(rawValue: raw)      { emgFilter = v }
        if let raw = ud.string(forKey: "app.highPass"),   let v = HighPassFilter(rawValue: raw) { highPass = v }
        if let raw = ud.string(forKey: "app.lowPass"),    let v = LowPassFilter(rawValue: raw)  { lowPass = v }
        if let raw = ud.string(forKey: "app.acNotch"),    let v = ACNotch(rawValue: raw)        { acNotch = v }
        if let raw = ud.string(forKey: "app.autoLock"),   let v = AutoLock(rawValue: raw)       { autoLock = v }
        if ud.object(forKey: "app.minnesotaCode") != nil { minnesotaCodeEnabled  = ud.bool(forKey: "app.minnesotaCode") }
        if ud.object(forKey: "app.showLeadV5")    != nil { showLeadV5            = ud.bool(forKey: "app.showLeadV5") }
        if ud.object(forKey: "app.darkMode")      != nil { darkModeEnabled       = ud.bool(forKey: "app.darkMode") }
        if ud.object(forKey: "app.tapSound")      != nil { tapSoundEnabled       = ud.bool(forKey: "app.tapSound") }
        if ud.object(forKey: "app.promoEmails")   != nil { allowPromotionalEmails = ud.bool(forKey: "app.promoEmails") }
        if ud.object(forKey: "app.demoData")      != nil { demoDataEnabled       = ud.bool(forKey: "app.demoData") }
        if let raw = ud.string(forKey: "app.weightUnit"),      let v = WeightUnit(rawValue: raw)      { weightUnit = v }
        if let raw = ud.string(forKey: "app.temperatureUnit"), let v = TemperatureUnit(rawValue: raw) { temperatureUnit = v }
    }

    // MARK: - Sections

    enum Section: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case ecgSignal   = "EKG Signal"
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
    }

    func discardChanges() {
        apply(snapshot: savedState)
    }

    func navigateBack() {
        router.navigate(to: .patientSelection)
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
            tapSoundEnabled:         tapSoundEnabled,
            fontSize:                fontSize,
            allowPromotionalEmails:  allowPromotionalEmails,
            demoDataEnabled:         demoDataEnabled,
            autoLock:                autoLock,
            weightUnit:              weightUnit,
            temperatureUnit:         temperatureUnit
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
        tapSoundEnabled        = snapshot.tapSoundEnabled
        fontSize               = snapshot.fontSize
        allowPromotionalEmails = snapshot.allowPromotionalEmails
        demoDataEnabled        = snapshot.demoDataEnabled
        autoLock               = snapshot.autoLock
        weightUnit             = snapshot.weightUnit
        temperatureUnit        = snapshot.temperatureUnit
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
    var tapSoundEnabled:        Bool            = true
    var fontSize:               FontSize        = .medium
    var allowPromotionalEmails: Bool            = false
    var demoDataEnabled:        Bool            = false
    var autoLock:               AutoLock        = .threeMinutes
    var weightUnit:             WeightUnit      = .imperial
    var temperatureUnit:        TemperatureUnit = .fahrenheit
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
    case threeMinutes = "3 min"
    case fiveMinutes  = "5 min"
}

enum WeightUnit: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case imperial = "lb"
    case metric   = "kg"
    var label: String { self == .imperial ? "lbs" : "kg" }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case fahrenheit = "°F"
    case celsius    = "°C"
}

enum FontSize: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case small  = "Small"
    case medium = "Medium"
    case large  = "Large"

    /// Maps to a DynamicTypeSize so .dynamicTypeSize() at the root scales all relativeTo: fonts.
    /// .large is the iOS system default (1×); small/large shift one step either way.
    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small:  return .xSmall
        case .medium: return .large
        case .large:  return .xxLarge
        }
    }
}
