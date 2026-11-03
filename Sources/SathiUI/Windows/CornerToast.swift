import AppKit

@MainActor
enum CornerToast {
    static func make(_ content: NSView) -> NSPanel {
        let p = PanelFactory.make(CornerPanel.self, content: content, level: .statusBar)
        p.becomesKeyOnlyIfNeeded = true
        return p
    }

    static func makeKey(_ content: NSView, onCancel: @escaping () -> Void) -> NSPanel {
        let p = PanelFactory.make(KeyCornerPanel.self, content: content, level: .statusBar)
        (p as? KeyCornerPanel)?.onCancel = onCancel
        return p
    }
}
