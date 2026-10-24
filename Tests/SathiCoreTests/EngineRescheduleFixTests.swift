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

    @Test func enablingMeditationLateNeverFiresAPastSlot() {
        let h = harness(at: day(2026, 3, 4, 23)) { $0.prefs.reading.enabled = false }
        h.engine.data.prefs.meditation.enabled = true
        h.engine.tick()
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 5, 8))
        h.advance(minutes: 30)
        #expect(!h.presenter.calls.contains(.showBubble(.meditation, .nudge)))
    }

    @Test func addingAPastSlotWaitsForTheNextSlot() {
        let h = harness(at: day(2026, 3, 4, 16)) {
            $0.prefs.meditation.enabled = true
            $0.events = [.done(.meditation, 5, at: day(2026, 3, 4, 8, 5))]
        }
        #expect(h.engine.phase == .idle)
        h.engine.data.prefs.meditation.slots.insert(.afternoon)
        h.engine.tick()
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 21, 30))
    }

    @Test func movingReadingEarlierThanNowWaitsForTomorrow() {
        let h = EngineHarness()
        h.engine.data.prefs.reading.timeMinutes = 9 * 60
        h.engine.tick()
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 5, 9))
    }

    @Test func removingAllSlotsWhileSnoozedNeverFiresAgain() {
        let h = harness(at: day(2026, 3, 4, 15)) { $0.prefs.meditation.enabled = true }
        #expect(h.engine.phase == .bubble(.meditation, .nudge))
        h.engine.snooze()
        h.engine.data.prefs.meditation.slots = []
        #expect(h.engine.state(.meditation).snoozedUntil == nil)
        #expect(h.engine.state(.meditation).nextDue == .distantFuture)
        h.advance(minutes: 10)
        #expect(h.engine.phase == .idle)
        #expect(!h.engine.queue.contains(.meditation))
        #expect(h.presenter.calls.filter { $0 == .showBubble(.meditation, .nudge) }.count == 1)
    }

    @Test func removingAllSlotsDropsMeditationFromTheQueue() {
        let h = harness(at: day(2026, 3, 4, 15)) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = day(2026, 3, 4, 13)
        }
        #expect(h.engine.phase == .bubble(.water, .nudge))
        #expect(h.engine.queue == [.meditation])
        h.engine.data.prefs.meditation.slots = []
        #expect(h.engine.queue.isEmpty)
    }

    @Test func launchWithAMissedSlotIsStillDueNow() {
        let h = harness(at: day(2026, 3, 4, 15)) { $0.prefs.meditation.enabled = true }
        #expect(h.engine.phase == .bubble(.meditation, .nudge))
    }

    @Test func meditationWithNoSlotsHasNoStreak() {
        let h = harness(at: day(2026, 3, 4, 15)) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.slots = []
        }
        #expect(h.engine.streak(.meditation) == 0)
    }
}
