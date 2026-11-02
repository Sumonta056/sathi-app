import Foundation
import SathiCore

package final class FakeClock: Clock {
    package var now: Date

    package init(_ now: Date) {
        self.now = now
    }

    package func advance(minutes: Double) {
        now = now.addingTimeInterval(minutes * Timing.minute)
    }
}

package final class SpySoundPlayer: SoundPlayer {
    package private(set) var played: [SoundName] = []
    package private(set) var beeps = 0

    package init() {}

    package func play(_ sound: SoundName) { played.append(sound) }
    package func beep() { beeps += 1 }
}

@MainActor
package final class SpyPresenter: ReminderPresenter {
    package enum Call: Equatable {
        case showBubble(HabitID, Level), closeBubble(HabitID)
        case showLock(HabitID), closeLock
        case showSession(HabitID), closeSession(HabitID)
        case showCelebration, closeCelebration
        case showSettings, showReports
        case showSnoozed(HabitID, Date)
        case showDaySummary, closeDaySummary
        case showQuick(UUID, Level), closeQuick(UUID), showQuickLock(UUID), showQuickSnoozed(String, Date)
        case showBlockStart, closeBlockStart, showBlockNote(BlockNote), showBlockWidget, closeBlockWidget
        case showBlockDone, closeBlockDone, showBlockCheckIn, closeBlockCheckIn
        case showBlockCalendarGone, closeBlockCalendarGone
    }

    package private(set) var calls: [Call] = []

    package var blockNotes: [BlockNote] {
        calls.compactMap { if case let .showBlockNote(note) = $0 { note } else { nil } }
    }

    package init() {}

    package func showBubble(_ id: HabitID, _ level: Level) { calls.append(.showBubble(id, level)) }
    package func closeBubble(_ id: HabitID) { calls.append(.closeBubble(id)) }
    package func showLock(_ id: HabitID) { calls.append(.showLock(id)) }
    package func closeLock() { calls.append(.closeLock) }
    package func showSession(_ id: HabitID) { calls.append(.showSession(id)) }
    package func closeSession(_ id: HabitID) { calls.append(.closeSession(id)) }
    package func showCelebration() { calls.append(.showCelebration) }
    package func closeCelebration() { calls.append(.closeCelebration) }
    package func showSettings() { calls.append(.showSettings) }
    package func showReports() { calls.append(.showReports) }
    package func showSnoozed(_ id: HabitID, until: Date) { calls.append(.showSnoozed(id, until)) }
    package func showDaySummary() { calls.append(.showDaySummary) }
    package func closeDaySummary() { calls.append(.closeDaySummary) }
    package func showQuick(_ id: UUID, _ level: Level) { calls.append(.showQuick(id, level)) }
    package func closeQuick(_ id: UUID) { calls.append(.closeQuick(id)) }
    package func showQuickLock(_ id: UUID) { calls.append(.showQuickLock(id)) }
    package func showQuickSnoozed(text: String, until: Date) { calls.append(.showQuickSnoozed(text, until)) }

    package func showBlockStart() { calls.append(.showBlockStart) }
    package func closeBlockStart() { calls.append(.closeBlockStart) }
    package func showBlockNote(_ note: BlockNote) { calls.append(.showBlockNote(note)) }
    package func showBlockWidget() { calls.append(.showBlockWidget) }
    package func closeBlockWidget() { calls.append(.closeBlockWidget) }
    package func showBlockDone() { calls.append(.showBlockDone) }
    package func closeBlockDone() { calls.append(.closeBlockDone) }
    package func showBlockCheckIn() { calls.append(.showBlockCheckIn) }
    package func closeBlockCheckIn() { calls.append(.closeBlockCheckIn) }
    package func showBlockCalendarGone() { calls.append(.showBlockCalendarGone) }
    package func closeBlockCalendarGone() { calls.append(.closeBlockCalendarGone) }
}
