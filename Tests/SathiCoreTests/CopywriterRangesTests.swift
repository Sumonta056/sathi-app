import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Range copy")
struct CopywriterRangesTests {
    private let zone = FixedZone.berlin
    private let now = FixedZone.berlin.date(2025, 11, 11, 14, 52)

    private func title(_ kind: ReportRange, _ date: Date) -> String {
        let range = StatsRange.containing(date, kind: kind, calendar: zone.calendar)
        return Copywriter.rangeTitle(range, now: now, calendar: zone.calendar)
    }

    @Test func dayTitles() {
        #expect(title(.day, now) == "Today, 11 Nov")
        #expect(title(.day, zone.date(2025, 11, 10)) == "Yesterday, 10 Nov")
        #expect(title(.day, zone.date(2025, 11, 3)) == "Mon, 3 Nov")
    }

    @Test func weekTitles() {
        #expect(title(.week, zone.date(2025, 11, 5)) == "3 – 9 Nov")
        #expect(title(.week, zone.date(2025, 10, 29)) == "27 Oct – 2 Nov")
    }

    @Test func monthTitle() {
        #expect(title(.month, zone.date(2026, 11, 11)) == "November 2026")
    }

    private func change(_ value: RangeChange, _ kind: ReportRange) -> String {
        Copywriter.rangeChange(value, kind: kind) { Fmt.count($0) }
    }

    @Test func changeWords() {
        #expect(change(.up(6), .week) == "+6 vs last week")
        #expect(change(.down(1), .week) == "\u{2212}1 vs last week")
        #expect(change(.same, .week) == "same as last week")
        #expect(change(.up(2), .day) == "+2 vs yesterday")
        #expect(change(.same, .day) == "same as yesterday")
        #expect(change(.down(2), .month) == "\u{2212}2 vs last month")
        #expect(change(.none, .month) == "")
    }

    @Test func lengthsUseTheGivenFormat() {
        let text = Copywriter.rangeChange(.down(125 * 60), kind: .week) { Fmt.short($0) }
        #expect(text == "\u{2212}2h 5m vs last week")
    }

    @Test func segments() {
        #expect(Copywriter.rangeSegment(.day) == "Day")
        #expect(Copywriter.rangeSegment(.week) == "Week")
        #expect(Copywriter.rangeSegment(.month) == "Month")
    }
}
