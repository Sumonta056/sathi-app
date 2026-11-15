import AppKit

@MainActor
final class WindowCloseWatcher: NSObject, NSWindowDelegate {
    var onClose: () -> Void = {}
    var lastVisibleFrame: CGRect?
    var shapeFrame: CGRect?
    private var fitting = false
    private var releaseMonitor: Any?

    func windowWillClose(_: Notification) {
        removeReleaseMonitor()
        onClose()
    }

    func windowDidMove(_ notification: Notification) {
        rememberShape(notification)
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        rememberShape(notification)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard !fitting, let window = notification.object as? NSWindow else { return }
        if NSEvent.pressedMouseButtons == 0 {
            fit(window)
        } else {
            fitAfterRelease(window)
        }
    }

    private func rememberShape(_ notification: Notification) {
        guard !fitting, NSEvent.pressedMouseButtons == 0, let window = notification.object as? NSWindow else { return }
        shapeFrame = window.frame
    }

    private func fitAfterRelease(_ window: NSWindow) {
        guard releaseMonitor == nil else { return }
        releaseMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self, weak window] event in
            DispatchQueue.main.async {
                self?.removeReleaseMonitor()
                if let window { self?.fit(window) }
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
