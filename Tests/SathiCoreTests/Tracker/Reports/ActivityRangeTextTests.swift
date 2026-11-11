import Foundation
@testable import SathiCore
import Testing

@Suite("Activity range text")
struct ActivityRangeTextTests {
    typealias Fix = ActivityReportSupport

    private var days: [ActivityDay] {
        [Fix.day(5, [Fix.work("Docs", "Learning", 5, (9, 0), (10, 0))]), Fix.day(4, Fix.busyDay)]
    }

    @Test func weekTextUsesTheRangeTitleInTheHeader() {
        let week = StatsRange.containing(Fix.at(4, 12), kind: .week, calendar: Fix.calendar)
        let title = Copywriter.rangeTitle(week, now: Fix.at(4, 12), calendar: Fix.calendar)
        let lines = ActivityRangeText.make(days, title: title, calendar: Fix.calendar).split(separator: "\n").map(String.init)
        #expect(lines.first == "2 – 8 Mar · 2 days tracked · 4 h 20 min")
        #expect(lines[1] == "Average 2 h 10 min a day")
        #expect(lines.last?.hasPrefix("Thu, 5 Mar") == true)
    }

    @Test func anEmptyRangeIsTheHeaderAndAverageOnly() {
        let text = ActivityRangeText.make([], title: "2 – 8 Mar", calendar: Fix.calendar)
        #expect(text.split(separator: "\n").count == 2)
    }
}
