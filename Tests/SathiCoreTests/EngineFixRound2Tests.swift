import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine fix round 2")
struct EngineFixRound2Tests {
    @Test func restartingAMenuStartedSessionStillStopsWithoutASnooze() {
        let h = EngineHarness(at: day(2026, 3, 4, 15)) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.meditation.enabled = true
            $0.events = [.done(.meditation, 5, at: day(2026, 3, 4, 8, 5))]
        }
        h.engine.startMeditation()
        h.engine.startMeditation()
        h.engine.stopSession()
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.meditation).snoozes == 0)
        #expect(!h.history.appended.contains { $0.kind == .snooze })
        h.advance(minutes: 10)
        #expect(!h.presenter.calls.contains(.showBubble(.meditation, .nudge)))
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 21, 30))
    }

    @Test func turningAHabitBackOnDropsAStaleSnooze() {
        let h = EngineHarness(at: day(2026, 3, 4, 8)) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.meditation.enabled = true
        }
        #expect(h.engine.phase == .bubble(.meditation, .nudge))
        h.engine.snooze()
        h.advance(minutes: 3)
        h.engine.data.prefs.meditation.enabled = false
        h.advance(minutes: 477)
        h.engine.data.prefs.meditation.enabled = true
        h.engine.tick()
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.meditation).snoozedUntil == nil)
        #expect(h.engine.state(.meditation).snoozes == 0)
        #expect(h.engine.state(.meditation).nextDue == day(2026, 3, 4, 21, 30))
    }

    @Test func readingBackOnAfterASnoozeWaitsForItsNextTime() {
        let h = EngineHarness(at: day(2026, 3, 4, 22)) {
            $0.prefs.water.enabled = false
        }
        #expect(h.engine.phase == .bubble(.reading, .nudge))
        h.engine.snooze()
        h.engine.data.prefs.reading.enabled = false
        h.advance(minutes: 30)
        h.engine.data.prefs.reading.enabled = true
        h.engine.tick()
        #expect(h.engine.phase == .idle)
        #expect(h.engine.state(.reading).snoozedUntil == nil)
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 5, 22))
    }
}
