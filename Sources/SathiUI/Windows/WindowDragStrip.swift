import AppKit
import SwiftUI

struct WindowDragStrip: NSViewRepresentable {
    func makeNSView(context _: Context) -> DragStripView {
        DragStripView()
    }

    func updateNSView(_: DragStripView, context _: Context) {}
}

final class DragStripView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        if event.clickCount == 2 {
            window.zoom(nil)
        } else {
            window.performDrag(with: event)
        }
    }
}
