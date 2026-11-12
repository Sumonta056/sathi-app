import Foundation
@testable import SathiCore
import Testing

@Suite("Activity standup and monthly text")
struct ActivityTextTests {
    typealias Fix = ActivityReportSupport

    @Test func standupMatchesRule35() {
        let text = ActivityStandupText.make(Fix.day(4, Fix.busyDay), calendar: Fix.calendar)
        let lines = text.split(separator: "\n").map(String.init)
        #expect(lines == [
            "Wed, 4 Mar · 3 h 20 min",
            "• Fix login bug (Coding) · 2 h 30 min",
            "• Standup (Meeting) · 30 min",
            "• Read mail · 20 min"
        ])
    }

    @Test func standupIgnoresAwayAndNotLogged() {
        let text = ActivityStandupText.make(Fix.day(4, Fix.busyDay), calendar: Fix.calendar)
        #expect(!text.contains("Away"))
    }

    @Test func standupOfAnEmptyDayIsTheHeaderOnly() {
        let text = ActivityStandupText.make(Fix.day(4, []), calendar: Fix.calendar)
        #expect(text == "Wed, 4 Mar · 0 min")
    }

    @Test func standupBreaksTiesByText() {
        let items = [Fix.work("B", nil, 4, (9, 0), (9, 30)), Fix.work("A", nil, 4, (10, 0), (10, 30))]
        let lines = ActivityStandupText.make(Fix.day(4, items), calendar: Fix.calendar).split(separator: "\n").map(String.init)
        #expect(lines.dropFirst() == ["• A · 30 min", "• B · 30 min"])
    }

    private var march: [ActivityDay] {
        [
            Fix.day(5, [Fix.work("Docs", "Learning", 5, (9, 0), (10, 0))]),
            Fix.day(4, Fix.busyDay),
            Fix.day(6, [Fix.away(6, (9, 0), (10, 0))])
        ]
    }

    @Test func monthlyMatchesRule36() {
        let range = StatsRange.containing(Fix.at(4, 12), kind: .month, calendar: Fix.calendar)
        let title = Copywriter.rangeTitle(range, now: Fix.at(4, 12), calendar: Fix.calendar)
        let lines = ActivityRangeText.make(march, title: title, calendar: Fix.calendar).split(separator: "\n").map(String.init)
        #expect(lines == [
            "March 2026 · 2 days tracked · 4 h 20 min",
            "Average 2 h 10 min a day",
            "Coding · 2 h 30 min (58%)",
            "Learning · 1 h (23%)",
            "Meeting · 30 min (12%)",
            "No category · 20 min (8%)",
            "Wed, 4 Mar · 3 h 20 · Fix login bug, Standup, Read mail",
            "Thu, 5 Mar · 1 h 00 · Docs"
        ])
    }

    @Test func monthStatsAverageBestAndAway() {
        let stats = ActivityMonthStats(march)
        #expect(stats.daysTracked == 2)
        #expect(stats.averageDay == 7800)
        #expect(stats.bestDay?.day == Fix.dayKey(4))
        #expect(stats.away == 1800)
        #expect(stats.rows.map(\.day) == [Fix.dayKey(4), Fix.dayKey(5)])
    }

    @Test func monthTopTextsAreCapped() {
        let items = (0 ..< 5).map { Fix.work("T\($0)", nil, 4, (9 + $0, 0), (9 + $0, 10 + $0)) }
        let row = ActivityMonthStats([Fix.day(4, items)]).rows[0]
        #expect(row.topTexts == ["T4", "T3", "T2"])
    }

    @Test func emptyMonthHasNoAverage() {
        let stats = ActivityMonthStats([])
        #expect(stats.averageDay == 0)
        #expect(stats.bestDay == nil)
    }
}
