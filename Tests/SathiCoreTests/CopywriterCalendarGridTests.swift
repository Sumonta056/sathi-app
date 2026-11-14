import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Copywriter calendar grid")
struct CopywriterCalendarGridTests {
    private let z = FixedZone.berlin

    @Test(arguments: [(6, "6 AM"), (11, "11 AM"), (12, "Midday"), (13, "1 PM"), (0, "12 AM"), (5, "5 AM")])
    func hourLabel(_ hour: Int, _ expected: String) {
        #expect(Copywriter.calendarHourLabel(hour: hour) == expected)
    }

    @Test func moreChips() {
        #expect(Copywriter.calendarMore(2) == "+2 more")
    }

    @Test func dayHeaderParts() {
        let key = DayKey(z.date(2026, 11, 14), calendar: z.calendar)
        #expect(Copywriter.calendarWeekday(key, calendar: z.calendar) == "Sat")
        #expect(Copywriter.calendarDayNumber(key, calendar: z.calendar) == "14")
    }

    @Test func spokenBlock() {
        let text = Copywriter.calendarBlockSpoken("Code review", z.date(2026, 11, 12, 9, 30), z.date(2026, 11, 12, 11), calendar: z.calendar)
        let start = Copywriter.trackerClock(z.date(2026, 11, 12, 9, 30), calendar: z.calendar)
        let end = Copywriter.trackerClock(z.date(2026, 11, 12, 11), calendar: z.calendar)
        #expect(text == "Code review, \(start) to \(end)")
    }

    @Test func weekdayOfEachDay() {
        let names = (9 ... 15).map { Copywriter.calendarWeekday(DayKey(z.date(2026, 11, $0), calendar: z.calendar), calendar: z.calendar) }
        #expect(names == ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
    }

    @Test func allDayLabel() {
        #expect(Copywriter.calendarAllDay == "All day")
    }
}
