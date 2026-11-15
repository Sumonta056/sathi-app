import AppKit
import SathiCore

extension UIController {
    func watchTrackerMove(_ p: NSPanel) {
        unwatchTrackerMove()
        trackerMoveToken = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification, object: p, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { _ = self?.dropTrackerPrompt() }
        }
    }

    func unwatchTrackerMove() {
        disarmTrackerMouseUp()
        guard let token = trackerMoveToken else { return }
        NotificationCenter.default.removeObserver(token)
        trackerMoveToken = nil
    }

    @discardableResult
    func dropTrackerPrompt() -> Bool {
        guard trackerPromptPanel != nil else { return true }
        guard NSEvent.pressedMouseButtons & 1 == 0 else {
            armTrackerMouseUp()
            return false
        }
        runTrackerDrop()
        return true
    }

    private func runTrackerDrop() {
        disarmTrackerMouseUp()
        guard let p = trackerPromptPanel else { return }
        let margin = UIMetrics.promptScreenMargin
        guard let target = PromptFit.screen(for: p.frame, in: NSScreen.screens.map(\.visibleFrame)) else { return }
        let fit = PromptFit.size(screen: target, margin: margin)
        if !PromptFit.sameSize(fit, p.frame.size), let kind = trackerPromptKind {
            trackerCenters[ObjectIdentifier(p)] = NSPoint(x: p.frame.midX, y: p.frame.midY)
            presentTrackerPrompt(kind, visible: target)
        }
        let f = PromptFit.dropped(frame: p.frame, screens: [target], margin: margin)
        if f.origin != p.frame.origin { p.setFrameOrigin(f.origin) }
        trackerCenters[ObjectIdentifier(p)] = NSPoint(x: p.frame.midX, y: p.frame.midY)
    }

    private func armTrackerMouseUp() {
        guard trackerUpMonitor == nil else { return }
        trackerUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            MainActor.assumeIsolated { self?.runTrackerDrop() }
            return event
        }
    }

    private func disarmTrackerMouseUp() {
        guard let monitor = trackerUpMonitor else { return }
        NSEvent.removeMonitor(monitor)
        trackerUpMonitor = nil
    }
}
