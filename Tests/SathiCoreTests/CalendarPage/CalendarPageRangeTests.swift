import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("CalendarPageRange")
struct CalendarPageRangeTests {
    let monday = FixedZone("Europe/Berlin", firstWeekday: 2)
    let sunday = FixedZone("Europe/Berlin", firstWeekday: 1)

    private func raws(_ days: [DayKey]) -> [String] { days.map(\.raw) }

    @Test func weekStartsOnMonday() {
        let range = CalendarPageRange.containing(monday.date(2026, 3, 4, 12), kind: .week, calendar: monday.calendar)
        #expect(raws(range.days) == ["2026-03-02", "2026-03-03", "2026-03-04", "2026-03-05", "2026-03-06", "2026-03-07", "2026-03-08"])
        #expect(range.interval.start == monday.date(2026, 3, 2, 6))
        #expect(range.interval.end == monday.date(2026, 3, 9, 6))
    }

    @Test func weekStartsOnSunday() {
        let range = CalendarPageRange.containing(sunday.date(2026, 3, 4, 12), kind: .week, calendar: sunday.calendar)
        #expect(range.days.first?.raw == "2026-03-01")
        #expect(range.days.last?.raw == "2026-03-07")
    }

    @Test func nextHasNoLimit() {
        let now = monday.date(2026, 3, 4, 12)
        let range = CalendarPageRange.containing(now, kind: .week, calendar: monday.calendar)
        #expect(range.holds(now))
        #expect(range.next.days.first?.raw == "2026-03-09")
        #expect(range.next.next.days.first?.raw == "2026-03-16")
    }

    @Test func dayMovesOneDate() {
        let range = CalendarPageRange.containing(monday.date(2026, 3, 4, 12), kind: .day, calendar: monday.calendar)
        #expect(range.previous.days.map(\.raw) == ["2026-03-03"])
        #expect(range.next.days.map(\.raw) == ["2026-03-05"])
    }

    @Test func monthNextOfMarchIsApril() {
        let range = CalendarPageRange.containing(monday.date(2026, 3, 10, 12), kind: .month, calendar: monday.calendar)
        #expect(range.days.count == 31)
        let next = range.next
        #expect(next.days.first?.raw == "2026-04-01")
        #expect(next.days.count == 30)
        #expect(range.previous.days.first?.raw == "2026-02-01")
    }

    @Test func monthWeeksAreWholeWeeks() throws {
        let range = CalendarPageRange.containing(monday.date(2026, 3, 10, 12), kind: .month, calendar: monday.calendar)
        let weeks = range.monthWeeks
        #expect(weeks.count == 6)
        #expect(weeks.allSatisfy { $0.count == 7 })
        #expect(weeks.first?.first?.raw == "2026-02-23")
        #expect(weeks.last?.last?.raw == "2026-04-05")
        #expect(try range.inRange(#require(DayKey(raw: "2026-03-15"))))
        #expect(try !range.inRange(#require(DayKey(raw: "2026-02-23"))))
    }

    @Test func changeToDayFromWeekHoldingNowGivesTodayPageDay() {
        let now = monday.date(2026, 3, 5, 1, 30)
        let week = CalendarPageRange.containing(now, kind: .week, calendar: monday.calendar)
        #expect(week.changed(to: .day, now: now).days.map(\.raw) == ["2026-03-04"])
    }

    @Test func changeToDayFromPastWeekGivesFirstDate() {
        let now = monday.date(2026, 3, 20, 12)
        let week = CalendarPageRange.containing(monday.date(2026, 3, 4, 12), kind: .week, calendar: monday.calendar)
        #expect(week.changed(to: .day, now: now).days.map(\.raw) == ["2026-03-02"])
    }

    @Test func scrollRowCountsFromSixAM() {
        let wed = CalendarPageRange.containing(monday.date(2026, 3, 4, 12), kind: .day, calendar: monday.calendar)
        #expect(wed.initialScrollRow(now: monday.date(2026, 3, 4, 10, 15)) == 4)
        #expect(wed.initialScrollRow(now: monday.date(2026, 3, 5, 1, 30)) == 19)
        #expect(wed.initialScrollRow(now: monday.date(2026, 3, 5, 6, 0)) == 0)
        #expect(wed.initialScrollRow(now: monday.date(2026, 3, 9, 10, 0)) == 0)
    }
}
