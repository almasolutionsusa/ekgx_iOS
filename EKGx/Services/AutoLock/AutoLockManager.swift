//
//  AutoLockManager.swift
//  EKGx
//
//  Tracks user activity and locks the app after a period of inactivity.
//  HIPAA-compliant — unattended hospital iPads must not expose patient data.
//
//  Flow:
//  1. On login the manager starts counting down from `timeoutSeconds` (taken
//     from the login response `appSettings.autolockSeconds`).
//  2. Any touch anywhere in the window resets the timer via `reportActivity()`.
//  3. When the timer fires, `isLocked = true`. RootView shows a LockOverlay
//     on top of the current screen.
//  4. User enters PIN → PIN login succeeds → `unlock()` clears the flag and
//     resumes exactly where they left off.
//
//  Skipped entirely in local/offline mode (no PIN to verify against).
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class AutoLockManager {

    // MARK: - State

    /// True when the lock overlay should be visible.
    var isLocked: Bool = false

    /// The configured timeout in seconds. 0 disables autolock.
    private(set) var timeoutSeconds: TimeInterval = 0

    // MARK: - Internal

    private var timer: Timer?

    // MARK: - Configuration

    /// Call after a successful login so the manager knows the timeout value.
    /// Pass 0 to disable autolock (e.g. the user picked "Disabled").
    func configure(timeoutSeconds: Int) {
        self.timeoutSeconds = TimeInterval(max(0, timeoutSeconds))
        restartTimer()
    }

    /// Resets the countdown. Call on any user activity.
    func reportActivity() {
        guard !isLocked else { return }   // once locked, taps should reach the overlay
        restartTimer()
    }

    /// Clears the locked state after the user re-authenticates.
    func unlock() {
        isLocked = false
        restartTimer()
    }

    /// Stops the timer and clears the locked state (e.g. on logout).
    func stop() {
        timer?.invalidate()
        timer = nil
        isLocked = false
        timeoutSeconds = 0
    }

    // MARK: - Private

    private func restartTimer() {
        timer?.invalidate()
        timer = nil
        guard timeoutSeconds > 0 else { return }

        timer = Timer.scheduledTimer(withTimeInterval: timeoutSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.lockNow()
            }
        }
    }

    private func lockNow() {
        guard !isLocked else { return }
        isLocked = true
        timer?.invalidate()
        timer = nil
    }
}
