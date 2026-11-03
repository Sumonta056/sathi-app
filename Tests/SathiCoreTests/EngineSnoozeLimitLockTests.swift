import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine snooze limit lock")
struct EngineSnoozeLimitLockTests {
    private func twoStrictHabits(limit: Int) -> EngineHarness {
        let h = EngineHarness {
            $0.prefs.general.snoozeLimit = limit
            $0.prefs.general.snoozeMinutes = 5
            $0.prefs.general.ignoreMinutes = 30
            $0.prefs.water.strictness = .strict
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.strictness = .strict
        }
        h.showReminder(.meditation)
        snoozeAndReturn(h, .meditation)
        snoozeAndReturn(h, .meditation)
        h.showReminder(.water)
        snoozeAndReturn(h)
        snoozeAndReturn(h)
        return h
    }

    @Test func aHabitThatWaitsForTheLockHasNoSnoozeLeft() {
        let h = twoStrictHabits(limit: 2)
        #expect(h.engine.phase(.meditation) == .lock)
        #expect(h.engine.phase(.water) == .bubble(.persist))
        #expect(!h.engine.canSnooze(.water))
    }

    @Test func itLocksWhenTheOtherLockEnds() {
        let h = twoStrictHabits(limit: 2)
        h.engine.emergencySkip(.meditation)
        h.advance(minutes: 0)
        #expect(h.engine.phase(.water) == .lock)
        #expect(h.presenter.calls.contains(.showLock(.water)))
    }

    @Test func withSnoozesLeftItStillWaitsForALaterSnooze() {
        let h = twoStrictHabits(limit: 5)
        h.engine.emergencySkip(.meditation)
        h.advance(minutes: 0)
        #expect(h.engine.phase(.water) == .bubble(.persist))
    }
}
