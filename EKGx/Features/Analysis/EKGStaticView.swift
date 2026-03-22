//
//  EKGStaticView.swift
//  EKGx
//
//  Static 12-lead ECG rendered using ECGDrawLinePath (SwiftUI Shape) on top of
//  EcgBackgroundView (vhECGRealTimeView used only as paper-grid background).
//  Matches the Alma reference project approach exactly.
//
//  Standard 3×4 layout:
//    Col 0   Col 1   Col 2   Col 3
//    I       aVR     V1      V4
//    II      aVL     V2      V5
//    III     aVF     V3      V6
//

import SwiftUI
import vhECGTrends

// MARK: - ECGLineModel

struct ECGLineModel {
    var rate: CGFloat     = 660
    var pixPermm: CGFloat = 5.5
    var xSpeed: CGFloat   = 25    // mm/s
    var yRate: CGFloat    = 10    // mm/mV  (5 / 10 / 20)
}

// MARK: - ECGDrawLinePath

struct ECGDrawLinePath: Shape {

    let ecgArray: [NSNumber]
    let model: ECGLineModel
    var showStandard: Bool = false
    var startIndex: Int = 0
    var widthLimit: CGFloat? = nil
    var fullScreen: Bool = false   // stretch beat to fill full width (layers mode)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let yMiddle   = rect.height / 2
        let xPerPoint = fullScreen
            ? rect.width / CGFloat(ecgArray.count)
            : model.pixPermm * model.xSpeed / model.rate
        var currentX: CGFloat = 0

        path.move(to: CGPoint(x: currentX, y: yMiddle))

        // 1 mV calibration pulse (only in non-fullScreen mode)
        if showStandard && !fullScreen {
            currentX += 1.5 * model.pixPermm
            path.addLine(to: CGPoint(x: currentX, y: yMiddle))
            path.addLine(to: CGPoint(x: currentX, y: yMiddle - model.yRate * model.pixPermm))
            currentX += 3 * model.pixPermm
            path.addLine(to: CGPoint(x: currentX, y: yMiddle - model.yRate * model.pixPermm))
            path.addLine(to: CGPoint(x: currentX, y: yMiddle))
            currentX += 1.5 * model.pixPermm
            path.addLine(to: CGPoint(x: currentX, y: yMiddle))
        }

        for i in startIndex..<ecgArray.count {
            let sample = CGFloat(ecgArray[i].floatValue)
            let yRate  = fullScreen ? CGFloat(15) : model.yRate
            let ySeek  = model.pixPermm * sample * yRate / 1000.0
            path.addLine(to: CGPoint(x: currentX, y: yMiddle - ySeek))
            currentX += xPerPoint
            if let limit = widthLimit, currentX >= limit { break }
        }

        return path
    }
}

// MARK: - EcgBackgroundView

/// vhECGRealTimeView as paper grid only — no ECG data is fed into it.
struct EcgBackgroundView: UIViewRepresentable {

    var showSmallLines: Bool = true
    var pixPerMm: Float = 5.5

    func makeUIView(context: Context) -> vhECGRealTimeView {
        let v = vhECGRealTimeView()
        v.background_color           = .white
        v.ecg_line_color             = .green
        v.ecg_line_width             = 1.62
        v.longLead                   = .II
        v.background_line_width      = 0.6
        v.background_line_color      = UIColor(red: 1, green: 0, blue: 0, alpha: 0.7)
        v.background_weak_line_color = showSmallLines
            ? UIColor(red: 1, green: 0, blue: 0, alpha: 0.7) : .clear
        v.paperSpeed                 = .normal
        v.sensitivity                = .normal
        v.standard_text_color        = .clear
        v.pix_per_mm                 = Double(pixPerMm)
        v.standard_style             = .hidden
        return v
    }

    func updateUIView(_ uiView: vhECGRealTimeView, context: Context) {}
}

// MARK: - ECGGridLine

struct ECGGridLine: View {

    let leadName: String
    let samples: [NSNumber]
    let height: CGFloat
    var width: CGFloat? = nil
    var showStandard: Bool = false
    var startIndex: Int = 0
    var lineModel: ECGLineModel

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ECGDrawLinePath(
                ecgArray: samples,
                model: lineModel,
                showStandard: showStandard,
                startIndex: startIndex,
                widthLimit: width
            )
            .stroke(Color.black, lineWidth: 1)

