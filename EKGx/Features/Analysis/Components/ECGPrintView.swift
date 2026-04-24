//
//  ECGPrintView.swift
//  EKGx
//
//  A4-style printable layout: header with patient info + measurements,
//  full 12-lead ECG grid, diagnosis footer.
//  Rendered via ImageRenderer then sent to UIPrintInteractionController.
//

import SwiftUI

// MARK: - ECGPrintView

/// A fixed-size (1024 × 768 pt) landscape layout used for printing.
struct ECGPrintView: View {

    let patient: Patient
    let templateData: ECGLeads
    let ecgData: ECGLeads
    let sampleRate: Int
    let measurements: vhMeasurements?
    let diagnosisLines: [String]

    var body: some View {
        VStack(spacing: 0) {
            printHeader
            Divider()
            // ECG grid — fills remaining space
            EKGStaticView(
                templateData: templateData,
                fullData: ecgData,
                sampleRate: sampleRate
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            printFooter
        }
        .background(Color.white)
        .frame(width: 1024, height: 768)
        .preferredColorScheme(.light)
    }

    // MARK: - Header

    private var printHeader: some View {
        HStack(alignment: .center, spacing: 0) {
            // Patient block
            VStack(alignment: .leading, spacing: 3) {
                Text(patient.fullName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                HStack(spacing: 8) {
                    Text(patient.age)
                    Text("·")
                    Text(patient.genderDisplay)
                    if !patient.birthDate.isEmpty {
                        Text("·")
                        Text(formattedDob(patient.birthDate))
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(Color(UIColor.darkGray))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)

            Divider().frame(height: 36)

            // Measurements
            if let m = measurements?.merge {
                HStack(spacing: 16) {
                    measureItem("HR",   m.hr,     "bpm")
                    measureItem("PR",   m.pr,     "ms")
                    measureItem("QRS",  m.qrs,    "ms")
                    measureItem("QT",   m.qt,     "ms")
                    measureItem("QTc",  m.qTc,    "ms")
                    measureItem("P°",   m.paxis,  "°")
                    measureItem("QRS°", m.qrSaxis,"°")
                }
                .padding(.horizontal, 20)
            }

            Divider().frame(height: 36)

            // Brand + date
            VStack(alignment: .trailing, spacing: 3) {
                AppImages.logo
                    .resizable()
                    .scaledToFit()
                    .frame(height: 16)
                Text(printDate)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(UIColor.darkGray))
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 56)
        .background(Color(UIColor.systemGray6))
    }

    // MARK: - Footer

    private var printFooter: some View {
        HStack {
            Text("INTERPRETATION: " + (diagnosisLines.isEmpty ? "—" : diagnosisLines.joined(separator: " · ")))
                .font(.system(size: 10))
                .foregroundStyle(Color(UIColor.darkGray))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
        .frame(height: 30)
        .background(Color(UIColor.systemGray6))
    }

    // MARK: - Helpers

    private func measureItem(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(Color.gray)
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 8))
                    .foregroundStyle(Color.gray)
            }
        }
    }

    private var printDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: Date())
    }

    private func formattedDob(_ raw: String) -> String {
        let parsers = ["yyyy-MM-dd", "MM/dd/yyyy"]
        let out = DateFormatter()
        out.dateFormat = "M/d/yyyy"
        for fmt in parsers {
            let df = DateFormatter(); df.dateFormat = fmt
            if let d = df.date(from: raw) { return out.string(from: d) }
        }
        return raw
    }
}

// MARK: - Print Helper

@MainActor
func printECG(
    patient: Patient,
    templateData: ECGLeads,
    ecgData: ECGLeads,
    sampleRate: Int,
    measurements: vhMeasurements?,
    diagnosisLines: [String]
) {
    let printView = ECGPrintView(
        patient: patient,
        templateData: templateData,
        ecgData: ecgData,
        sampleRate: sampleRate,
        measurements: measurements,
        diagnosisLines: diagnosisLines
    )

    let renderer = ImageRenderer(content: printView)
    renderer.scale = 2.0
    renderer.proposedSize = .init(width: 1024, height: 768)

    guard let uiImage = renderer.uiImage else { return }

    let printInfo = UIPrintInfo(dictionary: nil)
    printInfo.jobName = "ECG – \(patient.fullName)"
    printInfo.outputType = .grayscale
    printInfo.orientation = .landscape

    let controller = UIPrintInteractionController.shared
    controller.printInfo = printInfo
    controller.printingItem = uiImage

    controller.present(animated: true)
}
