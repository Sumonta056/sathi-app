import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine independence")
struct EngineIndependenceTests {
    private func harness() -> EngineHarness {
        EngineHarness(at: day(2026, 3, 4, 15)) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = day(2026, 3, 4, 14, 59)
        }
    }

    private func shown(_ h: EngineHarness, _ id: HabitID) -> Bool {
        h.presenter.calls.contains(.showBubble(id, .nudge))
    }

    @Test func eachHabitShowsWhileAnotherReminderIsOpen() {
        let h = harness()
        h.showReminder(.water)
        h.showReminder(.reading)
        h.showReminder(.meditation)
        #expect(shown(h, .water))
        #expect(shown(h, .reading))
        #expect(shown(h, .meditation))
    }

    @Test func aReminderShowsWhileASessionRuns() {
        let h = harness()
        h.engine.startReading()
        h.showReminder(.meditation)
        #expect(shown(h, .meditation))
    }

    @Test func aReminderShowsWhileACelebrationShows() {
        let h = harness()
        h.engine.logWater(1)
        h.showReminder(.reading)
        #expect(shown(h, .reading))
        #expect(!h.presenter.calls.contains(.closeCelebration))
    }

    @Test func ignoringOneReminderSnoozesOnlyThatHabit() {
        let h = harness()
        #expect(h.presenter.calls.isEmpty)
        h.showReminder(.water)
        h.advance(minutes: 3)
        h.showReminder(.reading)
        h.advance(minutes: 2)
        #expect(h.engine.state(.water).snoozes == 1)
        #expect(h.engine.state(.reading).snoozes == 0)
        h.advance(minutes: 3)
        #expect(h.engine.state(.reading).snoozes == 1)
    }

    @Test func dueHabitsShowTogetherAtTheSameTick() {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59)) {
            $0.prefs.water.endMinutes = 23 * 60
            $0.live.lastWaterDone = day(2026, 3, 4, 20)
        }
        h.advance(minutes: 1)
        #expect(shown(h, .water))
        #expect(shown(h, .reading))
    }

    @Test func turningAHabitOffClosesOnlyItsReminder() {
        let h = harness()
        h.showReminder(.water)
        h.showReminder(.reading)
        h.engine.data.prefs.reading.enabled = false
        #expect(h.engine.phase(.reading) == .idle)
        #expect(h.presenter.calls.contains(.closeBubble(.reading)))
        #expect(h.engine.phase(.water) == .bubble(.nudge))
    }

    @Test func twoSessionsRunAndStopIndependently() {
        let h = harness()
        h.engine.startReading()
        h.engine.startMeditation()
        h.engine.stopSession(.reading)
        #expect(h.engine.phase(.reading) == .idle)
        #expect(h.engine.phase(.meditation) == .session)
        #expect(!h.presenter.calls.contains(.closeSession(.meditation)))
    }

    @Test func restOfDayClosesOpenRemindersWithoutASnooze() {
        let h = harness()
        h.showReminder(.water)
        h.engine.pauseRestOfDay()
        #expect(h.engine.activities.isEmpty)
        #expect(h.presenter.calls.contains(.closeBubble(.water)))
        #expect(h.engine.state(.water).snoozes == 0)
        h.advance(minutes: 10 * 60)
        #expect(h.presenter.calls.filter { $0 == .showBubble(.water, .nudge) }.count == 1)
    }
}
