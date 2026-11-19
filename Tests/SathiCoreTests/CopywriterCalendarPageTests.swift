import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Copywriter calendar page")
struct CopywriterCalendarPageTests {
    private let cal = Calendar.current

    private func title(_ kind: ReportRange, _ date: Date) -> CalendarRangeTitle {
        Copywriter.calendarRangeTitle(.containing(date, kind: kind, calendar: cal), calendar: cal)
    }

    @Test func fixedTexts() {
        #expect(Copywriter.calendarPageTitle == "Calendar")
        #expect(Copywriter.calendarExperimentalTag == "Experimental")
        #expect(Copywriter.calendarSettingLabel == "Calendar page (experimental)")
        #expect(Copywriter.calendarToday == "Today")
        #expect(Copywriter.calendarGateTitle == "Your calendar, in Sathi")
        #expect(Copywriter.calendarGateNotice == "Sathi needs calendar access to show your events.")
        #expect(Copywriter.calendarGateDenied == "Calendar access is off. Turn it on in System Settings.")
    }

    @Test func monthTitleIsMonthAndYear() {
        let t = title(.month, day(2026, 11, 12, 10))
        #expect(t.main == "November")
        #expect(t.year == "2026")
    }

    @Test func dayTitleUsesThePageDay() {
        let t = title(.day, day(2026, 11, 12, 1, 30))
        #expect(t.main == "Wed 11 Nov")
        #expect(t.year == "2026")
    }

    @Test func weekTitleSpansTheDays() {
        let t = title(.week, day(2026, 11, 12, 10))
        #expect(t.main.contains(" to "))
        #expect(t.year == "2026")
    }

    @Test func weekAcrossTheYearTakesTheLastYear() {
        var monday = Calendar.current
        monday.firstWeekday = 2
        let range = CalendarPageRange.containing(day(2026, 12, 31, 10), kind: .week, calendar: monday)
        let t = Copywriter.calendarRangeTitle(range, calendar: monday)
        #expect(t.main == "26 Dec to 1 Jan")
        #expect(t.year == "2027")
    }
}
