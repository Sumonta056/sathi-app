import AppKit
import SwiftUI

struct PromptDragHandle: NSViewRepresentable {
    var onDrop: () -> Bool

    func makeNSView(context _: Context) -> PromptDragView {
        let v = PromptDragView()
        v.onDrop = onDrop
        return v
    }

    func updateNSView(_ v: PromptDragView, context _: Context) {
        v.onDrop = onDrop
    }
}

final class PromptDragView: NSView {
    var onDrop: () -> Bool = { true }
    private var startOrigin: NSPoint?

    override var mouseDownCanMoveWindow: Bool { false }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        startOrigin = window.frame.origin
        window.performDrag(with: event)
        dropIfMoved()
    }

    override func mouseUp(with _: NSEvent) {
        dropIfMoved()
    }

    private func dropIfMoved() {
        guard let start = startOrigin, let window, window.frame.origin != start else { return }
        if onDrop() { startOrigin = nil }
    }
}
