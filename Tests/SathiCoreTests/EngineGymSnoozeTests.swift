import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine gym snooze")
struct EngineGymSnoozeTests {
    private func snoozeEnd(_ h: EngineHarness, from start: Date) -> Date {
        start.addingTimeInterval(TimeInterval(h.engine.data.prefs.general.snoozeMinutes) * Timing.minute)
    }

    @Test func ignoredPopupIsANormalSnooze() {
        let h = gymAtTen()
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        h.advance(minutes: Double(h.engine.data.prefs.general.ignoreMinutes))
        let ignoredAt = h.clock.now
        #expect(h.engine.activities[.gym] == nil)
        #expect(h.engine.state(.gym).snoozes == 1)
        #expect(h.history.appended.last == .snooze(.gym, at: ignoredAt))
        #expect(h.engine.state(.gym).snoozedUntil == snoozeEnd(h, from: ignoredAt))
        #expect(h.presenter.calls.contains(.showSnoozed(.gym, snoozeEnd(h, from: ignoredAt))))
    }

    @Test func ignoredPopupComesBackAfterTheSnoozeLength() {
        let h = gymAtTen { $0.prefs.gym.strictness = .persistent }
        h.advance(minutes: Double(h.engine.data.prefs.general.ignoreMinutes))
        #expect(h.engine.activities[.gym] == nil)
        h.advance(minutes: Double(h.engine.data.prefs.general.snoozeMinutes))
        #expect(h.engine.phase(.gym) == .bubble(.persist))
    }

    @Test func twoIgnoresAtStrictLeadToTheLock() {
        let h = gymAtTen { $0.prefs.gym.strictness = .strict }
        let ignore = Double(h.engine.data.prefs.general.ignoreMinutes)
        let snooze = Double(h.engine.data.prefs.general.snoozeMinutes)
        h.advance(minutes: ignore)
        h.advance(minutes: snooze)
        #expect(h.engine.phase(.gym) == .bubble(.persist))
        h.advance(minutes: ignore)
        #expect(h.engine.state(.gym).snoozes == 2)
        h.advance(minutes: snooze)
        #expect(h.engine.phase(.gym) == .lock)
        #expect(h.presenter.calls.last == .showLock(.gym))
        #expect(h.history.appended.filter { $0.habit == .gym && $0.kind == .snooze }.count == 2)
    }

    @Test func snoozeButtonIsANormalSnooze() {
        let h = gymAtTen { $0.prefs.gym.strictness = .persistent }
        h.engine.snooze(.gym)
        #expect(h.engine.state(.gym).snoozes == 1)
        #expect(h.engine.state(.gym).snoozedUntil == snoozeEnd(h, from: day(2026, 3, 4, 10)))
        h.advance(minutes: Double(h.engine.data.prefs.general.snoozeMinutes))
        #expect(h.engine.phase(.gym) == .bubble(.persist))
    }

    @Test func snoozeLeavesOtherHabitsAlone() {
        let h = gymHarness(at: day(2026, 3, 4, 9)) {
            $0.prefs.water.enabled = true
            $0.live.lastWaterDone = day(2026, 3, 4, 8)
        }
        h.advance(minutes: 60)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        let waterDeadline = deadline(h, .water)
        let waterState = h.engine.state(.water)
        h.engine.snooze(.gym)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(deadline(h, .water) == waterDeadline)
        #expect(h.engine.state(.water) == waterState)
        #expect(!h.history.appended.contains { $0.habit == .water })
    }

    @Test func snoozeSurvivesASettingsChange() {
        let h = gymAtTen { $0.events = [.done(.gym, 1, at: day(2026, 3, 4, 8, 59))] }
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
        h.engine.snooze(.gym)
        let shows = h.presenter.calls.count { $0 == .showBubble(.gym, .nudge) }
        h.advance(minutes: 1)
        h.engine.data.prefs.water.intervalMinutes = 90
        h.engine.tick()
        h.advance(minutes: Double(h.engine.data.prefs.general.snoozeMinutes) - 2)
        #expect(h.presenter.calls.count { $0 == .showBubble(.gym, .nudge) } == shows)
        #expect(h.engine.activities[.gym] == nil)
        h.advance(minutes: 1)
        #expect(h.engine.phase(.gym) == .bubble(.nudge))
    }

    @Test func snoozeForgetsTheShownIdea() {
        let h = gymAtTen()
        h.engine.nextGymIdea()
        h.engine.snooze(.gym)
        #expect(h.engine.gymIdea == 0)
        #expect(h.engine.gymWorkout.name == "Neck and shoulder stretch")
    }

    @Test func ignoreForgetsTheShownIdea() {
        let h = gymAtTen()
        h.engine.nextGymIdea()
        h.advance(minutes: Double(h.engine.data.prefs.general.ignoreMinutes))
        #expect(h.engine.gymIdea == 0)
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
