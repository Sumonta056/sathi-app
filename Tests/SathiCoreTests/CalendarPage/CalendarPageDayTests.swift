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
}
