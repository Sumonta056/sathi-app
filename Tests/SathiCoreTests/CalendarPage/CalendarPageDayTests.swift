import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("CalendarPageDay")
struct CalendarPageDayTests {
    let zone = FixedZone("Europe/Berlin")

    @Test func lateNightBelongsToThePreviousDay() {
        let key = CalendarPageDay.key(holding: zone.date(2026, 3, 5, 0, 22), calendar: zone.calendar)
        #expect(key.raw == "2026-03-04")
    }

    @Test func justBeforeSixBelongsToThePreviousDay() {
        let date = zone.date(2026, 3, 5, 5, 59).addingTimeInterval(59)
        #expect(CalendarPageDay.key(holding: date, calendar: zone.calendar).raw == "2026-03-04")
    }

    @Test func sixOClockStartsTheDay() {
        let key = CalendarPageDay.key(holding: zone.date(2026, 3, 5, 6, 0), calendar: zone.calendar)
        #expect(key.raw == "2026-03-05")
    }

    @Test func intervalRunsSixToSix() throws {
        let key = try #require(DayKey(raw: "2026-03-04"))
        let interval = CalendarPageDay.interval(of: key, calendar: zone.calendar)
        #expect(interval.start == zone.date(2026, 3, 4, 6))
        #expect(interval.end == zone.date(2026, 3, 5, 6))
    }

    @Test func springForwardDayLastsTwentyThreeHours() throws {
        let key = try #require(DayKey(raw: "2026-03-28"))
        let interval = CalendarPageDay.interval(of: key, calendar: zone.calendar)
        #expect(interval.start == zone.date(2026, 3, 28, 6))
        #expect(interval.end == zone.date(2026, 3, 29, 6))
        #expect(interval.duration == 23 * 3600)
    }

    @Test func hourStartsCoverTwentyFourRows() throws {
        let starts = try CalendarPageDay.hourStarts(of: #require(DayKey(raw: "2026-03-04")), calendar: zone.calendar)
        #expect(starts.count == 24)
        #expect(starts.first == zone.date(2026, 3, 4, 6))
        #expect(starts.last == zone.date(2026, 3, 5, 5))
    }

    @Test(arguments: ["2026-03-28", "2026-10-24"])
    func hourRowsFollowWallClockOnDstDays(raw: String) throws {
        let key = try #require(DayKey(raw: raw))
        let interval = CalendarPageDay.interval(of: key, calendar: zone.calendar)
        let rows = CalendarPageDay.hourStarts(of: key, calendar: zone.calendar)
        #expect(rows.count == 24)
        #expect(rows.first == interval.start)
        #expect(zip(rows, rows.dropFirst()).allSatisfy { $0 <= $1 })
        let last = try zone.calendar.dateComponents([.day, .hour], from: #require(rows.last))
        let next = zone.calendar.dateComponents([.day], from: interval.end)
        #expect(last.hour == 5)
        #expect(last.day == next.day)
        #expect(try interval.end == #require(rows.last?.addingTimeInterval(3600)))
    }

    @Test func autumnRepeatedHourRowIsTwoHoursLong() throws {
        let rows = try CalendarPageDay.hourStarts(of: #require(DayKey(raw: "2026-10-24")), calendar: zone.calendar)
        #expect(rows[20].distance(to: rows[21]) == 2 * 3600)
    }

    @Test func dstNightsStayOnThePreviousPageDay() {
        let spring = CalendarPageDay.key(holding: zone.date(2026, 3, 29, 3, 30), calendar: zone.calendar)
        #expect(spring.raw == "2026-03-28")
        let autumn = CalendarPageDay.key(holding: zone.date(2026, 10, 25, 2, 30), calendar: zone.calendar)
        #expect(autumn.raw == "2026-10-24")
    }
}