            Text(leadName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.black)
                .padding(.leading, 4)
                .padding(.bottom, 4)
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

// MARK: - ECGLayersView

/// Layers / merged beat view with 6 draggable measurement markers.
/// - Top strip: small beats for all 12 leads + merged, tap to select
/// - Main area: selected beat stretched full width, with drag handles
/// - Right panel: live measurements (HR, PR, QRS, QT, QTc, axes)
struct ECGLayersView: View {

    @Bindable var viewModel: AnalysisViewModel

    private let leadNames = ["I","II","III","aVR","aVL","aVF","V1","V2","V3","V4","V5","V6"]
    private let leadColors: [Color] = [
        .black, .blue, .red, .green, .orange, .purple,
        .cyan, .brown, .indigo, .mint, .pink, .teal
    ]

    // -1 means "merged" (all leads overlaid)
    @State private var selectedLeadIndex: Int = -1

    var body: some View {
        VStack(spacing: 0) {
            // ── Top strip: scrollable thumbnail row ──────────────────────
            leadStripHeader

            Divider()

            // ── Main area ────────────────────────────────────────────────
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Beat + drag handles
                    beatCanvas(geo: geo)

                    // Measurements sidebar
                    measurementsSidebar
                        .frame(width: 90)
                }
            }
        }
        .background(Color.white)
    }

    // MARK: - Top Lead Strip

    private var leadStripHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Merged thumbnail
                stripThumbnail(label: "MERGED", index: -1)

                Divider().frame(height: 40)

                // Individual lead thumbnails
                ForEach(0..<min(viewModel.templateData.count, 12), id: \.self) { i in
                    stripThumbnail(label: leadNames[i], index: i)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(height: 68)
        .background(Color(UIColor.systemGray6))
    }

    private func stripThumbnail(label: String, index: Int) -> some View {
        let isSelected = selectedLeadIndex == index
        let color: Color = index == -1 ? .black : leadColors[index]

        return VStack(spacing: 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 60, height: 44)

                if index == -1 {
                    ZStack {
                        ForEach(0..<min(viewModel.templateData.count, 12), id: \.self) { i in
                            ECGDrawLinePath(
                                ecgArray: viewModel.templateData[i],
                                model: ECGLineModel(rate: 660, pixPermm: 0.3, xSpeed: 25, yRate: 12),
                                fullScreen: true
                            )
                            .stroke(leadColors[i].opacity(0.6), lineWidth: 0.8)
                        }
                    }
                    .frame(width: 56, height: 40)
                    .clipped()
                } else if index < viewModel.templateData.count {
                    ECGDrawLinePath(
                        ecgArray: viewModel.templateData[index],
                        model: ECGLineModel(rate: 660, pixPermm: 0.3, xSpeed: 25, yRate: 12),
                        fullScreen: true
                    )
                    .stroke(color, lineWidth: 1)
                    .frame(width: 56, height: 40)
                    .clipped()
                }
            }
            .frame(width: 60, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? AppColors.brandPrimary : Color.clear, lineWidth: 1.5)
            )

            Text(label)
                .font(.system(size: 9, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? AppColors.brandPrimary : Color.secondary)
        }
        .onTapGesture { selectedLeadIndex = index }
    }

    // MARK: - Beat Canvas

    private func beatCanvas(geo: GeometryProxy) -> some View {
        let canvasWidth = geo.size.width - 90
        let canvasHeight = geo.size.height

        return ZStack(alignment: .topLeading) {
            // Grid background
            EcgBackgroundView(showSmallLines: true, pixPerMm: 5.5)
                .frame(width: canvasWidth, height: canvasHeight)

            // Beat lines
            if selectedLeadIndex == -1 {
                // All leads merged
                ForEach(0..<min(viewModel.templateData.count, 12), id: \.self) { i in
                    ECGDrawLinePath(
                        ecgArray: viewModel.templateData[i],
                        model: ECGLineModel(),
                        fullScreen: true
                    )
                    .stroke(leadColors[i].opacity(0.75), lineWidth: 1.5)
                    .frame(width: canvasWidth, height: canvasHeight)
                }
            } else if selectedLeadIndex < viewModel.templateData.count {
                ECGDrawLinePath(
                    ecgArray: viewModel.templateData[selectedLeadIndex],
                    model: ECGLineModel(),
                    fullScreen: true
                )
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: canvasWidth, height: canvasHeight)
            }

            // Drag handles — always reads live templateAnalysisResult from analysis object
            if viewModel.analysis != nil {
                DragHandlesOverlay(
                    viewModel: viewModel,
                    selectedLeadIndex: selectedLeadIndex,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight
                )
            }
        }
        .frame(width: canvasWidth, height: canvasHeight)
        .clipped()
    }

    // MARK: - Measurements Sidebar

    private var measurementsSidebar: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                sidebarItem("HR",   viewModel.mergeHR,      "bpm")
                sidebarItem("PR",   viewModel.mergePR,      "ms")
                sidebarItem("QRS",  viewModel.mergeQRS,     "ms")
                sidebarItem("QT",   viewModel.mergeQT,      "ms")
                sidebarItem("QTc",  viewModel.mergeQTc,     "ms")
                sidebarItem("P°",   viewModel.mergePaxis,   "°")
                sidebarItem("QRS°", viewModel.mergeQRSaxis, "°")
                sidebarItem("T°",   viewModel.mergeTaxis,   "°")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .overlay(Rectangle().fill(Color(UIColor.systemGray4)).frame(width: 1), alignment: .leading)
    }

    private func sidebarItem(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.gray)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Beat Point Type

