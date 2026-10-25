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
    }

    package private(set) var calls: [Call] = []

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
}
