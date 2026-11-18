import Foundation
@testable import SathiCore
import Testing

@Suite("Calendar rounding")
struct CalendarRoundingTests {
    @Test func roundsEachEndToTheNearestMinuteOnce() {
        let raw = Split.span("14:35:54", "15:01:32")
        #expect(CalendarRounding.rounded(raw) == Split.span("14:36", "15:02"))
        #expect(CalendarRounding.rounded(Split.span("10:00:20", "10:30:40")) == Split.span("10:00", "10:31"))
        #expect(CalendarRounding.rounded(Split.span("10:00", "10:30")) == Split.span("10:00", "10:30"))
    }

    @Test func layoutSpanUsesTheRoundedValues() {
        let grid = Split.layout([Split.activity("testing", "14:35:54", "15:01:32")], metrics: Split.weekFlat)
        let laid = Split.laid(grid, "testing")
        #expect(laid?.span == Split.span("14:36", "15:02"))
        #expect(laid?.top == Double((14 - 6) * 60 + 36))
    }

    @Test func weekTimeLabelShowsTheRoundedRangeAndLength() {
        let grid = Split.layout([Split.activity("testing", "14:35:54", "15:01:32")], metrics: Split.weekFlat)
        let span = Split.laid(grid, "testing")?.span ?? Split.span("00:00", "00:00")
        #expect(Copywriter.calendarBlockTime(span, calendar: Split.calendar) == "2:36 – 3:02 PM · 26m")
    }

    @Test func lengthIsRoundedEndMinusRoundedStart() {
        let span = CalendarRounding.rounded(Split.span("10:00:20", "10:30:40"))
        #expect(Copywriter.calendarBlockTime(span, calendar: Split.calendar) == "10:00 – 10:31 AM · 31m")
    }

    @Test func labelAcrossNoonAndOverAnHour() {
        #expect(Copywriter.calendarBlockTime(Split.span("10:38", "12:31"), calendar: Split.calendar) == "10:38 AM – 12:31 PM · 1h 53m")
    }
}
