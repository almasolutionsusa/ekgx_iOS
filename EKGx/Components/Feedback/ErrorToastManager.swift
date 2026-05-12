//
//  ErrorToastManager.swift
//  EKGx
//
//  Singleton that holds the current error toast message.
//  Wire APIClient.shared.onError to this once at app startup —
//  every failed API call then automatically surfaces a toast.
//

import Foundation

@Observable
@MainActor
final class ErrorToastManager {

    var message: String? = nil

    private var dismissTask: Task<Void, Never>?

    func show(_ message: String) {
        dismissTask?.cancel()
        self.message = message
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self.message = nil
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        message = nil
    }
}
