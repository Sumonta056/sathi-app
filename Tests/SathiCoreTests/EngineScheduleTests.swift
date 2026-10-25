import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine schedule")
struct EngineScheduleTests {
    @Test func waterDoesNotRemindOutsideHours() {
        let h = EngineHarness(at: day(2026, 3, 4, 17, 0))
        h.advance(minutes: 120)
        #expect(h.engine.activities.isEmpty)
    }

    @Test func everyHabitHasAStateAfterInit() {
        let h = EngineHarness()
        #expect(Set(h.engine.habits.keys) == Set(HabitID.allCases))
    }

    @Test func changingTheIntervalReschedules() {
        let h = EngineHarness()
        h.engine.data.prefs.water.intervalMinutes = 30
        #expect(h.engine.state(.water).nextDue == day(2026, 3, 4, 10, 30))
    }

    @Test func reschedulingAfterMidnightUsesTheNewDay() {
        let h = EngineHarness(at: day(2026, 3, 4, 23, 59)) {
            $0.events = [.done(.reading, 15, at: day(2026, 3, 4, 22, 15))]
        }
        h.clock.advance(minutes: 1)
        h.engine.data.prefs.reading.timeMinutes = 21 * 60
        #expect(h.engine.state(.reading).nextDue == day(2026, 3, 5, 21))
    }
}
