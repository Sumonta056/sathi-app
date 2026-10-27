import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Streak days off")
struct StreakDaysOffTests {
    private let zone = FixedZone.berlin
    private let workdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]

    private func days(_ weekdays: Set<Weekday>, off: [String] = []) -> HabitDays {
        HabitDays(weekdays: weekdays, daysOff: Set(off.compactMap { DayKey(raw: $0) }))
    }

    private func met(_ dates: [(Int, Int, Int)], amount: Double = 4) -> [HistoryEvent] {
        dates.map { .done(.gym, amount, at: zone.date($0.0, $0.1, $0.2, 12)) }
    }

    private func current(_ events: [HistoryEvent], now: Date, days: HabitDays) -> Int {
        let store = InMemoryHistoryStore(events: events)
        let calendar = zone.calendar
        return StreakCalculator(calendar: calendar)
            .current(
                .gym, goal: 4, reset: nil, now: now,
                isOn: { days.isOn($0, calendar: calendar) },
                load: { store.events(from: $0.start, to: $0.end) }
            )
    }

    private func longest(_ events: [HistoryEvent], now: Date, days: HabitDays) -> Int {
        let store = InMemoryHistoryStore(events: events)
        let calendar = zone.calendar
        return StreakCalculator(calendar: calendar)
            .longest(
                .gym, goal: 4, reset: nil, now: now,
                isOn: { days.isOn($0, calendar: calendar) },
                load: { store.events(from: $0.start, to: $0.end) }
            )
    }

    private var weekOne: [(Int, Int, Int)] { [(2026, 3, 2), (2026, 3, 3), (2026, 3, 4), (2026, 3, 5), (2026, 3, 6)] }
    private var monday: Date { zone.date(2026, 3, 9, 12) }

    @Test func weekendOffKeepsTheStreak() {
        #expect(current(met(weekOne + [(2026, 3, 9)]), now: monday, days: days(workdays)) == 6)
    }

    @Test func metOffDayAddsOne() {
        #expect(current(met(weekOne + [(2026, 3, 7), (2026, 3, 9)]), now: monday, days: days(workdays)) == 7)
    }

    @Test func unmetOnDayStillBreaks() {
        let events = met([(2026, 3, 2), (2026, 3, 3), (2026, 3, 5), (2026, 3, 6), (2026, 3, 9)])
        #expect(current(events, now: monday, days: days(workdays)) == 3)
    }

    @Test func todayNotMetAndOnCountsFromYesterday() {
        #expect(current(met(weekOne), now: monday, days: days(workdays)) == 5)
    }

    @Test func todayOffAndNotMetIsSkipped() {
        #expect(current(met(weekOne), now: zone.date(2026, 3, 8, 12), days: days(workdays)) == 5)
    }

    @Test func aDateOffIsSkipped() {
        let events = met([(2026, 3, 2), (2026, 3, 3), (2026, 3, 5), (2026, 3, 6), (2026, 3, 9)])
        #expect(current(events, now: monday, days: days(workdays, off: ["2026-03-04"])) == 5)
    }

    @Test func streakSkipsOffDaysAcrossMonths() {
        let events = met([(2026, 2, 23), (2026, 2, 24), (2026, 2, 25), (2026, 2, 26), (2026, 3, 3), (2026, 3, 4)])
        let off = days(workdays, off: ["2026-02-27", "2026-03-02"])
        #expect(current(events, now: zone.date(2026, 3, 4, 12), days: off) == 6)
    }

    @Test func pastDaysOfAWeekdayTurnedOffAreSkipped() {
        let saturday = zone.date(2026, 3, 21, 12)
        let events = (0 ..< 20).map { zone.adding(days: -$0, to: saturday) }
            .filter { zone.calendar.component(.weekday, from: $0) != Weekday.sunday.rawValue }
            .map { HistoryEvent.done(.gym, 4, at: $0) }
        #expect(current(events, now: saturday, days: days(Set(Weekday.allCases))) == 6)
        #expect(current(events, now: saturday, days: days(Set(Weekday.allCases).subtracting([.sunday]))) == 18)
    }

    @Test func everyDayOffAndNothingMetGivesZero() {
        let store = InMemoryHistoryStore(events: [])
        let streak = StreakCalculator(calendar: zone.calendar)
            .current(.gym, goal: 4, reset: nil, now: monday, isOn: { _ in false }, load: { store.events(from: $0.start, to: $0.end) })
        #expect(streak == 0)
    }

    @Test func longestStreakSkipsOffDays() {
        let weekTwo = [(2026, 3, 9), (2026, 3, 10), (2026, 3, 11), (2026, 3, 12), (2026, 3, 13)]
        let later = [(2026, 4, 13), (2026, 4, 14), (2026, 4, 15)]
        let events = met(weekOne + weekTwo + later)
        #expect(longest(events, now: zone.date(2026, 4, 15, 12), days: days(workdays)) == 10)
    }

    @Test func longestStreakAddsAMetOffDay() {
        let weekTwo = [(2026, 3, 9), (2026, 3, 10), (2026, 3, 11), (2026, 3, 12), (2026, 3, 13)]
        let events = met(weekOne + [(2026, 3, 7)] + weekTwo)
        #expect(longest(events, now: zone.date(2026, 4, 15, 12), days: days(workdays)) == 11)
    }

    @Test func longestStreakResetsOnAnUnmetOnDay() {
        let events = met(weekOne + [(2026, 3, 9), (2026, 3, 10), (2026, 3, 12), (2026, 3, 13)])
        #expect(longest(events, now: zone.date(2026, 4, 15, 12), days: days(workdays)) == 7)
    }
}
