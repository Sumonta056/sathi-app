import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Report days off")
struct ReportDaysOffTests {
    private let zone = FixedZone.berlin
    private let workdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
    private var sundayNight: Date { zone.date(2026, 3, 8, 23) }

    private func gymPrefs(_ weekdays: Set<Weekday>, off: [String] = []) -> Prefs {
        var p = Prefs()
        p.gym.weekdays = weekdays
        p.gym.daysOff = Set(off.compactMap { DayKey(raw: $0) })
        return p
    }

    private func gym(_ amounts: [Int: Double]) -> [HistoryEvent] {
        amounts.map { .done(.gym, $0.value, at: zone.date(2026, 3, $0.key, 12)) }
    }

    private func habit(_ id: HabitID, _ range: ReportRange, now: Date, _ events: [HistoryEvent], prefs: Prefs) throws -> HabitReport {
        let report = ReportBuilder(calendar: zone.calendar).build(range, now: now, events: events, prefs: prefs)
        return try #require(report.habits.first { $0.habit == id })
    }

    private var workweek: [Int: Double] { [2: 4, 3: 4, 4: 4, 5: 4, 6: 4] }

    @Test func weekPercentIgnoresOffDays() throws {
        let r = try habit(.gym, .week, now: sundayNight, gym(workweek), prefs: gymPrefs(workdays))
        #expect(r.percentOfGoal == 100)
        #expect(r.averagePerDay == 4)
        #expect(r.daysMet == 5)
    }

    @Test func aMetOffDayCountsAsMet() throws {
        var amounts = workweek
        amounts[7] = 6
        let r = try habit(.gym, .week, now: sundayNight, gym(amounts), prefs: gymPrefs(workdays))
        #expect(r.averagePerDay == 26.0 / 6.0)
        #expect(r.percentOfGoal == 100)
        #expect(r.daysMet == 6)
    }

    @Test func anUnmetOffDayIsLeftOut() throws {
        var amounts = workweek
        amounts[8] = 2
        let r = try habit(.gym, .week, now: sundayNight, gym(amounts), prefs: gymPrefs(workdays))
        #expect(r.averagePerDay == 4)
        #expect(r.percentOfGoal == 100)
        #expect(r.daysMet == 5)
    }

    @Test func anUnmetOnDayStillLowersTheNumbers() throws {
        let r = try habit(.gym, .week, now: sundayNight, gym([2: 4, 3: 4, 4: 4, 5: 4]), prefs: gymPrefs(workdays))
        #expect(r.averagePerDay == 16.0 / 5.0)
        #expect(r.percentOfGoal == 80)
        #expect(r.daysMet == 4)
    }

    @Test func noCountedDayGivesAnAverageOfZero() throws {
        let r = try habit(.gym, .day, now: sundayNight, gym([8: 2]), prefs: gymPrefs(workdays))
        #expect(r.averagePerDay == 0)
        #expect(r.percentOfGoal == 0)
        #expect(r.daysMet == 0)
    }

    @Test func aDateOffIsLeftOut() throws {
        let r = try habit(.gym, .week, now: zone.date(2026, 3, 4, 23), gym([2: 4, 3: 4]), prefs: gymPrefs(Set(Weekday.allCases), off: ["2026-03-04"]))
        #expect(r.averagePerDay == 4)
        #expect(r.percentOfGoal == 100)
        #expect(r.daysMet == 2)
    }

    @Test func futureOnDaysStillNeverCount() throws {
        let r = try habit(.gym, .week, now: zone.date(2026, 3, 3, 23), gym([2: 4, 3: 4]), prefs: gymPrefs(workdays))
        #expect(r.averagePerDay == 4)
        #expect(r.daysMet == 2)
    }

    @Test func pastDaysOfAWeekdayTurnedOffAreLeftOut() throws {
        let sundays: Set = [1, 8, 15, 22, 29]
        let amounts = Dictionary(uniqueKeysWithValues: (1 ... 31).filter { !sundays.contains($0) }.map { ($0, 4.0) })
        let r = try habit(.gym, .month, now: zone.date(2026, 3, 31, 23), gym(amounts), prefs: gymPrefs(Set(Weekday.allCases).subtracting([.sunday])))
        #expect(r.averagePerDay == 4)
        #expect(r.percentOfGoal == 100)
        #expect(r.daysMet == 26)
    }

    @MainActor
    @Test func calendarMarksOffDays() throws {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) {
            $0.prefs.water.weekdays = workdays
            $0.events = [2, 3, 4, 5, 6, 8].map { .done(.water, 8, at: day(2026, 3, $0, 12)) }
        }
        let month = h.engine.reportScreen(.month, selected: .water).calendar
        let cell = { (d: Int) in try #require(month.cells.first { $0.day == d }) }
        #expect(try cell(1).isOff)
        #expect(try cell(1).level == 0)
        #expect(try cell(7).isOff)
        #expect(try cell(7).level == 0)
        #expect(try cell(8).level == 3)
        #expect(try !cell(8).isOff)
        #expect(try !cell(6).isOff)
        #expect(try !cell(9).isOff)
        #expect(month.streakText == "6 days")
    }

    @MainActor
    @Test func addingADayOffUpdatesTheCalendar() throws {
        let h = EngineHarness(at: day(2026, 3, 9, 10)) {
            $0.events = [2, 3, 4, 5, 6, 8].map { .done(.water, 8, at: day(2026, 3, $0, 12)) }
        }
        let before = h.engine.reportScreen(.month, selected: .water).calendar
        #expect(try !#require(before.cells.first { $0.day == 7 }).isOff)
        #expect(before.streakText == "1 day")
        h.engine.data.prefs.water.daysOff = [DayKey(day(2026, 3, 7), calendar: .current)]
        let after = h.engine.reportScreen(.month, selected: .water).calendar
        #expect(try #require(after.cells.first { $0.day == 7 }).isOff)
        #expect(after.streakText == "6 days")
    }
}
