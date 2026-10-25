import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine rest of day skip")
struct EngineRestOfDaySkipTests {
    private func bubbles(_ id: HabitID, _ h: EngineHarness) -> Int {
        h.presenter.calls.filter { if case let .showBubble(shown, _) = $0 { return shown == id } else { return false } }.count
    }

    @Test func missedEveningRemindersNeverShowAfterMidnight() {
        let h = EngineHarness(at: day(2026, 3, 4, 19, 30)) {
            $0.prefs.water.enabled = false
            $0.prefs.meditation.enabled = true
        }
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 20, 30))
        h.engine.pauseRestOfDay()
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 5, 22))
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 5, 9))
        h.advance(minutes: 4 * 60 + 30)
        #expect(h.engine.pausedUntil == nil)
        #expect(h.engine.activities.isEmpty)
        h.advance(minutes: 9 * 60 - 1)
        #expect(h.engine.activities.isEmpty)
        #expect(bubbles(.reading, h) == 0)
        #expect(bubbles(.meditation, h) == 0)
    }

    @Test func restOfDayClearsSnoozes() {
        let h = EngineHarness(at: day(2026, 3, 4, 22)) { $0.prefs.water.enabled = false }
        #expect(h.engine.phase(.reading) == .bubble(.nudge))
        h.engine.snooze(.reading)
        h.engine.pauseRestOfDay()
        #expect(h.engine.state(.reading).snoozedUntil == nil)
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 5, 22))
    }

    @Test func missedWaterShowsAtTheNextActiveStart() {
        let h = EngineHarness(at: day(2026, 3, 4, 15)) {
            $0.prefs.reading.enabled = false
            $0.live.lastWaterDone = day(2026, 3, 4, 14, 30)
        }
        h.engine.pauseRestOfDay()
        h.advance(minutes: 9 * 60)
        #expect(h.engine.pausedUntil == nil)
        #expect(bubbles(.water, h) == 0)
        h.advance(minutes: 9 * 60 + 29)
        #expect(bubbles(.water, h) == 0)
        h.advance(minutes: 1)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
    }

    @Test func shortPauseKeepsAMissedReminder() {
        let h = EngineHarness(at: day(2026, 3, 4, 11, 50)) {
            $0.prefs.reading.enabled = false
            $0.live.lastWaterDone = day(2026, 3, 4, 10)
        }
        h.engine.pause(hours: Timing.shortPauseHours)
        h.advance(minutes: 20)
        #expect(h.engine.activities.isEmpty)
        #expect(bubbles(.water, h) == 0)
        h.advance(minutes: 10)
        #expect(h.engine.pausedUntil == nil)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
    }
}
