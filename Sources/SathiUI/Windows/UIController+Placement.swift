import AppKit

extension UIController {
    var activeScreen: NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
    }

    func presentCentered(_ content: NSView, level: NSWindow.Level) -> NSPanel {
        let p = PanelFactory.make(FloatingPanel.self, content: content, level: level)
        if let f = activeScreen?.visibleFrame {
            p.setFrameOrigin(NSPoint(x: f.midX - p.frame.width / 2, y: f.midY - p.frame.height / 2))
        }
        fadeIn(p)
        return p
    }

    func presentTopRight(_ content: NSView, level: NSWindow.Level) -> NSPanel {
        placeTopRight(PanelFactory.make(FloatingPanel.self, content: content, level: level))
    }

    func placeTopRight(_ p: NSPanel) -> NSPanel {
        if corner.isEmpty { cornerScreen = activeScreen }
        corner.append(p)
        restack()
        fadeIn(p)
        return p
    }

    func dismiss(_ p: NSPanel?) {
        guard let p else { return }
        p.orderOut(nil)
        corner.removeAll { $0 === p }
        if corner.isEmpty { cornerScreen = nil }
        restack()
    }

    func detachFromCorner(_ p: NSPanel) {
        guard corner.contains(where: { $0 === p }) else { return }
        corner.removeAll { $0 === p }
        if corner.isEmpty { cornerScreen = nil }
        restack()
    }

    private func restack() {
        guard let vf = (cornerScreen ?? activeScreen)?.visibleFrame else { return }
        let origins = CornerLayout.origins(
            sizes: corner.map(\.frame.size),
            in: vf,
            inset: UIMetrics.bubbleScreenInset,
            overlap: UIMetrics.cornerStackOverlap,
            gap: UIMetrics.cornerColumnGap
        )
        for (p, origin) in zip(corner, origins) {
            p.setFrameOrigin(origin)
        }
    }

    private func fadeIn(_ w: NSWindow) {
        w.alphaValue = 0
        w.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = UIMetrics.fadeDuration
            w.animator().alphaValue = 1
        }
    }
}