private enum BeatPointType: CaseIterable {
    case pb, pe, qrsb, qrse, tb, te

    var label: String {
        switch self {
        case .pb: return "Pb"; case .pe: return "Pe"
        case .qrsb: return "Qb"; case .qrse: return "Qe"
        case .tb: return "Tb"; case .te: return "Te"
        }
    }
    var color: Color {
        switch self {
        case .pb, .pe: return .blue
        case .qrsb, .qrse: return .red
        case .tb, .te: return .green
        }
    }

    func readFrom(merged ta: vhTemplateAnalysis) -> Int {
        switch self {
        case .pb: return Int(ta.pb); case .pe: return Int(ta.pe)
        case .qrsb: return Int(ta.qrSb); case .qrse: return Int(ta.qrSe)
        case .tb: return Int(ta.tb); case .te: return Int(ta.te)
        }
    }
    func readFrom(lead: vhLeadTemplate) -> Int {
        switch self {
        case .pb: return Int(lead.pb); case .pe: return Int(lead.pe)
        case .qrsb: return Int(lead.qrSb); case .qrse: return Int(lead.qrSe)
        case .tb: return Int(lead.tb); case .te: return Int(lead.te)
        }
    }
    func write(to ta: vhTemplateAnalysis, value: Int) {
        let v = UInt(max(0, value))
        switch self {
        case .pb: ta.pb = v; case .pe: ta.pe = v
        case .qrsb: ta.qrSb = v; case .qrse: ta.qrSe = v
        case .tb: ta.tb = v; case .te: ta.te = v
        }
    }
    func write(to lead: vhLeadTemplate, value: Int) {
        let v = UInt(max(0, value))
        switch self {
        case .pb: lead.pb = v; case .pe: lead.pe = v
        case .qrsb: lead.qrSb = v; case .qrse: lead.qrSe = v
        case .tb: lead.tb = v; case .te: lead.te = v
        }
    }
}

// MARK: - Drag Handles Overlay

private struct DragHandlesOverlay: View {

    var viewModel: AnalysisViewModel
    let selectedLeadIndex: Int
    let canvasWidth: CGFloat
    let canvasHeight: CGFloat

    // Always read live from the analysis object — SDK may replace templateAnalysisResult after re-analysis
    private var liveTA: vhTemplateAnalysis? { viewModel.analysis?.templateAnalysisResult }

