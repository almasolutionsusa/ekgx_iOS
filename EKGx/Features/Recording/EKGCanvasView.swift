import UIKit

// MARK: - Panel Descriptor

private struct PanelDescriptor {
    let leadIndex: Int
    let label: String
    let frame: CGRect
    let isLong: Bool
}

// MARK: - Panel State
// Owned exclusively by renderQueue — no synchronisation needed.

private final class PanelState {

    let leadIndex: Int
    let pixelWidth: Int
    let panelHeight: CGFloat

    var yBuffer: [Float]    // ring buffer: col → Y offset in px (positive = upward)
    var writeCol = 0
    var pxFrac = 0.0
    var initialized = false

    init(leadIndex: Int, frame: CGRect) {
        self.leadIndex = leadIndex
        self.pixelWidth = max(1, Int(frame.width))
        self.panelHeight = frame.height
        self.yBuffer = [Float](repeating: 0, count: max(1, Int(frame.width)))
    }

    func reset() {
        for i in yBuffer.indices { yBuffer[i] = 0 }
        writeCol = 0
        pxFrac = 0
        initialized = false
    }
}

// MARK: - EKGCanvasView

final class EKGCanvasView: UIView {

    // MARK: Public configuration

    var leadLayout: ECGLeadLayout = .threeByFour {
        didSet { if oldValue != leadLayout { setNeedsRebuild() } }
    }

    var isCompactLayout: Bool = false {
        didSet { if oldValue != isCompactLayout { setNeedsRebuild() } }
    }

    var paperSpeedMmPerSec: CGFloat = 25   // 25 or 50 mm/s
    var sensitivityMmPerMv: CGFloat = 10  // 5, 10, or 20 mm/mV
    var pixPerMm: CGFloat = 6.2
    var sampleRate: Double = 660

    override var backgroundColor: UIColor? {
        didSet { setNeedsRebuild() }
    }

    var waveformColor: UIColor = UIColor(named: "ECGWaveform") ?? .green {
        didSet { applyWaveformColor() }
    }
    var lostLeadColor: UIColor = .systemRed
    var waveformLineWidth: CGFloat = 1.62 {
        didSet { applyWaveformColor() }
    }
    var labelColor: UIColor = UIColor.white.withAlphaComponent(0.8) {
        didSet { applyLabelColor() }
    }
    var majorGridColor: UIColor = UIColor.systemGray.withAlphaComponent(0.5) { didSet { setNeedsRebuild() } }
    var minorGridColor: UIColor = UIColor.systemGray.withAlphaComponent(0.2) { didSet { setNeedsRebuild() } }
    var majorGridWidth: CGFloat = 0.9
    var minorGridWidth: CGFloat = 0.5

    // MARK: Private — layer tree (main thread only)

    private var gridLayers: [CALayer] = []
    private var waveformLayers: [CAShapeLayer] = []
    private var borderLayers: [CAShapeLayer] = []
    private var dotLayers: [CALayer] = []
    private var labelLayers: [CATextLayer] = []

    // MARK: Private — rendering

    private let sampleQueue = EKGSampleQueue()
    private let renderQueue = DispatchQueue(label: "ekgx.canvas.render", qos: .userInteractive)

    // panelStates is owned exclusively by renderQueue.
    private var panelStates: [PanelState] = []

    private var displayLink: CADisplayLink?
    private var previousTimestamp: CFTimeInterval = 0

    // Lead status — written on any thread, read on renderQueue via snapshot.
    private var statusLock = os_unfair_lock()
    private var _leadStatus: [Bool] = Array(repeating: true, count: EKGSampleQueue.leadCount)

    // Prevent redundant layout passes when bounds haven't changed.
    private var lastBuiltSize: CGSize = .zero

    private static let eraserPx = 10
    private static let dotSize: CGFloat = 5
    private static let leadNames = ["I","II","III","aVR","aVL","aVF","V1","V2","V3","V4","V5","V6"]

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

