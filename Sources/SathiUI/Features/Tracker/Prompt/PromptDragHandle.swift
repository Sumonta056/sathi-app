import AppKit
import SwiftUI

struct PromptDragHandle: NSViewRepresentable {
    var onDrop: () -> Void

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
    var onDrop: () -> Void = {}

    override var mouseDownCanMoveWindow: Bool { false }

    override func acceptsFirstMouse(for _: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        window.performDrag(with: event)
        onDrop()
    }

    override func mouseUp(with _: NSEvent) {
        onDrop()
    }
}