    var body: some View {
        guard let ta = liveTA else { return AnyView(EmptyView()) }
        let beatCount = beatSampleCount
        if beatCount == 0 { return AnyView(EmptyView()) }
        let xPerSample = canvasWidth / CGFloat(beatCount)
        let ecgArray = activeEcgArray

        return AnyView(
            ZStack {
                ForEach(BeatPointType.allCases, id: \.label) { pt in
                    let sampleIdx = currentSampleIndex(for: pt, ta: ta)
                    let xPos = CGFloat(sampleIdx) * xPerSample
                    let safeIdx = min(sampleIdx, max(0, ecgArray.count - 1))
                    let yPos: CGFloat = ecgArray.isEmpty ? canvasHeight / 2 : {
                        let sample = CGFloat(ecgArray[safeIdx].floatValue)
                        let ySeek = 5.5 * sample * 15.0 / 1000.0
                        return canvasHeight / 2 - ySeek
                    }()
                    PointHandleView(
                        ecgArray: ecgArray,
                        canvasWidth: canvasWidth,
                        canvasHeight: canvasHeight,
                        xPerSample: xPerSample,
                        sampleCount: beatCount,
                        isMerged: selectedLeadIndex == -1,
                        onChanged: { newSample in writeSample(newSample, for: pt) },
                        onEnded: { refreshMeasurements() },
                        location: CGPoint(x: xPos, y: yPos)
                    )
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)
        )
    }

    // ECG array used for Y-snapping: use lead 0 for merged (representative), or selected lead
    private var activeEcgArray: [NSNumber] {
        if selectedLeadIndex == -1 {
            return viewModel.templateData.first ?? []
        } else if selectedLeadIndex < viewModel.templateData.count {
            return viewModel.templateData[selectedLeadIndex]
        }
        return []
    }

    private var beatSampleCount: Int {
        if selectedLeadIndex == -1 {
            return viewModel.templateData.first?.count ?? 0
        } else if selectedLeadIndex < viewModel.templateData.count {
            return viewModel.templateData[selectedLeadIndex].count
        }
        return 0
    }

    private func currentSampleIndex(for pt: BeatPointType, ta: vhTemplateAnalysis) -> Int {
        if selectedLeadIndex == -1 {
            return pt.readFrom(merged: ta)
        }
        guard let leads = ta.leadsTemplateAnalisysArray(),
              selectedLeadIndex < leads.count else {
            return pt.readFrom(merged: ta)
        }
        return pt.readFrom(lead: leads[selectedLeadIndex])
    }

    private func writeSample(_ sample: Int, for pt: BeatPointType) {
        guard let ta = liveTA else { return }
        if selectedLeadIndex == -1 {
            pt.write(to: ta, value: sample)
        } else {
            guard let leads = ta.leadsTemplateAnalisysArray(),
                  selectedLeadIndex < leads.count else { return }
            pt.write(to: leads[selectedLeadIndex], value: sample)
        }
    }

    private func refreshMeasurements() {
        guard let ta = liveTA else { return }
        if selectedLeadIndex == -1 {
            viewModel.reanalyseAllLeads()
        } else {
            guard let leads = ta.leadsTemplateAnalisysArray(),
                  selectedLeadIndex < leads.count else { return }
            viewModel.reanalyseLead(leads[selectedLeadIndex])
        }
    }
}

// MARK: - PointHandleView

private struct PointHandleView: View {

    let ecgArray: [NSNumber]       // waveform samples (for Y snapping)
    let canvasWidth: CGFloat
    let canvasHeight: CGFloat
    let xPerSample: CGFloat        // canvasWidth / sampleCount
    let sampleCount: Int
    let isMerged: Bool             // merged = show line; per-lead = dot only
    let onChanged: (Int) -> Void
    let onEnded: () -> Void

    // Current position on screen — starts at initial waveform position
    @State var location: CGPoint
    @GestureState private var startLocation: CGPoint? = nil

    var body: some View {
        let drag = DragGesture()
            .onChanged { value in
                var newLoc = startLocation ?? location
                newLoc.x += value.translation.width
                // Clamp x to canvas bounds
                newLoc.x = max(0, min(canvasWidth, newLoc.x))
                // Snap y to waveform value at this x
                newLoc.y = waveformY(at: newLoc.x)
                location = newLoc
                let sample = clampedSample(x: newLoc.x)
                onChanged(sample)
            }
            .onEnded { _ in
                let sample = clampedSample(x: location.x)
                onChanged(sample)
                onEnded()
            }
            .updating($startLocation) { _, startLocation, _ in
                startLocation = startLocation ?? location
            }

        ZStack {
            // Vertical line + arrow — centered on x, vertically centered
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                Spacer()
                Rectangle()
                    .fill(Color.blue.opacity(isMerged ? 0.7 : 0))
                    .frame(width: 1.5, height: 200)
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(Color.blue)
                    .frame(width: 25, height: 25)
                    .padding(3)
            }
            .contentShape(Rectangle())
            .position(x: location.x, y: canvasHeight / 2)

            // Blue dot snapped to waveform
            Circle()
                .fill(Color.blue)
                .frame(width: 10, height: 10)
                .position(location)
        }
        .gesture(drag)
    }

