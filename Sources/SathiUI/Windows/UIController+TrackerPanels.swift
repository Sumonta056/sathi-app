import AppKit
import SathiCore
import SwiftUI

extension UIController {
    func trackerHosting(_ view: some View) -> NSView? {
        guard let engine else { return nil }
        let root = AnyView(view.environment(\.colorScheme, .dark).environmentObject(engine))
        let h = FirstClickHostingView(rootView: root)
        h.setFrameSize(h.fittingSize)
        return h
    }

    func placeTrackerCorner(_ content: NSView, onCancel: @escaping () -> Void) -> NSPanel {
        let p = CornerToast.makeKey(content, onCancel: onCancel)
        p.becomesKeyOnlyIfNeeded = true
        trackerCorner.append(p)
        let placed = placeTopRight(p)
        watchTrackerResize(placed)
        return placed
    }

    func isTrackerCorner(_ p: NSPanel) -> Bool {
        trackerCorner.contains { $0 === p }
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
        trackerCorner.removeAll { $0 === p }
    }

    private func trackerPanelResized(_ p: NSPanel) {
        if corner.contains(where: { $0 === p }) {
            restack()
        } else if let c = trackerCenters[ObjectIdentifier(p)] {
            p.setFrameOrigin(NSPoint(x: c.x - p.frame.width / 2, y: c.y - p.frame.height / 2))
        }
    }
}