    deinit { stopRendering() }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !bounds.isEmpty, bounds.size != lastBuiltSize else { return }
        lastBuiltSize = bounds.size
        rebuildLayout()
    }

    // MARK: Public API

    func startRendering() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stopRendering() {
        displayLink?.invalidate()
        displayLink = nil
        previousTimestamp = 0
    }

    func updateLeads(_ frame: [[Int16]]) {
        sampleQueue.enqueue(frame)
    }

    func updateLeadsStatus(_ status: [Bool]) {
        os_unfair_lock_lock(&statusLock)
        _leadStatus = status
        os_unfair_lock_unlock(&statusLock)
    }

    func cleanViewCache() {
        sampleQueue.reset()
        renderQueue.async { [weak self] in
            self?.panelStates.forEach { $0.reset() }
        }
    }

    // MARK: Private — layout rebuild (main thread)

    private func setNeedsRebuild() {
        lastBuiltSize = .zero
        setNeedsLayout()
    }

    private func rebuildLayout() {
        // Tear down existing layers.
        (gridLayers + waveformLayers + borderLayers + dotLayers).forEach { $0.removeFromSuperlayer() }
        gridLayers.removeAll(); waveformLayers.removeAll()
        borderLayers.removeAll(); dotLayers.removeAll(); labelLayers.removeAll()

        let descs = Self.computePanels(in: bounds, layout: leadLayout, isCompact: isCompactLayout)
        let scale = window?.screen.scale ?? UIScreen.main.scale
        let ppm = pixPerMm
        let majC = majorGridColor; let majW = majorGridWidth
        let minC = minorGridColor; let minW = minorGridWidth
        let wfColor = waveformColor; let lw = waveformLineWidth
        let lbColor = labelColor
        let dSize = Self.dotSize

        let cornerRadius: CGFloat = 5
        let borderStrokeColor = UIColor.white.withAlphaComponent(0.6).cgColor

        for desc in descs {

            // — Grid layer: transparent background so the UIView's backgroundColor
            //   shows through uniformly — no seams between panels.
            //   cornerRadius + masksToBounds clips the grid to the rounded rect.
            let gl = CALayer()
            gl.frame = desc.frame
            gl.contentsScale = scale
            gl.isOpaque = false
            gl.cornerRadius = cornerRadius
            gl.masksToBounds = true
            gl.contents = Self.gridImage(size: desc.frame.size, scale: scale,
                                         ppm: ppm,
                                         majColor: majC, majWidth: majW,
                                         minColor: minC, minWidth: minW)
            layer.addSublayer(gl)
            gridLayers.append(gl)

            // — Waveform layer (path updated every display frame)
            let wl = CAShapeLayer()
            wl.frame = desc.frame
            wl.fillColor = nil
            wl.strokeColor = wfColor.cgColor
            wl.lineWidth = lw
            wl.lineJoin = .round
            wl.lineCap = .round
            layer.addSublayer(wl)
            waveformLayers.append(wl)

            // — Panel border: explicit rounded-rect stroke rendered on top of the grid
            //   and waveform so it's always clearly visible.
            let bl = CAShapeLayer()
            bl.frame = desc.frame
            bl.fillColor = nil
            bl.strokeColor = borderStrokeColor
            bl.lineWidth = 1.0
            bl.path = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: desc.frame.size),
                cornerRadius: cornerRadius
            ).cgPath
            layer.addSublayer(bl)
            borderLayers.append(bl)

            // — Sweep cursor dot (child of waveform layer, coordinate space: panel-local)
            let dl = CALayer()
            dl.bounds = CGRect(x: 0, y: 0, width: dSize, height: dSize)
            dl.cornerRadius = dSize / 2
            dl.backgroundColor = wfColor.cgColor
            dl.isHidden = true
            dl.shadowColor = wfColor.cgColor
            dl.shadowRadius = 3
            dl.shadowOpacity = 0.7
            dl.shadowOffset = .zero
            wl.addSublayer(dl)
            dotLayers.append(dl)

            // — Lead label (bottom-left of each panel)
            let tl = CATextLayer()
            tl.string = desc.label
            tl.fontSize = 10
            tl.foregroundColor = lbColor.cgColor
            tl.contentsScale = scale
            tl.frame = CGRect(x: 4, y: desc.frame.height - 18, width: 44, height: 14)
            tl.actions = ["contents": NSNull()]
            wl.addSublayer(tl)
            labelLayers.append(tl)
        }

        // Transfer new panel states to renderQueue (serial → naturally ordered).
        let newStates = descs.map { PanelState(leadIndex: $0.leadIndex, frame: $0.frame) }
        renderQueue.async { [weak self] in
            self?.panelStates = newStates
        }
    }

    // MARK: Private — color-only updates (no full rebuild needed)

    private func applyWaveformColor() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        waveformLayers.forEach { $0.strokeColor = waveformColor.cgColor; $0.lineWidth = waveformLineWidth }
        dotLayers.forEach { $0.backgroundColor = waveformColor.cgColor; $0.shadowColor = waveformColor.cgColor }
        CATransaction.commit()
    }

    private func applyLabelColor() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        labelLayers.forEach { $0.foregroundColor = labelColor.cgColor }
        CATransaction.commit()
    }

    // MARK: Private — display link tick (main thread)

    @objc private func tick(_ link: CADisplayLink) {
        let dt = previousTimestamp == 0 ? 0 : link.targetTimestamp - previousTimestamp
        previousTimestamp = link.targetTimestamp
        guard dt > 0 else { return }

        // Snapshot everything that's main-thread-owned before leaving main thread.
        let layers = waveformLayers
        let dots   = dotLayers
        guard !layers.isEmpty else { return }

        os_unfair_lock_lock(&statusLock)
        let status = _leadStatus
        os_unfair_lock_unlock(&statusLock)

        let pxPerSec     = Double(pixPerMm * paperSpeedMmPerSec)
        let samplesPerPx = sampleRate / pxPerSec
        let gainPxPerMv  = Float(sensitivityMmPerMv * pixPerMm)
        let maxSamples   = Int(dt * sampleRate) + 2
        let eraser       = Self.eraserPx
        let dSize        = Self.dotSize
        let wfCGColor    = waveformColor.cgColor
        let lostCGColor  = lostLeadColor.cgColor

        renderQueue.async { [weak self] in
            guard let self, !self.panelStates.isEmpty else { return }

            // Dequeue once per unique lead — shared between short panel + long strip.
            let uniqueLeads = Set(self.panelStates.map(\.leadIndex))
            var samplesMap = [Int: [Int16]](minimumCapacity: uniqueLeads.count)
            for lead in uniqueLeads {
                let s = self.sampleQueue.dequeue(lead: lead, max: maxSamples)
                if !s.isEmpty { samplesMap[lead] = s }
            }

            struct RenderResult {
                let path: CGPath
                let stroke: CGColor
                let dotPos: CGPoint?
            }
            var results = [RenderResult]()
            results.reserveCapacity(self.panelStates.count)

            for state in self.panelStates {
                let isLost = state.leadIndex < status.count ? !status[state.leadIndex] : false

                if !isLost, let samples = samplesMap[state.leadIndex] {
                    self.plot(samples, into: state,
                              samplesPerPx: samplesPerPx, gainPxPerMv: gainPxPerMv)
                }

                let path   = self.makePath(state: state, isLost: isLost, eraserWidth: eraser)
                let stroke = isLost ? lostCGColor : wfCGColor

                // Dot sits at the tip of the last-written sample (leading sweep edge).
                var dotPos: CGPoint? = nil
                if state.initialized && !isLost {
                    let col = (state.writeCol + state.pixelWidth - 1) % state.pixelWidth
                    let rawY = state.panelHeight / 2 - CGFloat(state.yBuffer[col])
                    dotPos = CGPoint(x: CGFloat(col),
                                     y: max(0, min(state.panelHeight, rawY)))
                }

                results.append(RenderResult(path: path, stroke: stroke, dotPos: dotPos))
            }

            // Only layer mutations touch main thread — paths are fully built here.
            DispatchQueue.main.async { [weak self] in
                guard self != nil else { return }
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                for (i, r) in results.enumerated() {
                    if i < layers.count {
                        layers[i].path = r.path
                        layers[i].strokeColor = r.stroke
                    }
                    if i < dots.count {
                        if let pos = r.dotPos {
                            dots[i].isHidden = false
                            dots[i].position = CGPoint(x: pos.x, y: pos.y)
                        } else {
                            dots[i].isHidden = true
                        }
                    }
                }
                CATransaction.commit()
            }
        }
    }

    // MARK: Private — sample plotting (renderQueue only)

    private func plot(
        _ samples: [Int16],
        into state: PanelState,
        samplesPerPx: Double,
        gainPxPerMv: Float
    ) {
        let step = 1.0 / samplesPerPx
        for s in samples {
            let yPx = Float(s) / 1_000.0 * gainPxPerMv
            state.pxFrac += step
            // A single sample may advance more than one column at high paper speeds.
            while state.pxFrac >= 1.0 {
                state.pxFrac -= 1.0
                state.yBuffer[state.writeCol] = yPx
                state.writeCol = (state.writeCol + 1) % state.pixelWidth
                state.initialized = true
            }
        }
    }

    // MARK: Private — CGPath construction (renderQueue only)

    private func makePath(state: PanelState, isLost: Bool, eraserWidth: Int) -> CGPath {
        let w    = state.pixelWidth
        let midY = state.panelHeight / 2
        let path = CGMutablePath()

        guard state.initialized, !isLost else {
            path.move(to: .init(x: 0, y: midY))
            path.addLine(to: .init(x: CGFloat(w), y: midY))
            return path
        }

        // Eraser gap: [writeCol, writeCol + eraserWidth) — may wrap the ring boundary.
        let gapStart = state.writeCol
        let gapEnd   = (state.writeCol + eraserWidth) % w
        let wraps    = gapEnd <= gapStart

        let maxY = state.panelHeight
        var penUp = true

        for col in 0..<w {
            let inGap = wraps
                ? (col >= gapStart || col < gapEnd)
                : (col >= gapStart && col < gapEnd)

            if inGap { penUp = true; continue }

            let rawY = midY - CGFloat(state.yBuffer[col])
            let pt   = CGPoint(x: CGFloat(col), y: max(0, min(maxY, rawY)))

            if penUp { path.move(to: pt);    penUp = false }
            else      { path.addLine(to: pt) }
        }

        return path
    }

    // MARK: Private — grid image (transparent — no background fill)

    private static func gridImage(
        size: CGSize,
        scale: CGFloat,
        ppm: CGFloat,
        majColor: UIColor, majWidth: CGFloat,
        minColor: UIColor, minWidth: CGFloat
    ) -> CGImage? {
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false   // ← transparent: UIView.backgroundColor shows through

        let img = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let c = ctx.cgContext
            strokeGrid(c, size: size, step: ppm,     color: minColor, width: minWidth)
            strokeGrid(c, size: size, step: ppm * 5, color: majColor, width: majWidth)
        }
        return img.cgImage
    }

    private static func strokeGrid(
        _ ctx: CGContext,
        size: CGSize,
        step: CGFloat,
        color: UIColor,
        width: CGFloat
    ) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        var x: CGFloat = 0
        while x <= size.width {
            ctx.move(to: .init(x: x, y: 0)); ctx.addLine(to: .init(x: x, y: size.height))
            x += step
        }
        var y: CGFloat = 0
        while y <= size.height {
            ctx.move(to: .init(x: 0, y: y)); ctx.addLine(to: .init(x: size.width, y: y))
            y += step
        }
        ctx.strokePath()
    }

    // MARK: Private — panel layout computation

    // 2pt inset per side → 4pt visible gap between adjacent panels.
    private static let panelInset: CGFloat = 2

    private static func computePanels(in bounds: CGRect, layout: ECGLeadLayout, isCompact: Bool) -> [PanelDescriptor] {
        let W = bounds.width, H = bounds.height
        guard W > 0, H > 0 else { return [] }
        let s = panelInset

        switch layout {

        case .threeByFour:
            if isCompact {
                // iPhone: 3 columns × 4 rows + full-width long strip.
                // Rows: I/II/III → aVR/aVL/aVF → V1/V2/V3 → V4/V5/V6 → II long
                let rowH = H / 5, colW = W / 3
                let grid: [[Int]] = [
                    [0,  1,  2 ],   // I,   II,  III
                    [3,  4,  5 ],   // aVR, aVL, aVF
                    [6,  7,  8 ],   // V1,  V2,  V3
                    [9,  10, 11],   // V4,  V5,  V6
                ]
                var out = [PanelDescriptor]()
                for (r, row) in grid.enumerated() {
                    for (c, li) in row.enumerated() {
                        out.append(.init(leadIndex: li, label: leadNames[li],
                                         frame: .init(x: CGFloat(c)*colW + s, y: CGFloat(r)*rowH + s,
                                                      width: colW - s*2, height: rowH - s*2),
                                         isLong: false))
                    }
                }
                out.append(.init(leadIndex: 1, label: leadNames[1],
                                  frame: .init(x: s, y: 4*rowH + s, width: W - s*2, height: rowH - s*2),
                                  isLong: true))
                return out
            } else {
                // iPad: 4 columns × 3 rows + full-width long strip (standard 12-lead landscape layout).
                // Col order: limb (I,II,III) | augmented (aVR,aVL,aVF) | precordial V1–V3 | precordial V4–V6
                let rowH = H / 4, colW = W / 4
                let grid: [[Int]] = [
                    [0, 3, 6,  9 ],   // I,   aVR, V1, V4
                    [1, 4, 7,  10],   // II,  aVL, V2, V5
                    [2, 5, 8,  11],   // III, aVF, V3, V6
                ]
                var out = [PanelDescriptor]()
                for (r, row) in grid.enumerated() {
                    for (c, li) in row.enumerated() {
                        out.append(.init(leadIndex: li, label: leadNames[li],
                                         frame: .init(x: CGFloat(c)*colW + s, y: CGFloat(r)*rowH + s,
                                                      width: colW - s*2, height: rowH - s*2),
                                         isLong: false))
                    }
                }
                out.append(.init(leadIndex: 1, label: leadNames[1],
                                  frame: .init(x: s, y: 3*rowH + s, width: W - s*2, height: rowH - s*2),
                                  isLong: true))
                return out
            }

        case .sixByTwo:
            // 2 columns × 6 rows, no long strip.
            // Left column: limb leads (I–aVF), right column: precordial (V1–V6).
            let rowH = H / 6, colW = W / 2
            let grid: [[Int]] = [
                [0,  6 ],   // I,   V1
                [1,  7 ],   // II,  V2
                [2,  8 ],   // III, V3
                [3,  9 ],   // aVR, V4
                [4,  10],   // aVL, V5
                [5,  11],   // aVF, V6
            ]
            var out = [PanelDescriptor]()
            for (r, row) in grid.enumerated() {
                for (c, li) in row.enumerated() {
                    out.append(.init(leadIndex: li, label: leadNames[li],
                                     frame: .init(x: CGFloat(c)*colW + s, y: CGFloat(r)*rowH + s,
                                                  width: colW - s*2, height: rowH - s*2),
                                     isLong: false))
                }
            }
            return out

        case .twelveByOne:
            let rowH = H / 12
            return (0..<12).map {
                .init(leadIndex: $0, label: leadNames[$0],
                      frame: .init(x: s, y: CGFloat($0)*rowH + s, width: W - s*2, height: rowH - s*2),
                      isLong: false)
            }
        }
    }
}
