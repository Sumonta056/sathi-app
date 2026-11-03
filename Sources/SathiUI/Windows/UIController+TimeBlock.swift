import AppKit
import SathiCore
import SwiftUI

enum BlockPanel {
    case widget, done, checkIn, calendarGone
}

extension UIController {
    package func showBlockStart() {
        closeBlockStart()
        guard let h = hosting(BlockStartPopup()) else { return }
        let p = placeTopRight(CornerToast.makeKey(h) { [weak self] in self?.closeBlockStart() })
        blockStartPanel = p
        let front = NSWorkspace.shared.frontmostApplication
        blockStartReturnApp = front == NSRunningApplication.current ? nil : front
        NSApp.activate(ignoringOtherApps: true)
        p.makeKey()
    }

    package func closeBlockStart() {
        guard let p = blockStartPanel else { return }
        dismiss(p)
        blockStartPanel = nil
        if NSApp.isActive, NSApp.keyWindow == nil || NSApp.keyWindow === p { blockStartReturnApp?.activate() }
        blockStartReturnApp = nil
    }

    package func showBlockNote(_ note: BlockNote) {
        presentNote(BlockNoteView(note: note))
    }

    package func showBlockWidget() {
        showBlock(.widget, BlockWidget { [weak self] in self?.moveBlockWidget(by: $0) })
        blockPanels[.widget]?.allowsToolTipsWhenApplicationIsInactive = true
    }

    func moveBlockWidget(by delta: CGSize) {
        guard delta != .zero, let p = blockPanels[.widget] else { return }
        detachFromCorner(p)
        p.setFrameOrigin(NSPoint(x: p.frame.minX + delta.width, y: p.frame.minY + delta.height))
    }
    package func closeBlockWidget() { closeBlock(.widget) }
    package func showBlockDone() { showBlock(.done, BlockDonePopup()) }
    package func closeBlockDone() { closeBlock(.done) }
    package func showBlockCheckIn() { showBlock(.checkIn, BlockCheckInPopup()) }
    package func closeBlockCheckIn() { closeBlock(.checkIn) }
    package func showBlockCalendarGone() { showBlock(.calendarGone, CalendarGonePopup()) }
    package func closeBlockCalendarGone() { closeBlock(.calendarGone) }

    private func showBlock(_ kind: BlockPanel, _ view: some View) {
        closeBlock(kind)
        blockPanels[kind] = presentCorner(view)
    }

    private func closeBlock(_ kind: BlockPanel) {
        dismiss(blockPanels.removeValue(forKey: kind))
    }
}
