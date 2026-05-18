//
//  ECGImageRenderer.swift
//  EKGx
//
//  CoreGraphics-based 3×4 ECG image renderer.
//  Each column stretches its data segment to fill exactly — no clipping.
//  Replaces the SwiftUI ImageRenderer approach used previously.
//

import UIKit

struct ECGImageRenderer {

    // US-Letter landscape (points at 72 dpi)
    private static let pageWidth:  CGFloat = 792
    private static let pageHeight: CGFloat = 612
    private static let margin:     CGFloat = 14.175   // ~5 mm

    // Standard ECG paper: 72 dpi → ~2.835 px/mm
    private static let pixPerMm: CGFloat = 72.0 / 25.4

    private static let leadNames: [String] = [
        "I", "II", "III", "aVR", "aVL", "aVF",
        "V1", "V2", "V3",  "V4",  "V5",  "V6",
    ]

    // Row-major 3×4 clinical lead order
    private static let leadOrder: [[Int]] = [
        [0, 3, 6,  9],   // I,   aVR, V1, V4
        [1, 4, 7, 10],   // II,  aVL, V2, V5
        [2, 5, 8, 11],   // III, aVF, V3, V6
    ]

    // Width of 1-mV calibration pulse (flat + up + hold + down + flat ≈ 4.5 mm)
    private static let calibrationWidth: CGFloat = pixPerMm * 4.5

    // MARK: - Public

    /// Renders a 12-lead 3×4 ECG to UIImage.
    /// - Parameter scale: pixel multiplier (2.0 → 1584 × 1224 physical px)
    static func render(
        ecgData: [[NSNumber]],
        patient: Patient,
        sampleRate: Int,
        measurements: vhMeasurements?,
        diagnosisLines: [String],
        scale: CGFloat = 2.0
    ) -> UIImage? {
        guard ecgData.count == 12, !ecgData[0].isEmpty, sampleRate > 0 else { return nil }

        let size   = CGSize(width: pageWidth, height: pageHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale  = scale
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let context = ctx.cgContext

            // White background
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            let headerBottom = drawHeader(
                patient: patient,
                measurements: measurements,
                in: CGRect(origin: .zero, size: size),
                context: context
            )

            draw3x4(
                ecgData: ecgData,
                diagnosisLines: diagnosisLines,
                in: CGRect(origin: .zero, size: size),
                topOffset: headerBottom,
                context: context
            )
        }
    }

    // MARK: - Header

