import AppKit

@MainActor
final class WindowCloseWatcher: NSObject, NSWindowDelegate {
    var onClose: () -> Void = {}
    var lastVisibleFrame: CGRect?
    private var fitting = false

    func windowWillClose(_: Notification) {
        onClose()
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard !fitting, let window = notification.object as? NSWindow, let screen = window.screen else { return }
        let target = screen.visibleFrame
        defer { lastVisibleFrame = target }
        guard let from = lastVisibleFrame, from != target else { return }
        let fitted = WindowFit.moved(frame: window.frame, from: from, to: target, tolerance: UIMetrics.windowFitTolerance)
        guard fitted != window.frame else { return }
        fitting = true
        window.setFrame(fitted, display: true)
        fitting = false
    }
}
