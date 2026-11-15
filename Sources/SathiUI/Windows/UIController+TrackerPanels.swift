import AppKit
import SathiCore
import SwiftUI

extension UIController {
    func trackerRoot(_ view: some View) -> AnyView? {
        guard let engine else { return nil }
        return AnyView(view.environment(\.colorScheme, .dark).environmentObject(engine))
    }

    func trackerHosting(_ view: some View) -> NSView? {
        guard let root = trackerRoot(view) else { return nil }
        let h = FirstClickHostingView(rootView: root)
        h.setFrameSize(h.fittingSize)
        return h
    }

    func presentTrackerNote(_ content: NSView) -> NSPanel {
        let p = CornerToast.make(content)
        let screen = trackerPromptPanel?.screen ?? activeScreen
        p.setFrameOrigin(CenterStack.noteOrigin(
            note: p.frame.size,
            prompt: trackerPromptPanel?.frame,
            screen: screen?.visibleFrame ?? .zero,
            gap: UIMetrics.centerStackGap
        ))
        fadeIn(p)
        return p
    }

    func presentTrackerCentered(_ content: NSView) -> NSPanel {
        let p = presentCentered(content, level: .floating)
        trackerCenters[ObjectIdentifier(p)] = NSPoint(x: p.frame.midX, y: p.frame.midY)
        watchTrackerResize(p)
        return p
    }

    func watchTrackerResize(_ p: NSPanel) {
        if let old = trackerResizeTokens.removeValue(forKey: ObjectIdentifier(p)) {
            NotificationCenter.default.removeObserver(old)
        }
        let token = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification, object: p, queue: .main
        ) { [weak self, weak p] _ in
            MainActor.assumeIsolated {
                guard let self, let p else { return }
                self.trackerPanelResized(p)
            }
        }
        trackerResizeTokens[ObjectIdentifier(p)] = token
    }

    func closeTrackerPanel(_ p: NSPanel) {
        if let token = trackerResizeTokens.removeValue(forKey: ObjectIdentifier(p)) {
            NotificationCenter.default.removeObserver(token)
        }
        trackerCenters[ObjectIdentifier(p)] = nil
        dismiss(p)
    }

    private func trackerPanelResized(_ p: NSPanel) {
        guard let c = trackerCenters[ObjectIdentifier(p)] else { return }
        placeTracker(p, center: c, screen: p.screen ?? activeScreen)
    }

    private func placeTracker(_ p: NSPanel, center c: NSPoint, screen: NSScreen?) {
        var origin = NSPoint(x: c.x - p.frame.width / 2, y: c.y - p.frame.height / 2)
        if let f = screen?.visibleFrame {
            origin = PromptFit.clamped(origin: origin, size: p.frame.size, screen: f, margin: UIMetrics.promptScreenMargin)
        }
        p.setFrameOrigin(origin)
        trackerCenters[ObjectIdentifier(p)] = NSPoint(x: p.frame.midX, y: p.frame.midY)
    }
}
