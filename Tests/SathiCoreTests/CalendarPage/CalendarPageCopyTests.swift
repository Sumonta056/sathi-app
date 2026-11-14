import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar page copy")
struct CalendarPageCopyTests {
    @Test func hoursShowTwoDigitMinutes() {
        #expect(Copywriter.calendarHours(21 * 3600 + 5 * 60) == "21 h 05 m")
        #expect(Copywriter.calendarHours(6 * 3600 + 40 * 60) == "6 h 40 m")
    }

    @Test func underAnHourShowsMinutesOnly() {
        #expect(Copywriter.calendarHours(40 * 60) == "40 m")
        #expect(Copywriter.calendarHours(0) == "0 m")
        #expect(Copywriter.calendarHours(59) == "0 m")
    }

    @Test func summaryUsesTheSameWordsForEveryRange() {
        let stats = CalendarPageStats(tracked: 42 * 3600 + 5 * 60, planned: 29 * 3600 + 16 * 60)
        #expect(Copywriter.calendarSummary(stats) == "Tracked 42 h 05 m · Planned 29 h 16 m")
        #expect(Copywriter.calendarPlanned == "Planned")
    }

    @Test func sidePanelButtonNamesTheAction() {
        #expect(Copywriter.calendarSidePanelLabel(shown: true) == "Hide side panel")
        #expect(Copywriter.calendarSidePanelLabel(shown: false) == "Show side panel")
    }

    @Test func panelTitleNamesTheRange() {
        #expect(Copywriter.calendarStatsTitle(.day) == "This day")
        #expect(Copywriter.calendarStatsTitle(.week) == "This week")
        #expect(Copywriter.calendarStatsTitle(.month) == "This month")
    }

    @Test func eventDateIsTheShortDay() {
        let calendar = FixedZone.berlin.calendar
        let key = DayKey(FixedZone.berlin.date(2026, 3, 4, 12), calendar: calendar)
        #expect(Copywriter.calendarEventDate(key, calendar: calendar) == "Wed 4 Mar")
    }
}
