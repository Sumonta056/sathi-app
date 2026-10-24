import AppKit

extension UIController {
    private var primary: NSScreen? { NSScreen.screens.first ?? NSScreen.main }

    func presentCentered(_ content: NSView, level: NSWindow.Level) -> NSPanel {
        let p = PanelFactory.make(FloatingPanel.self, content: content, level: level)
        if let f = primary?.visibleFrame {
            p.setFrameOrigin(NSPoint(x: f.midX - p.frame.width / 2, y: f.midY - p.frame.height / 2))
        }
        fadeIn(p)
        return p
    }

    func presentTopRight(_ content: NSView, level: NSWindow.Level) -> NSPanel {
        placeTopRight(PanelFactory.make(FloatingPanel.self, content: content, level: level))
    }

    func placeTopRight(_ p: NSPanel) -> NSPanel {
        if let vf = primary?.visibleFrame {
            let inset = UIMetrics.bubbleScreenInset
            p.setFrameOrigin(NSPoint(x: vf.maxX - p.frame.width + inset.x, y: vf.maxY - p.frame.height + inset.y))
        }
        fadeIn(p)
        return p
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
