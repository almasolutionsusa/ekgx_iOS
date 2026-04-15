//
//  ActivityTrackingView.swift
//  EKGx
//
//  A zero-impact passthrough gesture recognizer that reports every touch
//  anywhere in the window to the AutoLockManager. Uses UIKit so the touches
//  reach the underlying SwiftUI views normally — we only observe them.
//

import SwiftUI
import UIKit

struct ActivityTrackingView: UIViewRepresentable {

    let onActivity: () -> Void

    func makeUIView(context: Context) -> ActivityPassthroughView {
        let view = ActivityPassthroughView(onActivity: onActivity)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: ActivityPassthroughView, context: Context) {}
}

final class ActivityPassthroughView: UIView {

    private let onActivity: () -> Void

    init(onActivity: @escaping () -> Void) {
        self.onActivity = onActivity
        super.init(frame: .zero)
        isUserInteractionEnabled = false   // never intercept; observe only
        // Attach once the view moves into a window so we recognize globally.
    }

    required init?(coder: NSCoder) { fatalError() }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window else { return }
        let recognizer = PassThroughGestureRecognizer(target: self, action: #selector(handle(_:)))
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        window.addGestureRecognizer(recognizer)
    }

    @objc private func handle(_ sender: UIGestureRecognizer) {
        onActivity()
    }
}

/// A gesture recognizer that fires on every touch but never claims them —
/// the touches continue on to whatever view was under them.
final class PassThroughGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        state = .recognized
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        state = .recognized
    }
    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool { false }
}
