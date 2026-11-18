import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Copywriter calendar week")
struct CopywriterCalendarWeekTests {
    private let z = FixedZone.berlin

    @Test func weekDayHeaderShowsWeekdayNumberAndMonth() {
        let key = DayKey(z.date(2026, 11, 16), calendar: z.calendar)
        #expect(Copywriter.calendarWeekDayHeader(key, calendar: z.calendar) == "Mon 16 Nov")
    }

    @Test func weekDayHeaderForAnotherMonth() {
        let key = DayKey(z.date(2026, 3, 4), calendar: z.calendar)
        #expect(Copywriter.calendarWeekDayHeader(key, calendar: z.calendar) == "Wed 4 Mar")
    }

    @Test func halfLabels() {
        #expect(Copywriter.calendarActualLabel == "ACTUAL")
        #expect(Copywriter.calendarPlanLabel == "PLAN")
    }

    @Test(arguments: [(3, "3 days"), (4, "4 days"), (5, "5 days"), (7, "7 days")])
    func dayCountOption(_ n: Int, _ expected: String) {
        #expect(Copywriter.calendarWeekDaysOption(n) == expected)
    }

    @Test(arguments: [
        (60, 180, "7:00 – 9:00 AM · away or nothing on every shown day"),
        (0, 60, "6:00 – 7:00 AM · away or nothing on every shown day"),
        (1080, 1440, "12:00 – 6:00 AM · away or nothing on every shown day"),
        (960, 1440, "10:00 PM – 6:00 AM · away or nothing on every shown day"),
        (330, 420, "11:30 AM – 1:00 PM · away or nothing on every shown day"),
    ])
    func foldText(_ from: Int, _ to: Int, _ expected: String) {
        #expect(Copywriter.calendarFoldText(fromMinute: from, toMinute: to) == expected)
    }

    @Test func narrowStartClockHasNoHalfOfDay() {
        #expect(Copywriter.calendarStartClock(z.date(2026, 11, 16, 14, 36), calendar: z.calendar) == "2:36")
        #expect(Copywriter.calendarStartClock(z.date(2026, 11, 16, 10), calendar: z.calendar) == "10:00")
    }
}
