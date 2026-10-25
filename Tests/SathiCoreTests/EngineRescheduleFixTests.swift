import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine reschedule fixes")
struct EngineRescheduleFixTests {
    private func harness(at start: Date, configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness(at: start) {
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
            configure(&$0)
        }
    }

    @Test func enablingMeditationAfterTheEndWaitsForTomorrowsStart() {
        let h = harness(at: day(2026, 3, 4, 23)) { $0.prefs.reading.enabled = false }
        h.engine.data.prefs.meditation.enabled = true
        h.engine.tick()
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 5, 9))
        h.advance(minutes: 30)
        #expect(!h.presenter.calls.contains(.showBubble(.meditation, .nudge)))
    }

    @Test func aLongerIntervalMovesTheNextReminderLater() {
        let h = harness(at: day(2026, 3, 4, 16)) {
            $0.prefs.meditation.enabled = true
            $0.events = [.done(.meditation, 2, at: day(2026, 3, 4, 15, 30))]
        }
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 16, 30))
        h.engine.data.prefs.meditation.intervalMinutes = 90
        h.engine.tick()
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 17))
    }

    @Test func movingReadingEarlierThanNowWaitsForTomorrow() {
        let h = EngineHarness()
        h.engine.data.prefs.reading.timeMinutes = 9 * 60
        h.engine.tick()
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 5, 9))
    }

    @Test func aLaterStartWhileSnoozedClearsTheSnoozeAndWaitsForTheStart() {
        let h = harness(at: day(2026, 3, 4, 15)) {
            $0.prefs.meditation.enabled = true
            $0.events = [.done(.meditation, 2, at: day(2026, 3, 4, 13, 30))]
        }
        #expect(h.engine.phase(.meditation) == .bubble(.nudge))
        h.engine.snooze(.meditation)
        h.engine.data.prefs.meditation.startMinutes = 17 * 60
        #expect(h.engine.state(.meditation).snoozedUntil == nil)
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 17))
        h.advance(minutes: 10)
        #expect(h.engine.activities.isEmpty)
        #expect(h.presenter.calls.filter { $0 == .showBubble(.meditation, .nudge) }.count == 1)
    }

    @Test func aLaterMeditationStartLeavesTheWaterReminderAlone() {
        let h = harness(at: day(2026, 3, 4, 15)) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = day(2026, 3, 4, 13)
            $0.events = [.done(.meditation, 2, at: day(2026, 3, 4, 13, 30))]
        }
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.engine.phase(.meditation) == .bubble(.nudge))
        h.engine.data.prefs.meditation.startMinutes = 17 * 60
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(!h.presenter.calls.contains(.closeBubble(.water)))
    }

    @Test func launchWithAMissedReminderIsStillDueNow() {
        let h = harness(at: day(2026, 3, 4, 15)) {
            $0.prefs.meditation.enabled = true
            $0.events = [.done(.meditation, 2, at: day(2026, 3, 4, 13, 30))]
        }
        #expect(h.engine.phase(.meditation) == .bubble(.nudge))
    }

    @Test func meditationWithAZeroGoalHasNoStreak() {
        let h = harness(at: day(2026, 3, 4, 15)) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.dailyGoalMinutes = 0
            $0.events = [.done(.meditation, 5, at: day(2026, 3, 3, 10)), .done(.meditation, 5, at: day(2026, 3, 4, 10))]
        }
        #expect(h.engine.streak(.meditation) == 0)
    }
}
