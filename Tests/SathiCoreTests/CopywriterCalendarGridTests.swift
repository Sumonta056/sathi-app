import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Copywriter calendar grid")
struct CopywriterCalendarGridTests {
    private let z = FixedZone.berlin

    @Test(arguments: [(6, "6 AM"), (11, "11 AM"), (12, "Midday"), (13, "1 PM"), (0, "12 AM"), (5, "5 AM")])
    func hourLabel(_ hour: Int, _ expected: String) {
        #expect(Copywriter.calendarHourLabel(z.date(2026, 11, 12, hour), calendar: z.calendar) == expected)
    }

    @Test func moreChips() {
        #expect(Copywriter.calendarMore(2) == "+2 more")
    }

    @Test func dayHeaderParts() {
        let key = DayKey(z.date(2026, 11, 14), calendar: z.calendar)
        #expect(Copywriter.calendarWeekday(key, calendar: z.calendar) == "Sat")
        #expect(Copywriter.calendarDayNumber(key, calendar: z.calendar) == "14")
    }

    @Test func allDayLabel() {
        #expect(Copywriter.calendarAllDay == "All day")
    }
}
