import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine session log edges")
struct EngineSessionLogEdgeTests {
    private func harness(trackerOn: Bool, at start: Date) -> EngineHarness {
        EngineHarness.tracker(at: start) {
            $0.prefs.tracker.isOn = trackerOn
            $0.prefs.reading.enabled = true
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.sessionMinutes = 10
            $0.prefs.gym.enabled = true
        }
    }

    private func rows(_ h: EngineHarness, _ id: HabitID) -> [Activity] {
        h.saved.filter { $0.kind == .buddy && $0.category == ActivityCategory.buddy(id).name }
    }

    @Test func pausedInsideHoursResumedAfterLogsOne() {
        let h = harness(trackerOn: true, at: wed(17, 50))
        h.engine.startSession(.meditation)
        h.clock.advance(minutes: 5)
        h.engine.pauseSession(.meditation)
        h.clock.advance(minutes: 25)
        h.engine.resumeSession(.meditation)
        h.clock.advance(minutes: 5)
        h.engine.finishSession(.meditation)
        #expect(rows(h, .meditation).count == 1)
    }

    @Test func pausedBeforeHoursResumedInsideLogsOne() {
        let h = harness(trackerOn: true, at: wed(8, 55))
        h.engine.startSession(.meditation)
        h.clock.advance(minutes: 3)
        h.engine.pauseSession(.meditation)
        h.clock.advance(minutes: 12)
        h.engine.resumeSession(.meditation)
        h.clock.advance(minutes: 7)
        h.engine.finishSession(.meditation)
        #expect(rows(h, .meditation).count == 1)
    }

    @Test func trackerTurnedOffMidSessionLogsNoSecondRow() {
        let h = harness(trackerOn: true, at: wed(10))
        h.engine.startSession(.gym)
        h.clock.advance(minutes: 2)
        h.engine.data.prefs.tracker.isOn = false
        h.clock.advance(minutes: 3)
        h.engine.finishSession(.gym)
        #expect(rows(h, .gym).count == 1)
    }

    @Test func trackerTurnedOnMidSessionStillLogs() {
        let h = harness(trackerOn: false, at: wed(10))
        h.engine.startSession(.gym)
        h.clock.advance(minutes: 2)
        h.engine.data.prefs.tracker.isOn = true
        h.clock.advance(minutes: 3)
        h.engine.finishSession(.gym)
        #expect(rows(h, .gym).count == 1)
        #expect(rows(h, .gym).first?.start == wed(10))
    }

    @Test func aSecondBuddyInterruptsWithNoDuplicate() {
        let h = harness(trackerOn: true, at: wed(10))
        h.engine.startSession(.gym)
        h.clock.advance(minutes: 2)
        h.engine.startSession(.meditation)
        h.clock.advance(minutes: 1)
        h.engine.finishSession(.gym)
        #expect(rows(h, .gym).count == 1)
    }

    @Test func sleepPastTheTimerEndCutsAtTheSessionEnd() {
        let h = harness(trackerOn: false, at: wed(21))
        h.engine.startSession(.reading)
        h.advance(minutes: 150)
        #expect(h.engine.session(.reading) == nil)
        #expect(rows(h, .reading).first?.end == wed(21, 15))
    }
}
