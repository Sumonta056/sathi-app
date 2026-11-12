import Foundation
@testable import SathiCore
import Testing

@Suite("Away totals per place")
struct ActivityAwayTotalsTests {
    typealias Fix = ActivityReportSupport

    private func away(_ d: Int, _ from: (Int, Int), _ to: (Int, Int), place: AwayPlace? = nil, name: String? = nil) -> Activity {
        var a = Fix.away(d, from, to)
        a.awayPlace = place
        a.awayPlaceName = name
        return a
    }

    private var items: [Activity] {
        [
            Fix.work("Docs", "Coding", 4, (9, 0), (10, 0)),
            away(4, (10, 0), (10, 30), place: .lunch),
            away(4, (11, 0), (12, 0), place: .walk),
            away(4, (12, 0), (12, 15), place: .lunch),
            away(4, (13, 0), (13, 20), place: .other, name: "Gym trip"),
            away(4, (14, 0), (14, 10))
        ]
    }

    @Test func dayHasOneRowPerPlaceLongestFirst() {
        let stats = ActivityDayStats(Fix.day(4, items))
        #expect(stats.awayTotals.map(\.name) == ["Walk", "Lunch", "Gym trip", Copywriter.trackerAway])
        #expect(stats.awayTotals.map(\.seconds) == [3600, 2700, 1200, 600])
        #expect(stats.awayTotals.allSatisfy { $0.percent == 0 && $0.isNamed })
    }

    @Test func dayTiesSortByName() {
        let day = Fix.day(4, [away(4, (10, 0), (10, 30), place: .walk), away(4, (11, 0), (11, 30), place: .lunch)])
        #expect(ActivityDayStats(day).awayTotals.map(\.name) == ["Lunch", "Walk"])
    }

    @Test func dayAwayTotalsDoNotChangeTheOtherNumbers() {
        let stats = ActivityDayStats(Fix.day(4, items))
        #expect(stats.realWork == 3600)
        #expect(stats.categories.map(\.name) == ["Coding"])
        #expect(stats.categories.first?.percent == 100)
        #expect(stats.away == stats.awayTotals.reduce(0) { $0 + $1.seconds })
    }

    @Test func overviewExposesTheAwayTotals() {
        let day = Fix.day(4, items)
        let overview = ActivityDayOverview(day, loggedChange: .none)
        #expect(overview.awayTotals == ActivityDayStats(day).awayTotals)
        #expect(overview.topPlace == "Walk")
    }

    @Test func noAwayGivesNoRows() {
        #expect(ActivityDayStats(Fix.day(4, [Fix.work("Docs", "Coding", 4, (9, 0), (10, 0))])).awayTotals.isEmpty)
    }

    @Test func rangeHasOneAwayRowPerPlaceSummedOverDays() {
        let days = [
            Fix.day(4, [Fix.work("A", "Coding", 4, (9, 0), (10, 0)), away(4, (10, 0), (10, 30), place: .lunch)]),
            Fix.day(
                5,
                [Fix.work("B", "Coding", 5, (9, 0), (10, 0)), away(5, (10, 0), (11, 0), place: .lunch), away(5, (12, 0), (12, 20), place: .walk)]
            )
        ]
        let stats = ActivityRangeStats(days, compare: [])
        let rows = stats.categories.filter { $0.kind == .away }
        #expect(rows.map(\.name) == ["Lunch", "Walk"])
        #expect(rows.map(\.seconds) == [5400, 1200])
        #expect(rows.map(\.id).count == Set(rows.map(\.id)).count)
        #expect(stats.away == 6600)
        #expect(stats.realWork == 7200)
    }

    @Test func rangeAwayRowsCompareWithTheRangeBefore() {
        let now = [Fix.day(4, [Fix.work("A", "Coding", 4, (9, 0), (10, 0)), away(4, (10, 0), (11, 0), place: .lunch)])]
        let before = [Fix.day(1, [Fix.work("A", "Coding", 1, (9, 0), (10, 0)), away(1, (10, 0), (10, 30), place: .lunch)])]
        let lunch = ActivityRangeStats(now, compare: before).categories.first { $0.kind == .away }
        #expect(lunch?.change == .up(1800))
    }
}
