//
//  LiveClockView.swift
//  EKGx
//
//  Displays the current date and time, updating every second.
//  Reusable across any screen that needs a live clock in the nav bar.
//

import SwiftUI
import Combine

struct LiveClockView: View {

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        Text(Self.formatter.string(from: now))
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .monospacedDigit()
            .onReceive(timer) { now = $0 }
    }
}
