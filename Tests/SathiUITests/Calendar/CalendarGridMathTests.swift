import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@Suite("Calendar grid math")
struct CalendarGridMathTests {
    private let z = FixedZone.berlin
    private let h: CGFloat = 40

    private func math(_ d: Int, month: Int = 11) -> CalendarGridMath {
        CalendarGridMath(day: DayKey(z.date(2026, month, d), calendar: z.calendar), calendar: z.calendar, hourHeight: h)
    }

    @Test func sixAMIsTheTop() {
        #expect(math(12).y(for: z.date(2026, 11, 12, 6)) == 0)
    }

    @Test func halfPastSevenIsOneAndAHalfRows() {
        #expect(math(12).y(for: z.date(2026, 11, 12, 7, 30)) == 1.5 * h)
    }

    @Test func fiveAMOfTheNextDateIsTheLastRow() {
        #expect(math(12).y(for: z.date(2026, 11, 13, 5)) == 23 * h)
    }

    @Test func endOfThePageDayIsTheBottom() {
        #expect(math(12).y(for: z.date(2026, 11, 13, 6)) == 24 * h)
    }

    @Test func slotRoundsDownToFifteenMinutes() {
        #expect(math(12).slotStart(y: 2.3 * h) == z.date(2026, 11, 12, 8, 15))
    }

    @Test func heightIsTheDistanceBetweenStartAndEnd() {
        let i = DateInterval(start: z.date(2026, 11, 12, 9), end: z.date(2026, 11, 12, 10, 30))
        #expect(math(12).height(i) == 1.5 * h)
    }

    @Test func hourHeightIsSixtyPoints() {
        #expect(UIMetrics.calendarHourHeight == 60)
    }

    @Test(arguments: [(60, CGFloat(60)), (30, 120), (15, 240)])
    func rowZoomMultipliesSixtyPoints(_ minutes: Int, _ height: CGFloat) {
        #expect(UIMetrics.calendarHourHeight(rowMinutes: minutes) == height)
    }

    @Test(arguments: [(60, CGFloat(1)), (30, 2), (15, 4)])
    func rowZoomScalesTheHourHeight(_ minutes: Int, _ scale: CGFloat) {
        let base = UIMetrics.calendarHourHeight
        let tall = UIMetrics.calendarHourHeight(rowMinutes: minutes)
        #expect(tall == base * scale)
        let m = CalendarGridMath(day: DayKey(z.date(2026, 11, 12), calendar: z.calendar), calendar: z.calendar, hourHeight: tall)
        #expect(m.y(for: z.date(2026, 11, 12, 7, 30)) == 1.5 * base * scale)
        #expect(m.slotStart(y: m.y(for: z.date(2026, 11, 12, 7, 40))) == z.date(2026, 11, 12, 7, 30))
        #expect(m.slotStart(y: m.y(for: z.date(2026, 11, 12, 7, 59))) == z.date(2026, 11, 12, 7, 45))
        #expect(m.slotStart(y: m.y(for: z.date(2026, 11, 13, 5, 50))) == z.date(2026, 11, 13, 5, 45))
    }

    @Test func tallerRowsShowTheTitleOfAShortBlock() {
        let span = DateInterval(start: z.date(2026, 11, 12, 9), end: z.date(2026, 11, 12, 9, 15))
        let key = DayKey(z.date(2026, 11, 12), calendar: z.calendar)
        let heights = [60, 30, 15].map {
            CalendarGridMath(day: key, calendar: z.calendar, hourHeight: UIMetrics.calendarHourHeight(rowMinutes: $0)).height(span)
        }
        #expect(!CalendarBlockFit.showsText(height: heights[0]))
        #expect(CalendarBlockFit.showsText(height: heights[1]))
        #expect(CalendarBlockFit.showsTimeRange(height: heights[2]))
    }

    @Test func fallBackDayKeepsWallClockRows() {
        let m = math(24, month: 10)
        #expect(m.y(for: z.date(2026, 10, 25, 5)) == 23 * h)
        #expect(m.y(for: z.date(2026, 10, 25, 6)) == 24 * h)
    }
}