    @discardableResult
    private static func drawHeader(
        patient: Patient,
        measurements: vhMeasurements?,
        in rect: CGRect,
        context: CGContext
    ) -> CGFloat {
        var y = margin

        let bodyFont        = UIFont.systemFont(ofSize: 8)
        let boldFont        = UIFont.boldSystemFont(ofSize: 9)
        let unconfirmedFont = UIFont.boldSystemFont(ofSize: 8)
        let bodyAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont]
        let boldAttrs: [NSAttributedString.Key: Any] = [.font: boldFont]
        let grayAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont, .foregroundColor: UIColor.darkGray,
        ]
        let redAttrs: [NSAttributedString.Key: Any] = [
            .font: unconfirmedFont, .foregroundColor: UIColor.red,
        ]

        // Line 1: Patient name (left) — recording date (right)
        (patient.fullName as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: boldAttrs)

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let dateStr  = df.string(from: Date())
        let dateSize = (dateStr as NSString).size(withAttributes: grayAttrs)
        (dateStr as NSString).draw(
            at: CGPoint(x: rect.width - margin - dateSize.width, y: y),
            withAttributes: grayAttrs
        )
        y += 11

        // Line 2: Gender / age / DOB / MRN (left) — "Unconfirmed" (right)
        var details = patient.genderDisplay
        if !patient.age.isEmpty       { details += "  ·  Age: \(patient.age)" }
        if !patient.birthDate.isEmpty { details += "  ·  DOB: \(patient.birthDate)" }
        if let mrn = patient.medicalRecordNumber, !mrn.isEmpty {
            details += "  ·  MRN: \(mrn)"
        }
        (details as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttrs)

        let unconfirmedStr  = "Unconfirmed"
        let unconfirmedSize = (unconfirmedStr as NSString).size(withAttributes: redAttrs)
        (unconfirmedStr as NSString).draw(
            at: CGPoint(x: rect.width - margin - unconfirmedSize.width, y: y),
            withAttributes: redAttrs
        )
        y += 11

        // Line 3: Measurements row
        if let m = measurements?.merge {
            let pairs: [(String, String, String)] = [
                ("HR",   m.hr,      "bpm"),
                ("PR",   m.pr,      "ms"),
                ("QRS",  m.qrs,     "ms"),
                ("QT",   m.qt,      "ms"),
                ("QTc",  m.qTc,     "ms"),
                ("P°",   m.paxis,   "°"),
                ("QRS°", m.qrSaxis, "°"),
            ]
            let mStr = pairs
                .filter { !$0.1.isEmpty && $0.1 != "—" }
                .map    { "\($0.0): \($0.1) \($0.2)" }
                .joined(separator: "  ·  ")
            (mStr as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: bodyAttrs)
            y += 11
        }

        // Separator
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.3)
        context.move(to:    CGPoint(x: margin,              y: y))
        context.addLine(to: CGPoint(x: rect.width - margin, y: y))
        context.strokePath()
        y += 3

        return y
    }

    // MARK: - ECG Grid

    private static func drawGrid(in rect: CGRect, context: CGContext) {
        let small = pixPerMm * 1.0   // 1 mm small box
        let large = pixPerMm * 5.0   // 5 mm large box

        // Small lines — light pink
        context.setStrokeColor(UIColor(red: 1, green: 0.85, blue: 0.85, alpha: 1).cgColor)
        context.setLineWidth(0.2)
        var x = rect.minX
        while x <= rect.maxX {
            context.move(to:    CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += small
        }
        var y = rect.minY
        while y <= rect.maxY {
            context.move(to:    CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += small
        }
        context.strokePath()

        // Large lines — darker pink
        context.setStrokeColor(UIColor(red: 0.94, green: 0.56, blue: 0.56, alpha: 1).cgColor)
        context.setLineWidth(0.5)
        x = rect.minX
        while x <= rect.maxX {
            context.move(to:    CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += large
        }
        y = rect.minY
        while y <= rect.maxY {
            context.move(to:    CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += large
        }
        context.strokePath()
    }

    // MARK: - Calibration Pulse

    private static func drawCalibrationPulse(
        context: CGContext,
        startX: CGFloat,
        baselineY: CGFloat,
        halfRow: CGFloat,
        gainPxPerMV: CGFloat
    ) {
        let flatBefore = pixPerMm * 0.5
        let hold       = pixPerMm * 2.5
        let flatAfter  = pixPerMm * 1.0
        let height     = min(gainPxPerMV, halfRow)

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(0.6)
        context.setLineJoin(.miter)
        context.move(to:    CGPoint(x: startX,                              y: baselineY))
        context.addLine(to: CGPoint(x: startX + flatBefore,                 y: baselineY))
        context.addLine(to: CGPoint(x: startX + flatBefore,                 y: baselineY - height))
        context.addLine(to: CGPoint(x: startX + flatBefore + hold,          y: baselineY - height))
        context.addLine(to: CGPoint(x: startX + flatBefore + hold,          y: baselineY))
        context.addLine(to: CGPoint(x: startX + flatBefore + hold + flatAfter, y: baselineY))
        context.strokePath()
    }

    // MARK: - 3×4 Layout

    private static func draw3x4(
        ecgData: [[NSNumber]],
        diagnosisLines: [String],
        in pageRect: CGRect,
        topOffset: CGFloat,
        context: CGContext
    ) {
        let footerHeight: CGFloat = 16
        let drawableWidth  = pageRect.width  - 2 * margin
        let drawableHeight = pageRect.height - topOffset - footerHeight - margin

        // 3 lead rows + 1 rhythm strip
        let rowHeight = drawableHeight / 4
        // 4 equal time columns after the calibration area
        let colWidth  = (drawableWidth - calibrationWidth) / 4

        let labelFont  = UIFont.boldSystemFont(ofSize: 7)
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: labelFont, .foregroundColor: UIColor.black,
        ]

        // Grid covers full drawable area
        drawGrid(
            in: CGRect(x: margin, y: topOffset, width: drawableWidth, height: drawableHeight),
            context: context
        )

        let gainPxPerMV = pixPerMm * 10.0   // standard ECG gain: 10 mm/mV
        let sampleCount = ecgData[0].count
        let samplesPerCol = sampleCount / 4  // divide recording into 4 equal time windows

        // Compute uniform Y-scale so the tallest waveform fits within its row
        let halfRow       = rowHeight * 0.45
        let standardScale = gainPxPerMV / 1000.0   // µV → px at 10 mm/mV
        var globalMaxAbs: CGFloat = 0
        for lead in ecgData {
            for s in lead {
                let v = abs(CGFloat(s.doubleValue))
                if v > globalMaxAbs { globalMaxAbs = v }
            }
        }
        let yScale: CGFloat
        if globalMaxAbs > 0 && globalMaxAbs * standardScale <= halfRow {
            yScale = standardScale
        } else if globalMaxAbs > 0 {
            yScale = halfRow / globalMaxAbs
        } else {
            yScale = standardScale
        }

        // ── 3 lead rows ──────────────────────────────────────────────────────

        for row in 0..<3 {
            let baselineY = topOffset + (CGFloat(row) + 0.5) * rowHeight

            for col in 0..<4 {
                let leadIndex = leadOrder[row][col]
                let segStart  = col * samplesPerCol
                let segEnd    = min(segStart + samplesPerCol, ecgData[leadIndex].count)
                guard segEnd > segStart else { continue }

                let segment   = Array(ecgData[leadIndex][segStart..<segEnd])
                let cellX     = margin + calibrationWidth + CGFloat(col) * colWidth

                // Calibration pulse only in first column of each row
                if col == 0 {
                    drawCalibrationPulse(
                        context: context,
                        startX: margin,
                        baselineY: baselineY,
                        halfRow: halfRow,
                        gainPxPerMV: gainPxPerMV
                    )
                }

                // Lead label above waveform
                (leadNames[leadIndex] as NSString).draw(
                    at: CGPoint(x: cellX + 2, y: baselineY - halfRow - 1),
                    withAttributes: labelAttrs
                )

                // Stretch segment to fill the column exactly
                let values = segment.map { CGFloat($0.doubleValue) }
                let pps    = colWidth / CGFloat(segment.count)
                let step   = max(1, segment.count / Int(colWidth * 2))

                context.setStrokeColor(UIColor.black.cgColor)
                context.setLineWidth(0.8)
                context.setLineJoin(.round)
                context.move(to: CGPoint(x: cellX, y: baselineY - values[0] * yScale))
                for i in stride(from: step, to: values.count, by: step) {
                    let px = cellX + CGFloat(i) * pps
                    let py = baselineY - values[i] * yScale
                    context.addLine(to: CGPoint(x: px, y: py))
                }
                context.strokePath()
            }
        }

        // ── Rhythm strip — Lead II, full width ───────────────────────────────

        let rhythmBaselineY = topOffset + 3.5 * rowHeight
        let rhythmHalfRow   = rowHeight * 0.45
        let traceStartX     = margin + calibrationWidth
        let traceWidth      = drawableWidth - calibrationWidth

        drawCalibrationPulse(
            context: context,
            startX: margin,
            baselineY: rhythmBaselineY,
            halfRow: rhythmHalfRow,
            gainPxPerMV: gainPxPerMV
        )
        ("II" as NSString).draw(
            at: CGPoint(x: traceStartX + 2, y: rhythmBaselineY - rhythmHalfRow - 1),
            withAttributes: labelAttrs
        )

        let iiValues = ecgData[1].map { CGFloat($0.doubleValue) }
        let iiPps    = traceWidth / CGFloat(sampleCount)
        let iiStep   = max(1, sampleCount / Int(traceWidth * 2))

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(0.8)
        context.setLineJoin(.round)
        context.move(to: CGPoint(x: traceStartX, y: rhythmBaselineY - iiValues[0] * yScale))
        for i in stride(from: iiStep, to: iiValues.count, by: iiStep) {
            let px = traceStartX + CGFloat(i) * iiPps
            let py = rhythmBaselineY - iiValues[i] * yScale
            context.addLine(to: CGPoint(x: px, y: py))
        }
        context.strokePath()

        // ── Footer ────────────────────────────────────────────────────────────

        let footerFont  = UIFont.systemFont(ofSize: 7)
        let footerY     = topOffset + drawableHeight + 4
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: footerFont, .foregroundColor: UIColor.gray,
        ]
        ("25 mm/s  ·  10 mm/mV" as NSString).draw(
            at: CGPoint(x: margin, y: footerY),
            withAttributes: footerAttrs
        )

        if !diagnosisLines.isEmpty {
            let diagText  = "INTERPRETATION: " + diagnosisLines.joined(separator: " · ")
            let diagAttrs: [NSAttributedString.Key: Any] = [
                .font: footerFont, .foregroundColor: UIColor.darkGray,
            ]
            let diagRect = CGRect(
                x: margin + 120,
                y: footerY,
                width: drawableWidth - 120,
                height: footerHeight
            )
            (diagText as NSString).draw(in: diagRect, withAttributes: diagAttrs)
        }
    }
}
