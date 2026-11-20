import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine session log")
struct EngineSessionLogTests {
    private func harness(trackerOn: Bool = false, at start: Date = wed(10)) -> EngineHarness {
        EngineHarness.tracker(at: start) {
            $0.prefs.tracker.isOn = trackerOn
            $0.prefs.reading.enabled = true
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
        }
    }

    @Test func trackerOffFinishedGymLogsOneBuddyActivity() {
        let h = harness()
        h.engine.startSession(.gym)
        let text = "Gym · " + h.engine.gymIdeaText
        h.clock.advance(minutes: 5)
        h.engine.finishSession(.gym)
        #expect(h.saved.count == 1)
        let a = h.saved.first
        #expect(a?.kind == .buddy)
        #expect(a?.category == "Gym")
        #expect(a?.text == text)
        #expect(a?.start == wed(10))
        #expect(a?.end == wed(10, 5))
        #expect(a?.calendarID == nil)
    }

    @Test func trackerOffTimerEndLogsTheMeditation() {
        let h = harness()
        h.engine.startSession(.meditation)
        h.advance(minutes: Double(h.store.prefs.meditation.sessionMinutes) + 1)
        #expect(h.engine.session(.meditation) == nil)
        #expect(h.saved.map(\.text) == ["Breathing · Calm 4·6"])
    }

    @Test func trackerOffStoppedSessionLogsNothing() {
        let h = harness()
        h.engine.startSession(.reading)
        h.clock.advance(minutes: 3)
        h.engine.stopSession(.reading)
        #expect(h.saved.isEmpty)
    }

    @Test func trackerOnInsideHoursLogsExactlyOne() {
        let h = harness(trackerOn: true)
        h.engine.startSession(.gym)
        h.clock.advance(minutes: 5)
        h.engine.finishSession(.gym)
        #expect(h.saved.filter { $0.kind == .buddy }.count == 1)
    }

    @Test func trackerOnStartedBeforeHoursLogsOne() {
        let h = harness(trackerOn: true, at: wed(8, 58))
        h.engine.startSession(.gym)
        h.clock.advance(minutes: 5)
        h.engine.finishSession(.gym)
        #expect(h.saved.filter { $0.kind == .buddy }.count == 1)
        #expect(h.saved.first?.start == wed(8, 58))
        #expect(h.saved.first?.end == wed(9, 3))
    }

    @Test func sessionPastMidnightEndsAtMidnight() {
        let h = harness(at: wed(23, 55))
        h.engine.startSession(.gym)
        h.clock.advance(minutes: 10)
        h.engine.finishSession(.gym)
        #expect(h.saved.first?.start == wed(23, 55))
        #expect(h.saved.first?.end == day(2026, 3, 5, 0, 0))
    }

    @Test func trackerOffAddsTheBuddyCategory() {
        let h = harness()
        h.engine.startSession(.gym)
        h.clock.advance(minutes: 5)
        h.engine.finishSession(.gym)
        #expect(h.engine.activityCategories.contains(ActivityCategory.buddy(.gym)))
    }

    @Test func doNowStartsGym() {
        let h = harness()
        h.engine.doNow(.gym)
        #expect(h.presenter.calls.contains(.showSession(.gym)))
    }

    @Test func doNowDoesNothingWhileASessionRuns() {
        let h = harness()
        h.engine.doNow(.gym)
        h.clock.advance(minutes: 1)
        h.engine.doNow(.gym)
        #expect(h.engine.session(.gym)?.start == wed(10))
    }

    @Test func doNowDoesNothingForAnOffBuddyOrWater() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.isOn = false }
        h.engine.doNow(.gym)
        h.engine.doNow(.water)
        #expect(h.engine.session(.gym) == nil)
        #expect(h.engine.glassesToday == 0)
    }
}
