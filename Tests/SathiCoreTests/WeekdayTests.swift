import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Weekday")
struct WeekdayTests {
    @Test func allCasesStartOnMonday() {
        #expect(Weekday.allCases == [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday])
    }

    @Test func rawValuesMatchTheCalendarWeekday() {
        #expect(Weekday.allCases.map(\.rawValue) == [2, 3, 4, 5, 6, 7, 1])
        let zone = FixedZone.berlin
        let wednesday = zone.date(2026, 3, 4, 12)
        #expect(Weekday(rawValue: zone.calendar.component(.weekday, from: wednesday)) == .wednesday)
        let sunday = zone.date(2026, 3, 8, 12)
        #expect(Weekday(rawValue: zone.calendar.component(.weekday, from: sunday)) == .sunday)
    }

    @Test func shortLabels() {
        #expect(Weekday.allCases.map(\.shortLabel) == ["M", "T", "W", "T", "F", "S", "S"])
    }

    @Test func names() {
        let names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        #expect(Weekday.allCases.map(\.name) == names)
    }

    @Test func reminderStyleRawValues() {
        #expect(ReadingReminderStyle.allCases.map(\.rawValue) == ["corner", "focus"])
    }
}