    private func waveformY(at x: CGFloat) -> CGFloat {
        let idx = clampedSample(x: x)
        let sample = CGFloat(ecgArray[idx].floatValue)
        let ySeek = 5.5 * sample * 15.0 / 1000.0   // pixPermm=5.5, yRate=15 (fullScreen)
        return canvasHeight / 2 - ySeek
    }

    private func clampedSample(x: CGFloat) -> Int {
        let s = Int(x / xPerSample)
        return max(0, min(sampleCount - 1, s))
    }
}

// MARK: - EKGStaticView

/// Standard 3-row × 4-column 12-lead ECG display.
///
/// Lead order (row-major, matching clinical standard):
///   Row 0: I, aVR, V1, V4
///   Row 1: II, aVL, V2, V5
///   Row 2: III, aVF, V3, V6
struct EKGStaticView: View {

    let templateData: ECGLeads   // beat template — repeated to fill each grid cell
    let fullData: ECGLeads       // full recording — long lead row
    let sampleRate: Int

    private let leadNames = ["I","II","III","aVR","aVL","aVF","V1","V2","V3","V4","V5","V6"]
    private let leadOrder: [[Int]] = [
        [0, 3, 6,  9],
        [1, 4, 7, 10],
        [2, 5, 8, 11],
    ]
    private let numRows = 3
    private let numCols = 4
    private let longLeadIndex = 1   // Lead II

    @State private var lineModel = ECGLineModel()
    @State private var yRate: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let longLeadHeight = geo.size.height * 0.20
            let gridHeight     = geo.size.height - longLeadHeight
            let cellWidth      = geo.size.width  / CGFloat(numCols)
            let cellHeight     = gridHeight / CGFloat(numRows)
            let xPerPoint      = lineModel.pixPermm * lineModel.xSpeed / lineModel.rate
            let longLeadWidth  = max(CGFloat(fullData.first?.count ?? 0) * xPerPoint, geo.size.width)

            ZStack(alignment: .topLeading) {
                EcgBackgroundView(showSmallLines: true, pixPerMm: Float(lineModel.pixPermm))

                if templateData.count >= 12 && fullData.count >= 12 {
                    VStack(spacing: 0) {
                        // 3×4 grid — use full recording data, offset per column
                        ForEach(0..<numRows, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<numCols, id: \.self) { col in
                                    let leadIndex   = leadOrder[row][col]
                                    let samples     = fullData[leadIndex]
                                    let samplesPerCell = Int(cellWidth / xPerPoint)
                                    let startIdx    = min(col * samplesPerCell, max(0, samples.count - 1))

                                    ECGGridLine(
                                        leadName: leadNames[leadIndex],
                                        samples: samples,
                                        height: cellHeight,
                                        width: cellWidth,
                                        showStandard: col == 0,
                                        startIndex: startIdx,
                                        lineModel: lineModel
                                    )
                                }
                            }
                        }

                        // Long lead row — full Lead II, horizontally scrollable
                        ScrollView(.horizontal, showsIndicators: true) {
                            ZStack(alignment: .topLeading) {
                                EcgBackgroundView(showSmallLines: true, pixPerMm: Float(lineModel.pixPermm))
                                    .frame(width: longLeadWidth, height: longLeadHeight)

                                ECGGridLine(
                                    leadName: "II",
                                    samples: fullData[longLeadIndex],
                                    height: longLeadHeight,
                                    width: longLeadWidth,
                                    showStandard: true,
                                    startIndex: 0,
                                    lineModel: lineModel
                                )
                            }
                            .frame(width: longLeadWidth, height: longLeadHeight)
                        }
                        .frame(height: longLeadHeight)
                    }
                }

                // Scale label
                VStack {
                    Spacer()
                    HStack {
                        Text("25 mm/s  ·  \(Int(yRate)) mm/mV")
                            .font(.system(size: 9))
                            .foregroundColor(.black.opacity(0.6))
                            .padding(6)
                        Spacer()
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { cycleYRate() }
        }
        .onChange(of: yRate) { _, v in lineModel.yRate = v }
    }

    private func cycleYRate() {
        yRate = yRate == 10 ? 20 : yRate == 20 ? 5 : 10
    }
}
