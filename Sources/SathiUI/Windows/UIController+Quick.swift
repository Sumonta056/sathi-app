import AppKit
import SathiCore
import SwiftUI

extension UIController {
    package func showQuick(_ id: UUID, _ level: Level) {
        closeQuick(id)
        quickPanels[id] = presentCorner(QuickPopup(id: id, level: level))
    }

    package func closeQuick(_ id: UUID) {
        dismiss(quickPanels.removeValue(forKey: id))
    }

    package func showQuickLock(_ id: UUID) {
        presentLocks(QuickLockView(id: id))
    }

    package func showQuickSnoozed(text: String, until: Date) {
        presentNote(QuickSnoozedNote(text: text, until: until))
    }

    package func showQuickAdd() {
        closeQuickAdd()
        guard let h = hosting(QuickAddPopup()) else { return }
        let p = placeTopRight(CornerToast.makeKey(h) { [weak self] in self?.closeQuickAdd() })
        quickAddPanel = p
        let front = NSWorkspace.shared.frontmostApplication
        quickAddReturnApp = front == NSRunningApplication.current ? nil : front
        NSApp.activate(ignoringOtherApps: true)
        p.makeKey()
    }

    package func closeQuickAdd() {
        guard let p = quickAddPanel else { return }
        dismiss(p)
        quickAddPanel = nil
        if NSApp.isActive, NSApp.keyWindow == nil || NSApp.keyWindow === p { quickAddReturnApp?.activate() }
        quickAddReturnApp = nil
    }
}
