//
//  EKGRealtimeView.swift
//  EKGx
//
//  Hosts the real-time ECG renderer.
//  Toggle `useCustomRenderer` to switch between the custom Canvas renderer
//  (zero SDK dependency, full grid control) and the SDK's vhECGRealTimeView.
//

import SwiftUI
import vhECGTrends

// MARK: - Renderer Switch

struct EKGRealtimeView: View {

    // ─────────────────────────────────────────────────────────────────────────
    // Set to false to fall back to the vhECGTrends SDK renderer.
    static let useCustomRenderer = true
    // ─────────────────────────────────────────────────────────────────────────

    let viewModel: RecordingViewModel

    var body: some View {
        if 	Self.useCustomRenderer {
            CustomECGRenderer(viewModel: viewModel)
        } else {
            SDKECGRenderer(viewModel: viewModel)
        }
    }
}

// MARK: - Custom Renderer

private struct CustomECGRenderer: View {

    let viewModel: RecordingViewModel
    @State private var canvas = EKGCanvasView()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let isCompact = sizeClass == .compact
        return CanvasRepresentable(canvas: canvas, layout: viewModel.selectedLayout, isCompact: isCompact)
            .onChange(of: viewModel.frameCount) { _, _ in
                let frame = viewModel.latestECGFrame
                if frame.isEmpty {
                    canvas.cleanViewCache()
                } else {
                    canvas.updateLeads(frame)
                }
            }
            .onChange(of: viewModel.leadStatusCount) { _, _ in
                canvas.updateLeadsStatus(viewModel.latestLeadStatus)
            }
            .onChange(of: viewModel.selectedLayout) { _, layout in
                canvas.leadLayout = layout
            }
    }
}

private struct CanvasRepresentable: UIViewRepresentable {

    let canvas: EKGCanvasView
    let layout: ECGLeadLayout
    let isCompact: Bool

    func makeUIView(context: Context) -> EKGCanvasView {
        canvas.backgroundColor         = UIColor(named: "ECGBackground") ?? .black
        canvas.waveformColor           = UIColor(named: "ECGWaveform") ?? .green
        canvas.lostLeadColor           = .systemRed
        canvas.waveformLineWidth       = 1.62
        canvas.paperSpeedMmPerSec      = 25
        canvas.sensitivityMmPerMv      = 10
        canvas.pixPerMm                = 6.2
        canvas.sampleRate              = 660
        canvas.majorGridColor          = UIColor.systemGray.withAlphaComponent(0.5)
        canvas.majorGridWidth          = 0.9
        canvas.minorGridColor          = UIColor.systemGray.withAlphaComponent(0.2)
        canvas.minorGridWidth          = 0.5
        canvas.labelColor              = UIColor.white.withAlphaComponent(0.8)
        canvas.leadLayout              = layout
        canvas.isCompactLayout         = isCompact
        canvas.layer.cornerRadius      = 0
        canvas.layer.masksToBounds     = true
        canvas.startRendering()
        return canvas
    }

    func updateUIView(_ uiView: EKGCanvasView, context: Context) {
        if uiView.leadLayout != layout { uiView.leadLayout = layout }
        if uiView.isCompactLayout != isCompact { uiView.isCompactLayout = isCompact }
    }

    static func dismantleUIView(_ uiView: EKGCanvasView, coordinator: ()) {
        uiView.stopRendering()
    }
}

// MARK: - SDK Renderer

private struct SDKECGRenderer: View {

    let viewModel: RecordingViewModel
    @State private var sdkView = vhECGRealTimeView()

    var body: some View {
        SDKRepresentable(sdkView: sdkView, layout: viewModel.selectedLayout)
            .onChange(of: viewModel.frameCount) { _, _ in
                let frame = viewModel.latestECGFrame
                if frame.isEmpty {
                    sdkView.cleanViewCache()
                } else {
                    sdkView.updateLeads(frame)
                }
            }
            .onChange(of: viewModel.leadStatusCount) { _, _ in
                sdkView.updateLeadsStatus(viewModel.latestLeadStatus)
            }
            .onChange(of: viewModel.selectedLayout) { _, _ in
                sdkView.leadDisplay = viewModel.selectedLayout.sdkType
            }
    }
}

private struct SDKRepresentable: UIViewRepresentable {

    let sdkView: vhECGRealTimeView
    let layout: ECGLeadLayout

    func makeUIView(context: Context) -> vhECGRealTimeView {
        sdkView.background_color              = UIColor(named: "ECGBackground") ?? .black
        sdkView.ecg_line_color                = UIColor(named: "ECGWaveform") ?? .green
        sdkView.ecg_dot_color                 = UIColor(named: "ECGWaveform") ?? .green
        sdkView.lost_line_color               = .systemRed
        sdkView.ecg_line_width                = 1.62
        sdkView.longLead                      = .II
        sdkView.background_board_line_color   = UIColor.systemGray.withAlphaComponent(0.5)
        sdkView.background_board_line_width   = 0.9
        sdkView.background_line_width         = 0.5
        sdkView.background_line_color         = UIColor.systemGray.withAlphaComponent(0.35)
        sdkView.background_weak_line_width    = 0.5
        sdkView.background_weak_line_color    = UIColor.systemGray.withAlphaComponent(0.2)
        sdkView.paperSpeed                    = .normal
        sdkView.sensitivity                   = .normal
        sdkView.standard_text_color           = UIColor.white.withAlphaComponent(0.8)
        sdkView.pix_per_mm                    = 6.2
        sdkView.standard_style                = .hidden
        sdkView.leadDisplay                   = layout.sdkType
        sdkView.layer.cornerRadius            = 0
        sdkView.layer.masksToBounds           = true
        return sdkView
    }

    func updateUIView(_ uiView: vhECGRealTimeView, context: Context) {
        if uiView.leadDisplay != layout.sdkType { uiView.leadDisplay = layout.sdkType }
    }
}

// MARK: - ECGLeadLayout → SDK type

extension ECGLeadLayout {
    var sdkType: vhEcgLeadDisplayType {
        switch self {
        case .threeByFour:  return .lead_3x4
        case .sixByTwo:     return .lead_6x2
        case .twelveByOne:  return .lead_12x1
        }
    }
}
