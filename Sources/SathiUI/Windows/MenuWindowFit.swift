import AppKit
import SwiftUI

struct MenuWindowFit: NSViewRepresentable {
    let height: CGFloat

    func makeNSView(context _: Context) -> NSView { NSView() }

    func updateNSView(_ view: NSView, context _: Context) {
        let target = height
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            let content = window.contentRect(forFrameRect: window.frame)
            guard Self.needsFit(content, height: target) else { return }
            window.setFrame(window.frameRect(forContentRect: Self.frame(content, height: target)), display: true)
        }
    }

    static func needsFit(_ current: NSRect, height: CGFloat) -> Bool {
        abs(current.height - height) > UIMetrics.windowFitTolerance
    }

    static func frame(_ current: NSRect, height: CGFloat) -> NSRect {
        NSRect(x: current.minX, y: current.maxY - height, width: current.width, height: height)
    }
}
