import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@Suite("Dashboard content")
struct DashboardContentTests {
    private static var zone: FixedZone { .berlin }
    private static let now = zone.date(2026, 11, 11, 20)

    private static func range(_ kind: ReportRange, at date: Date) -> StatsRange {
        StatsRange.containing(date, kind: kind, calendar: zone.calendar)
    }

    private static let today = range(.day, at: now)
    private static let yesterday = range(.day, at: zone.date(2026, 11, 10, 12))
    private static let thisWeek = range(.week, at: now)
    private static let lastWeek = range(.week, at: zone.date(2026, 11, 2, 12))
    private static let thisMonth = range(.month, at: now)
    private static let lastMonth = range(.month, at: zone.date(2026, 10, 15, 12))

    struct Row: Sendable, CustomTestStringConvertible {
        let name: String
        let range: StatsRange
        let selected: HabitID?
        let expected: DashboardContent

        var testDescription: String { name }
    }

    static let rows: [Row] = [
        Row(name: "day holding now, all buddies", range: today, selected: nil, expected: .today),
        Row(name: "past day, all buddies", range: yesterday, selected: nil, expected: .all),
        Row(name: "current week, all buddies", range: thisWeek, selected: nil, expected: .all),
        Row(name: "past week, all buddies", range: lastWeek, selected: nil, expected: .all),
        Row(name: "current month, all buddies", range: thisMonth, selected: nil, expected: .all),
        Row(name: "past month, all buddies", range: lastMonth, selected: nil, expected: .all),
        Row(name: "day holding now, a buddy", range: today, selected: .water, expected: .buddy(.water)),
        Row(name: "past day, a buddy", range: yesterday, selected: .reading, expected: .buddy(.reading)),
        Row(name: "current week, a buddy", range: thisWeek, selected: .meditation, expected: .buddy(.meditation)),
        Row(name: "past week, a buddy", range: lastWeek, selected: .gym, expected: .buddy(.gym)),
        Row(name: "current month, a buddy", range: thisMonth, selected: .gym, expected: .buddy(.gym)),
        Row(name: "past month, a buddy", range: lastMonth, selected: .water, expected: .buddy(.water))
    ]

    @Test(arguments: rows)
    func theContentFollowsTheRangeAndTheTab(_ row: Row) {
        #expect(DashboardPage.content(range: row.range, now: Self.now, selected: row.selected) == row.expected)
    }

    @Test func onlyTheDayThatHoldsNowShowsTheTodayContent() {
        let late = Self.zone.date(2026, 11, 11, 23, 59)
        let tomorrow = Self.zone.date(2026, 11, 12, 0, 1)
        #expect(DashboardPage.content(range: Self.today, now: late, selected: nil) == .today)
        #expect(DashboardPage.content(range: Self.today, now: tomorrow, selected: nil) == .all)
    }
}
