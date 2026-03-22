//
//  EKGRealtimeView.swift
//  EKGx
//
//  UIViewRepresentable wrapper for vhECGRealTimeView.
//  Receives pre-filtered ECG frames from RecordingViewModel and renders them.
//  The VM owns the single onECGData callback — this view is purely a renderer.
//

import SwiftUI
import vhECGTrends

// MARK: - EKGRealtimeView

struct EKGRealtimeView: View {

    let viewModel: RecordingViewModel

    @State private var ecgView = vhECGRealTimeView()

    var body: some View {
        ECGRealTimeRepresentable(ecgView: ecgView, layout: viewModel.selectedLayout)
            .background(Color.black)
            .onChange(of: viewModel.frameCount) { _, _ in
                let frame = viewModel.latestECGFrame
                if frame.isEmpty {
                    ecgView.cleanViewCache()
                } else {
                    ecgView.updateLeads(frame)
                }
            }
            .onChange(of: viewModel.leadStatusCount) { _, _ in
                ecgView.updateLeadsStatus(viewModel.latestLeadStatus)
            }
            .onChange(of: viewModel.selectedLayout) { _, _ in
                ecgView.leadDisplay = viewModel.selectedLayout.sdkType
            }
    }
}

// MARK: - UIViewRepresentable

private struct ECGRealTimeRepresentable: UIViewRepresentable {

    let ecgView: vhECGRealTimeView
    let layout: ECGLeadLayout

    func makeUIView(context: Context) -> vhECGRealTimeView {
        ecgView.background_color              = UIColor(named: "ECGBackground") ?? .black
        ecgView.ecg_line_color                = UIColor(named: "ECGWaveform") ?? .green
        ecgView.ecg_dot_color                 = UIColor(named: "ECGWaveform") ?? .green
        ecgView.lost_line_color               = .systemRed
        ecgView.ecg_line_width                = 1.5
        ecgView.longLead                      = .II
        ecgView.background_board_line_color   = UIColor.systemGray.withAlphaComponent(0.5)
        ecgView.background_board_line_width   = 0.8
        ecgView.background_line_width         = 0.5
        ecgView.background_line_color         = UIColor.systemGray.withAlphaComponent(0.35)
        ecgView.background_weak_line_width    = 0.5
        ecgView.background_weak_line_color    = UIColor.systemGray.withAlphaComponent(0.2)
        ecgView.paperSpeed                    = .normal
        ecgView.sensitivity                   = .normal
        ecgView.standard_text_color           = UIColor(named: "BrandPrimary") ?? .systemBlue
        ecgView.pix_per_mm                    = 7.5
        ecgView.standard_style                = .hidden
        ecgView.leadDisplay                   = layout.sdkType
        ecgView.layer.cornerRadius            = 0
        ecgView.layer.masksToBounds           = true
        return ecgView
    }

    func updateUIView(_ uiView: vhECGRealTimeView, context: Context) {
        if uiView.leadDisplay != layout.sdkType {
            uiView.leadDisplay = layout.sdkType
        }
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
