import AppKit
import SathiCore
import SwiftUI

extension UIController {
    package func showSnoozed(_ id: HabitID, until: Date) {
        closeNote()
        note = presentCorner(SnoozedNote(id: id, until: until))
        noteTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Timing.cornerNoteDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.closeNote()
        }
    }

    func closeNote() {
        noteTask?.cancel()
        noteTask = nil
        note?.orderOut(nil)
        note = nil
    }

    func presentCorner(_ view: some View) -> NSPanel? {
        guard let h = hosting(view) else { return nil }
        return placeTopRight(CornerToast.make(h))
    }

    func celebrationPanel(_ h: NSView, _ e: Engine) -> NSPanel {
        let id = e.celebration.id
        switch id {
        case .water: return presentTopRight(h, level: .statusBar)
        case .reading, .meditation:
            return e.usesCorner(id) ? placeTopRight(CornerToast.make(h)) : presentCentered(h, level: .statusBar)
        }
    }
}
