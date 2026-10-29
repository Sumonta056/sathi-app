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
}
