import SwiftUI
import UIKit

// MARK: - PinchZoomView

private class PinchZoomView: UIView {

    weak var delegate: PinchZoomViewDelegate?

    private(set) var scale: CGFloat = 0 {
        didSet { delegate?.pinchZoomView(self, didChangeScale: scale) }
    }
    private(set) var anchor: UnitPoint = .center {
        didSet { delegate?.pinchZoomView(self, didChangeAnchor: anchor) }
    }
    private(set) var offset: CGSize = .zero {
        didSet { delegate?.pinchZoomView(self, didChangeOffset: offset) }
    }
    private(set) var isPinching: Bool = false {
        didSet { delegate?.pinchZoomView(self, didChangePinching: isPinching) }
    }

    private var startLocation: CGPoint = .zero
    private var location: CGPoint = .zero
    private var numberOfTouches: Int = 0

    init() {
        super.init(frame: .zero)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.cancelsTouchesInView = false
        addGestureRecognizer(pinch)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isPinching = true
            startLocation = gesture.location(in: self)
            anchor = UnitPoint(x: startLocation.x / bounds.width,
                               y: startLocation.y / bounds.height)
            numberOfTouches = gesture.numberOfTouches

        case .changed:
            if gesture.numberOfTouches != numberOfTouches {
                let newLocation = gesture.location(in: self)
                let jump = CGSize(width: newLocation.x - location.x,
                                  height: newLocation.y - location.y)
                startLocation = CGPoint(x: startLocation.x + jump.width,
                                        y: startLocation.y + jump.height)
                numberOfTouches = gesture.numberOfTouches
            }
            scale = gesture.scale
            location = gesture.location(in: self)
            offset = CGSize(width: location.x - startLocation.x,
                            height: location.y - startLocation.y)

        case .ended, .cancelled, .failed:
            isPinching = false
            scale = 1.0
            anchor = .center
            offset = .zero

        default:
            break
        }
    }
}

// MARK: - Delegate

private protocol PinchZoomViewDelegate: AnyObject {
    func pinchZoomView(_ view: PinchZoomView, didChangePinching isPinching: Bool)
    func pinchZoomView(_ view: PinchZoomView, didChangeScale scale: CGFloat)
    func pinchZoomView(_ view: PinchZoomView, didChangeAnchor anchor: UnitPoint)
    func pinchZoomView(_ view: PinchZoomView, didChangeOffset offset: CGSize)
}

// MARK: - UIViewRepresentable bridge

private struct PinchZoom: UIViewRepresentable {

    @Binding var scale: CGFloat
    @Binding var anchor: UnitPoint
    @Binding var offset: CGSize
    @Binding var isPinching: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PinchZoomView {
        let v = PinchZoomView()
        v.delegate = context.coordinator
        return v
    }

    func updateUIView(_ uiView: PinchZoomView, context: Context) {}

    class Coordinator: NSObject, PinchZoomViewDelegate {
        var parent: PinchZoom
        init(_ parent: PinchZoom) { self.parent = parent }

        func pinchZoomView(_ view: PinchZoomView, didChangePinching isPinching: Bool) { parent.isPinching = isPinching }
        func pinchZoomView(_ view: PinchZoomView, didChangeScale scale: CGFloat)       { parent.scale = scale }
        func pinchZoomView(_ view: PinchZoomView, didChangeAnchor anchor: UnitPoint)   { parent.anchor = anchor }
        func pinchZoomView(_ view: PinchZoomView, didChangeOffset offset: CGSize)      { parent.offset = offset }
    }
}

// MARK: - ViewModifier

struct PinchToZoom: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @State private var anchor: UnitPoint = .center
    @State private var offset: CGSize = .zero
    @State private var isPinching: Bool = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale, anchor: anchor)
            .offset(offset)
            .animation(isPinching ? .none : .spring(), value: isPinching)
            .overlay(
                PinchZoom(scale: $scale, anchor: $anchor,
                          offset: $offset, isPinching: $isPinching)
            )
    }
}

extension View {
    func pinchToZoom() -> some View {
        modifier(PinchToZoom())
    }
}
