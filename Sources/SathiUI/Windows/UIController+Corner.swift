import AppKit
import SathiCore
import SwiftUI

extension UIController {
    package func showSnoozed(_ id: HabitID, until: Date) {
        presentNote(SnoozedNote(id: id, until: until))
    }

    func presentNote(_ view: some View) {
        closeNote()
        note = presentCorner(view)
        noteTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Timing.cornerNoteDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.closeNote()
        }
    }

    package func showDaySummary() {
        closeDaySummary()
        daySummaryPanel = presentCorner(DaySummaryCard())
    }

    package func closeDaySummary() {
        dismiss(daySummaryPanel)
        daySummaryPanel = nil
    }

    func closeNote() {
        noteTask?.cancel()
        noteTask = nil
        dismiss(note)
        note = nil
    }

    func presentCorner(_ view: some View) -> NSPanel? {
        guard let h = hosting(view) else { return nil }
        return placeTopRight(CornerToast.make(h))
    }

    @ViewBuilder
    func cornerSessionView(_ id: HabitID) -> some View {
        switch id {
        case .gym: GymTimerCard()
        case .water, .reading, .meditation: ReadingTimerPill()
        }
    }

    func celebrationPanel(_ h: NSView, _ e: Engine) -> NSPanel {
        let id = e.celebration.id
        switch id {
        case .water: return presentTopRight(h, level: .statusBar)
        case .reading, .meditation, .gym:
            return e.usesCorner(id) ? placeTopRight(CornerToast.make(h)) : presentCentered(h, level: .statusBar)
        }
    }
}
