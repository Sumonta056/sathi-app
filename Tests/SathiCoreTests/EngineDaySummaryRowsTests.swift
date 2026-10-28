import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine day summary rows")
struct EngineDaySummaryRowsTests {
    private var today: DayKey { DayKey(day(2026, 3, 4), calendar: .current) }

    private func status(_ h: EngineHarness, _ id: HabitID) -> DaySummaryStatus? {
        h.engine.daySummary.rows.first { $0.id == id }?.status
    }

    @Test func alwaysFourRowsInHabitOrder() {
        let h = EngineHarness()
        #expect(h.engine.daySummary.rows.map(\.id) == HabitID.allCases)
    }

    @Test func fourRowsEvenWhenEveryHabitIsOff() {
        let h = EngineHarness {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
        }
        #expect(h.engine.daySummary.rows.map(\.id) == HabitID.allCases)
        #expect(h.engine.daySummary.rows.map(\.status) == [.off, .off, .off, .off])
        #expect(h.engine.daySummary.verdict == .restDay)
    }

    @Test func defaultPrefsShowProgressForWaterAndReadingAndOffForTheRest() {
        let h = EngineHarness()
        let readingGoal = Double(h.engine.data.prefs.reading.sessionMinutes)
        #expect(status(h, .water) == .progress(done: 0, goal: 8))
        #expect(status(h, .reading) == .progress(done: 0, goal: readingGoal))
        #expect(status(h, .meditation) == .off)
        #expect(status(h, .gym) == .off)
    }

    @Test func waterLogsCountTowardTheGoal() {
        let h = EngineHarness {
            $0.prefs.water.dailyGoalGlasses = 6
            $0.events = [.done(.water, 2, at: day(2026, 3, 4, 8)), .done(.water, 1.5, at: day(2026, 3, 4, 9))]
        }
        #expect(status(h, .water) == .progress(done: 3.5, goal: 6))
    }

    @Test func aGlassLoggedNowUpdatesTheRow() {
        let h = EngineHarness()
        h.engine.logWater(1)
        h.engine.logWater(1)
        #expect(status(h, .water) == .progress(done: 2, goal: 8))
    }

    @Test func yesterdayDoesNotCount() {
        let h = EngineHarness { $0.events = [.done(.water, 5, at: day(2026, 3, 3, 20))] }
        #expect(status(h, .water) == .progress(done: 0, goal: 8))
    }

    @Test func aDayOffWithTheGoalNotMetIsDayOff() {
        let h = EngineHarness {
            $0.prefs.water.daysOff = [today]
            $0.events = [.done(.water, 3, at: day(2026, 3, 4, 8))]
        }
        #expect(status(h, .water) == .dayOff)
        #expect(status(h, .reading) == .progress(done: 0, goal: Double(h.engine.data.prefs.reading.sessionMinutes)))
    }

    @Test func aWeekdayOffWithNothingDoneIsDayOff() {
        let h = EngineHarness {
            $0.prefs.reading.weekdays = Set(Weekday.allCases).subtracting([.wednesday])
        }
        #expect(status(h, .reading) == .dayOff)
    }

    @Test func aDayOffWithTheGoalMetIsProgress() {
        let goal = Double(Limits.gymDailyGoal)
        let h = EngineHarness {
            $0.prefs.gym.enabled = true
            $0.prefs.gym.daysOff = [today]
            $0.events = (0 ..< Limits.gymDailyGoal).map { .done(.gym, 1, at: day(2026, 3, 4, 8, $0)) }
        }
        #expect(status(h, .gym) == .progress(done: goal, goal: goal))
    }

    @Test func anOffHabitWithLogsIsStillOff() {
        let h = EngineHarness {
            $0.prefs.water.enabled = false
            $0.events = [.done(.water, 8, at: day(2026, 3, 4, 8))]
        }
        #expect(status(h, .water) == .off)
    }

    @Test func meditationUsesItsMinutesGoal() {
        let h = EngineHarness {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.dailyGoalMinutes = 12
            $0.events = [.done(.meditation, 5, at: day(2026, 3, 4, 9))]
        }
        #expect(status(h, .meditation) == .progress(done: 5, goal: 12))
    }

    @Test func eachRowCarriesTheHabitStreak() {
        let h = EngineHarness {
            $0.prefs.gym.enabled = true
            $0.events = (1 ... 3).map { .done(.water, 8, at: day(2026, 3, 4 - $0, 12)) }
        }
        #expect(h.engine.streak(.water) > 0)
        for row in h.engine.daySummary.rows {
            #expect(row.streak == h.engine.streak(row.id))
        }
        #expect(h.engine.daySummary.rows.first?.streak == h.engine.streak(.water))
    }

    @Test func theVerdictFollowsTheRows() {
        let h = EngineHarness {
            $0.prefs.reading.enabled = false
            $0.events = [.done(.water, 8, at: day(2026, 3, 4, 9))]
        }
        #expect(h.engine.daySummary.verdict == .allMet)
    }
}
