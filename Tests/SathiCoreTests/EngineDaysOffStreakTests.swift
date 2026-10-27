import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine days off streak")
struct EngineDaysOffStreakTests {
    private let workdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

    private func gymDone(_ days: [Int]) -> [HistoryEvent] {
        days.map { .done(.gym, 4, at: day(2026, 3, $0, 9)) }
    }

    @Test func gymStreakStaysAcrossAWeekendOff() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) {
            $0.prefs.gym.weekdays = workdays
            $0.events = gymDone([2, 3, 4, 5, 6])
        }
        #expect(h.engine.streak(.gym) == 5)
        #expect(h.engine.longestStreak(.gym) == 5)
    }

    @Test func turningWeekdaysOffUpdatesTheShownStreak() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) { $0.events = gymDone([2, 3, 4, 5, 6, 9]) }
        #expect(h.engine.streak(.gym) == 1)
        #expect(h.engine.longestStreak(.gym) == 5)
        h.engine.data.prefs.gym.weekdays = workdays
        #expect(h.engine.streak(.gym) == 6)
        #expect(h.engine.longestStreak(.gym) == 6)
    }

    @Test func turningAWeekdayBackOnUpdatesTheShownStreak() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) {
            $0.prefs.gym.weekdays = workdays
            $0.events = gymDone([2, 3, 4, 5, 6, 9])
        }
        #expect(h.engine.streak(.gym) == 6)
        h.engine.data.prefs.gym.weekdays = Set(Weekday.allCases)
        #expect(h.engine.streak(.gym) == 1)
    }

    @Test func addingADayOffUpdatesTheShownStreak() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) { $0.events = gymDone([2, 3, 4, 5, 6, 8, 9]) }
        #expect(h.engine.streak(.gym) == 2)
        h.engine.data.prefs.gym.daysOff = [DayKey(day(2026, 3, 7), calendar: .current)]
        #expect(h.engine.streak(.gym) == 7)
        #expect(h.engine.longestStreak(.gym) == 7)
    }

    @Test func aDayOffOfAnotherHabitNeverChangesTheStreak() {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) { $0.events = gymDone([2, 3, 4, 5, 6, 8, 9]) }
        #expect(h.engine.streak(.gym) == 2)
        h.engine.data.prefs.water.daysOff = [DayKey(day(2026, 3, 7), calendar: .current)]
        #expect(h.engine.streak(.gym) == 2)
    }
}
