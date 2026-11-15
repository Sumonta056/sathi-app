import AppKit
import SathiCore

extension UIController {
    func watchTrackerMove(_ p: NSPanel) {
        unwatchTrackerMove()
        trackerMoveToken = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification, object: p, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.dropTrackerPrompt() }
        }
    }

    func unwatchTrackerMove() {
        guard let token = trackerMoveToken else { return }
        NotificationCenter.default.removeObserver(token)
        trackerMoveToken = nil
    }

    func dropTrackerPrompt() {
        guard let p = trackerPromptPanel, NSEvent.pressedMouseButtons & 1 == 0 else { return }
        let margin = UIMetrics.promptScreenMargin
        guard let target = PromptFit.screen(for: p.frame, in: NSScreen.screens.map(\.visibleFrame)) else { return }
        if PromptFit.size(screen: target, margin: margin) != p.frame.size, let kind = trackerPromptKind {
            trackerCenters[ObjectIdentifier(p)] = NSPoint(x: p.frame.midX, y: p.frame.midY)
            presentTrackerPrompt(kind, visible: target)
        }
        let f = PromptFit.dropped(frame: p.frame, screens: [target], margin: margin)
        if f.origin != p.frame.origin { p.setFrameOrigin(f.origin) }
        trackerCenters[ObjectIdentifier(p)] = NSPoint(x: p.frame.midX, y: p.frame.midY)
    }
}
