import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine days off streak")
struct EngineDaysOffStreakTests {
    private let workdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

    private func gymDone(_ days: [Int], into p: inout Persisted) {
        p.live.gymMinutesSince = day(2026, 3, 1)
        p.events = days.map { .done(.gym, 20, at: day(2026, 3, $0, 9)) }
    }

    @Test func gymStreakStaysAcrossAWeekendOff() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) {
            $0.prefs.gym.weekdays = workdays
            gymDone([2, 3, 4, 5, 6], into: &$0)
        }
        #expect(h.engine.streak(.gym) == 5)
    }

    @Test func turningWeekdaysOffUpdatesTheShownStreak() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) { gymDone([2, 3, 4, 5, 6, 9], into: &$0) }
        #expect(h.engine.streak(.gym) == 1)
        h.engine.data.prefs.gym.weekdays = workdays
        #expect(h.engine.streak(.gym) == 6)
    }

    @Test func turningAWeekdayBackOnUpdatesTheShownStreak() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) {
            $0.prefs.gym.weekdays = workdays
            gymDone([2, 3, 4, 5, 6, 9], into: &$0)
        }
        #expect(h.engine.streak(.gym) == 6)
        h.engine.data.prefs.gym.weekdays = Set(Weekday.allCases)
        #expect(h.engine.streak(.gym) == 1)
    }

    @Test func addingADayOffUpdatesTheShownStreak() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) { gymDone([2, 3, 4, 5, 6, 8, 9], into: &$0) }
        #expect(h.engine.streak(.gym) == 2)
        h.engine.data.prefs.gym.daysOff = [DayKey(day(2026, 3, 7), calendar: .current)]
        #expect(h.engine.streak(.gym) == 7)
    }

    @Test func aDayOffOfAnotherHabitNeverChangesTheStreak() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) { gymDone([2, 3, 4, 5, 6, 8, 9], into: &$0) }
        #expect(h.engine.streak(.gym) == 2)
        h.engine.data.prefs.water.daysOff = [DayKey(day(2026, 3, 7), calendar: .current)]
        #expect(h.engine.streak(.gym) == 2)
    }
}
