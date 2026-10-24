import AppKit

@MainActor
enum CornerToast {
    static func make(_ content: NSView) -> NSPanel {
        let p = PanelFactory.make(CornerPanel.self, content: content, level: .statusBar)
        p.becomesKeyOnlyIfNeeded = true
        return p
    }
}
