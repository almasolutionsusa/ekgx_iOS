import SwiftUI

// Single source of truth for every vital measurement type.
// Adding a new vital = add one case here + register its VitalDeviceService.
enum VitalType: String, CaseIterable, Identifiable {
    case ekg
    case echo
    case bloodPressure
    case oxygenSaturation
    case temperature
    case bloodSugar
    case heartRate
    case weight
    case respirations
    case height
    case painLevel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ekg:              return "EKGx"
        case .echo:             return "Echo"
        case .bloodPressure:    return "Blood Pressure"
        case .oxygenSaturation: return "Oxygen Saturation"
        case .temperature:      return "Temperature"
        case .bloodSugar:       return "Blood Sugar"
        case .heartRate:        return "Heart Rate"
        case .weight:           return "Weight"
        case .respirations:     return "Respirations"
        case .height:           return "Height"
        case .painLevel:        return "Pain Level"
        }
    }

    var icon: String {
        switch self {
        case .ekg:              return "waveform.path.ecg"
        case .echo:             return "waveform.path.ecg.rectangle"
        case .bloodPressure:    return "book.closed.fill"
        case .oxygenSaturation: return "lungs.fill"
        case .temperature:      return "thermometer.medium"
        case .bloodSugar:       return "drop.fill"
        case .heartRate:        return "waveform.path"
        case .weight:           return "scalemass.fill"
        case .respirations:     return "lungs"
        case .height:           return "ruler.fill"
        case .painLevel:        return "face.smiling"
        }
    }

    var iconColor: Color {
        switch self {
        case .ekg:              return AppColors.brandPrimary
        case .echo:             return Color(red: 0.18, green: 0.75, blue: 0.85)
        case .bloodPressure:    return Color(red: 0.45, green: 0.45, blue: 0.90)
        case .oxygenSaturation: return Color(red: 0.18, green: 0.75, blue: 0.75)
        case .temperature:      return Color(red: 0.18, green: 0.80, blue: 0.65)
        case .bloodSugar:       return Color(red: 0.50, green: 0.40, blue: 0.90)
        case .heartRate:        return Color(red: 0.18, green: 0.75, blue: 0.85)
        case .weight:           return Color(red: 0.18, green: 0.80, blue: 0.70)
        case .respirations:     return Color(red: 0.60, green: 0.35, blue: 0.85)
        case .height:           return Color(red: 0.25, green: 0.55, blue: 0.90)
        case .painLevel:        return Color(red: 0.18, green: 0.78, blue: 0.72)
        }
    }

    var connectDescription: String {
        "Pair your \(title) device via Bluetooth"
    }

    // First two vitals render as wide cards in a 2-column top row.
    var isWideCard: Bool { self == .ekg || self == .echo }

    // EKG is the only active vital today; others are placeholders.
    var isAvailable: Bool { self == .ekg }

    // EKG card replaces the text title with the app logo image.
    var usesLogoImage: Bool { self == .ekg }
}
