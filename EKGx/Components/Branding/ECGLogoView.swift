//
//  ECGLogoView.swift
//  EKGx
//
//  Animated ECG logo — dark pill with live waveform + title below.
//  Baseline sits at 72% height so the R-spike has room to breathe at the top.
//

import SwiftUI

// MARK: - ECGLogoView

struct ECGLogoView: View {

    var width: CGFloat  = 240
    var height: CGFloat = 80      // taller canvas so R-spike is never clipped

    @State private var startDate = Date()
    private let loopDuration: Double = 2.4
    private let pauseDuration: Double = 3.0   // idle gap between beats

    var body: some View {
        VStack(spacing: AppMetrics.spacing8) {

            // Dark pill — canvas sits inside with padding on all sides
            TimelineView(.animation) { timeline in
                let cycleDuration = loopDuration + pauseDuration   // 4.4 s total
                let elapsed  = timeline.date.timeIntervalSince(startDate)
                let phase    = elapsed.truncatingRemainder(dividingBy: cycleDuration)
                // During the first loopDuration seconds the dot travels 0→1.
                // For the remaining pauseDuration seconds progress stays at 0 (dot at start).
                let progress = phase < loopDuration
                    ? CGFloat(phase / loopDuration)
                    : 0
                ECGAnimatedCanvas(progress: progress, width: width, height: height)
            }
            .frame(width: width, height: height)
            .padding(.horizontal, AppMetrics.spacing20)
            .padding(.vertical, AppMetrics.spacing10)
            .background(
                RoundedRectangle(cornerRadius: AppMetrics.radiusLarge)
                    .fill(AppColors.surfaceSidebar)
                    .shadow(color: AppColors.brandPrimary.opacity(0.25), radius: 10, x: 0, y: 4)
            )

            // App title
            Text(L10n.Branding.appName)
                .font(AppTypography.title1Extra)
                .foregroundStyle(AppColors.textPrimary)
                .tracking(2)
        }
        .onAppear { startDate = Date() }
    }
}

// MARK: - ECGAnimatedCanvas

private struct ECGAnimatedCanvas: View {

    let progress: CGFloat
    let width: CGFloat
    let height: CGFloat

    private let lineColor = AppColors.ecgWaveform

    var body: some View {
        Canvas { ctx, size in
            let rect     = CGRect(origin: .zero, size: size)
            let fullPath = ECGWaveformShape().path(in: rect)

            // Dim full waveform
            ctx.stroke(
                Path(fullPath.cgPath),
                with: .color(lineColor.opacity(0.55)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )

            // Bright trailing segment behind dot
            let trailPath = fullPath.trimmedPath(from: max(0, progress - 0.15), to: progress)
            ctx.stroke(
                Path(trailPath.cgPath),
                with: .color(lineColor),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )

            // Moving dot
            guard let point = fullPath.trimmedPath(from: 0, to: progress).currentPoint else { return }
            let r: CGFloat = 5
            ctx.fill(
                Path(ellipseIn: CGRect(x: point.x - r * 2.2, y: point.y - r * 2.2,
                                       width: r * 4.4, height: r * 4.4)),
                with: .color(lineColor.opacity(0.2))
            )
            ctx.fill(
                Path(ellipseIn: CGRect(x: point.x - r, y: point.y - r,
                                       width: r * 2, height: r * 2)),
                with: .color(.white)
            )
        }
        .frame(width: width, height: height)
    }
}

// MARK: - ECGWaveformShape

struct ECGWaveformShape: Shape {

    func path(in rect: CGRect) -> Path {
        let w   = rect.width
        let h   = rect.height
        // Baseline at 70% — leaves 70% below for S dip, 30% above for R spike
        let mid = h * 0.70

        var p = Path()

        p.move(to: CGPoint(x: 0, y: mid))
        p.addLine(to: CGPoint(x: w * 0.10, y: mid))

        // P wave
        p.addCurve(
            to:       CGPoint(x: w * 0.20, y: mid),
            control1: CGPoint(x: w * 0.13, y: mid - h * 0.14),
            control2: CGPoint(x: w * 0.17, y: mid - h * 0.14)
        )

        // PR segment
        p.addLine(to: CGPoint(x: w * 0.26, y: mid))

        // Q dip
        p.addLine(to: CGPoint(x: w * 0.30, y: mid + h * 0.08))

        // R spike — reaches 8% from top (0.92 * h from top = h * 0.08 from top)
        p.addLine(to: CGPoint(x: w * 0.34, y: h * 0.06))

        // S dip
        p.addLine(to: CGPoint(x: w * 0.38, y: mid + h * 0.16))

        // ST segment
        p.addLine(to: CGPoint(x: w * 0.46, y: mid))

        // T wave
        p.addCurve(
            to:       CGPoint(x: w * 0.62, y: mid),
            control1: CGPoint(x: w * 0.50, y: mid - h * 0.22),
            control2: CGPoint(x: w * 0.58, y: mid - h * 0.22)
        )

        // Flat baseline (right)
        p.addLine(to: CGPoint(x: w, y: mid))

        return p
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppColors.surfaceBackground.ignoresSafeArea()
        ECGLogoView()
    }
}
