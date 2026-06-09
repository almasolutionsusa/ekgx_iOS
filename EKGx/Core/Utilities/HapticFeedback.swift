import SwiftUI
import UIKit

// MARK: - Haptic utility

enum HapticFeedback {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - HapticButtonStyle

/// Drop-in for .buttonStyle(.plain): fires a light haptic + tap sound on press-down.
struct HapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, new in new }
            .onChange(of: configuration.isPressed) { _, pressed in
                guard pressed else { return }
                let enabled = UserDefaults.standard.object(forKey: "app.tapSound") as? Bool ?? true
                if enabled { AppSounds.shared.tap() }
            }
    }
}

extension ButtonStyle where Self == HapticButtonStyle {
    static var hapticPlain: HapticButtonStyle { HapticButtonStyle() }
}
