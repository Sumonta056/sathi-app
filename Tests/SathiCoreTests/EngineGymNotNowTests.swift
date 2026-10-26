import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine gym not now")
struct EngineGymNotNowTests {
    @Test func closeIsNotNowAndComesBackNextInterval() {
        let h = gymAtTen()
        h.engine.notNow(.gym)
        #expect(h.history.appended.last == .snooze(.gym, at: day(2026, 3, 4, 10)))
        #expect(h.engine.state(.gym).nextDue == day(2026, 3, 4, 11))
        #expect(h.engine.state(.gym).snoozes == 0)
        #expect(h.engine.state(.gym).snoozedUntil == day(2026, 3, 4, 11))
        #expect(h.engine.activities[.gym] == nil)
        #expect(h.presenter.calls.contains(.showSnoozed(.gym, day(2026, 3, 4, 11))))
    }

    @Test func ignoredPopupComesBackNextIntervalAtGentle() {
        let h = gymHarness(at: day(2026, 3, 4, 9)) {
            $0.prefs.general.ignoreMinutes = 5
            $0.prefs.gym.strictness = .persistent
        }
        h.advance(minutes: 60)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        h.advance(minutes: 5)
        #expect(h.engine.activities[.gym] == nil)
        let shows = h.presenter.calls.filter { $0 == .showBubble(.gym, .nudge) }.count
        h.advance(minutes: 50)
        #expect(h.engine.activities[.gym] == nil)
        h.advance(minutes: 10)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        #expect(h.presenter.calls.filter { $0 == .showBubble(.gym, .nudge) }.count == shows + 1)
        #expect(!h.presenter.calls.contains(.showBubble(.gym, .persist)))
    }

    @Test func snoozeButtonIsANormalSnooze() {
        let h = gymAtTen { $0.prefs.gym.strictness = .persistent }
        h.engine.snooze(.gym)
        let until = day(2026, 3, 4, 10).addingTimeInterval(TimeInterval(h.engine.data.prefs.general.snoozeMinutes) * Timing.minute)
        #expect(h.engine.state(.gym).snoozedUntil == until)
        h.advance(minutes: Double(h.engine.data.prefs.general.snoozeMinutes))
        #expect(h.engine.phase(.gym) == .bubble(.persist))
    }

    @Test func notNowLeavesOtherHabitsAlone() {
        let h = gymHarness(at: day(2026, 3, 4, 9)) {
            $0.prefs.water.enabled = true
            $0.live.lastWaterDone = day(2026, 3, 4, 8)
        }
        h.advance(minutes: 60)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        let waterDeadline = deadline(h, .water)
        let waterState = h.engine.state(.water)
        h.engine.notNow(.gym)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(deadline(h, .water) == waterDeadline)
        #expect(h.engine.state(.water) == waterState)
        #expect(!h.history.appended.contains { $0.habit == .water })
    }

    @Test func notNowSurvivesASettingsChange() {
        let h = gymAtTen { $0.events = [.done(.gym, 1, at: day(2026, 3, 4, 8, 59))] }
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        h.engine.notNow(.gym)
        let shows = h.presenter.calls.count { $0 == .showBubble(.gym, .nudge) }
        h.advance(minutes: 10)
        h.engine.data.prefs.water.intervalMinutes = 90
        h.engine.tick()
        h.advance(minutes: 49)
        #expect(h.presenter.calls.count { $0 == .showBubble(.gym, .nudge) } == shows)
        #expect(h.engine.activities[.gym] == nil)
        h.advance(minutes: 1)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
    }

    @Test func notNowForgetsTheShownIdea() {
        let h = gymAtTen()
        h.engine.nextGymIdea()
        h.engine.notNow(.gym)
        #expect(h.engine.gymIdea == 0)
        #expect(h.engine.gymWorkout.name == "Neck and shoulder stretch")
    }

    @Test func snoozeForgetsTheShownIdea() {
        let h = gymAtTen()
        h.engine.nextGymIdea()
        h.engine.snooze(.gym)
        #expect(h.engine.gymWorkout.name == "Neck and shoulder stretch")
    }

    @Test func stopSessionForgetsTheShownIdea() {
        let h = gymAtTen()
        h.engine.nextGymIdea()
        h.engine.nextGymIdea()
        h.engine.startSession(.gym)
        h.engine.stopSession(.gym)
        #expect(h.engine.gymIdea == 0)
        #expect(h.engine.gymWorkout == h.engine.data.prefs.gym.workout(at: 0))
    }
}
