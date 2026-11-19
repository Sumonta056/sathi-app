import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("CalendarPageRange")
struct CalendarPageRangeTests {
    let monday = FixedZone("Europe/Berlin", firstWeekday: 2)
    let sunday = FixedZone("Europe/Berlin", firstWeekday: 1)

    private func raws(_ days: [DayKey]) -> [String] { days.map(\.raw) }

    @Test func weekStartsOnSaturdayWhateverTheRegion() {
        for zone in [monday, sunday] {
            let range = CalendarPageRange.containing(zone.date(2026, 11, 11, 12), kind: .week, calendar: zone.calendar)
            #expect(raws(range.days) == ["2026-11-07", "2026-11-08", "2026-11-09", "2026-11-10", "2026-11-11", "2026-11-12", "2026-11-13"])
            #expect(range.interval.start == zone.date(2026, 11, 7, 6))
            #expect(range.interval.end == zone.date(2026, 11, 14, 6))
        }
    }

    @Test func saturdayStartsItsOwnWeek() {
        let range = CalendarPageRange.containing(monday.date(2026, 11, 14, 12), kind: .week, calendar: monday.calendar)
        #expect(range.days.first?.raw == "2026-11-14")
        #expect(range.days.last?.raw == "2026-11-20")
    }

    @Test func nextHasNoLimit() {
        let now = monday.date(2026, 3, 4, 12)
        let range = CalendarPageRange.containing(now, kind: .week, calendar: monday.calendar)
        #expect(range.holds(now))
        #expect(range.next.days.first?.raw == "2026-03-07")
        #expect(range.next.next.days.first?.raw == "2026-03-14")
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
        #expect(weeks.count == 5)
        #expect(weeks.allSatisfy { $0.count == 7 })
        #expect(weeks.first?.first?.raw == "2026-02-28")
        #expect(weeks.last?.last?.raw == "2026-04-03")
        #expect(try range.inRange(#require(DayKey(raw: "2026-03-15"))))
        #expect(try !range.inRange(#require(DayKey(raw: "2026-02-28"))))
    }

    @Test func changeToDayFromWeekHoldingNowGivesTodayPageDay() {
        let now = monday.date(2026, 3, 5, 1, 30)
        let week = CalendarPageRange.containing(now, kind: .week, calendar: monday.calendar)
        #expect(week.changed(to: .day, now: now).days.map(\.raw) == ["2026-03-04"])
    }

    @Test func changeToDayFromPastWeekGivesFirstDate() {
        let now = monday.date(2026, 3, 20, 12)
        let week = CalendarPageRange.containing(monday.date(2026, 3, 4, 12), kind: .week, calendar: monday.calendar)
        #expect(week.changed(to: .day, now: now).days.map(\.raw) == ["2026-02-28"])
    }

    @Test func regionFirstWeekdayDoesNotChangeTheMonthGrid() {
        let date = monday.date(2026, 3, 10, 12)
        let a = CalendarPageRange.containing(date, kind: .month, calendar: monday.calendar)
        let b = CalendarPageRange.containing(date, kind: .month, calendar: sunday.calendar)
        #expect(a == b)
        #expect(a.monthWeeks == b.monthWeeks)
    }

    @Test func monthGridRowsStartOnSaturday() {
        let range = CalendarPageRange.containing(sunday.date(2026, 11, 11, 12), kind: .month, calendar: sunday.calendar)
        let gregorian = Calendar.gregorian(in: sunday.calendar.timeZone)
        let weekdays = range.monthWeeks.map { gregorian.component(.weekday, from: $0[0].start(in: gregorian)) }
        #expect(weekdays.allSatisfy { $0 == 7 })
        #expect(range.monthWeeks.first?.first?.raw == "2026-10-31")
        #expect(range.monthWeeks.last?.last?.raw == "2026-12-04")
    }

    @Test func monthStartingOnSaturdayHasNoLeadingDays() {
        let range = CalendarPageRange.containing(monday.date(2026, 8, 10, 12), kind: .month, calendar: monday.calendar)
        #expect(range.monthWeeks.first?.first?.raw == "2026-08-01")
    }
}

@Suite("CalendarPageRange from a day")
struct CalendarPageRangeDayTests {
    @Test func dayKeyOpensThatDay() {
        let cal = FixedZone.berlin.calendar
        let thu = DayKey(FixedZone.berlin.date(2026, 11, 12), calendar: cal)
        let range = CalendarPageRange.containing(day: thu, kind: .day, calendar: cal)
        #expect(range.days == [thu])
        #expect(CalendarPageRange.containing(day: thu, kind: .week, calendar: cal).days.contains(thu))
    }
}
