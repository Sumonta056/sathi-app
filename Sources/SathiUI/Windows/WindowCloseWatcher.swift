import AppKit

@MainActor
final class WindowCloseWatcher: NSObject, NSWindowDelegate {
    var onClose: () -> Void = {}
    var lastVisibleFrame: CGRect?
    var onShape: (CGRect) -> Void = { _ in }
    var shapeFrame: CGRect? {
        didSet { if let shapeFrame, shapeFrame != oldValue { onShape(shapeFrame) } }
    }
    private var fitting = false
    private var pendingFit = false
    private var releaseMonitor: Any?

    func windowWillClose(_: Notification) {
        removeReleaseMonitor()
        onClose()
    }

    func windowDidMove(_ notification: Notification) {
        guard !fitting, let window = notification.object as? NSWindow else { return }
        if NSEvent.pressedMouseButtons == 0 {
            settle(window)
        } else {
            armReleaseMonitor(window)
        }
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        let record = WindowFit.shouldRecordShape(
            fitting: fitting,
            pendingFit: pendingFit,
            mouseDown: NSEvent.pressedMouseButtons != 0,
            inLiveResize: window.inLiveResize
        )
        if record { shapeFrame = window.frame }
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        guard !fitting, let window = notification.object as? NSWindow else { return }
        settle(window)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard !fitting, let window = notification.object as? NSWindow else { return }
        pendingFit = true
        if NSEvent.pressedMouseButtons == 0 {
            settle(window)
        } else {
            armReleaseMonitor(window)
        }
    }

    func settle(_ window: NSWindow) {
        guard !fitting, NSEvent.pressedMouseButtons == 0 else { return }
        removeReleaseMonitor()
        if pendingFit {
            pendingFit = false
            fit(window)
        } else {
            shapeFrame = window.frame
        }
    }

    private func armReleaseMonitor(_ window: NSWindow) {
        guard releaseMonitor == nil else { return }
        releaseMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self, weak window] event in
            DispatchQueue.main.async {
                if let window { self?.settle(window) }
            }
            return event
        }
    }

    private func removeReleaseMonitor() {
        if let releaseMonitor { NSEvent.removeMonitor(releaseMonitor) }
        releaseMonitor = nil
    }

    private func fit(_ window: NSWindow) {
        guard let screen = window.screen, !window.styleMask.contains(.fullScreen) else { return }
        let target = screen.visibleFrame
        let before = shapeFrame ?? window.frame
        defer { lastVisibleFrame = target }
        guard let from = lastVisibleFrame, from != target else {
            shapeFrame = window.frame
            return
        }
        let fitted = WindowFit.moved(frame: before, from: from, to: target, tolerance: UIMetrics.windowFitTolerance)
        fitting = true
        if fitted != window.frame { window.setFrame(fitted, display: true) }
        fitting = false
        shapeFrame = window.frame
    }
}
