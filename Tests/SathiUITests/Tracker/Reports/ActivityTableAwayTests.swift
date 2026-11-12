import SathiCore
@testable import SathiUI
import Testing

@Suite("Activity table away rows")
struct ActivityTableAwayTests {
    private let work = [ActivityCategoryTotal(name: "Coding", isNamed: true, seconds: 7200, percent: 100)]
    private let aways = [
        ActivityCategoryTotal(name: "Lunch", isNamed: true, seconds: 10800, percent: 0),
        ActivityCategoryTotal(name: Copywriter.trackerAway, isNamed: true, seconds: 600, percent: 0)
    ]

    @Test func dayTableAppendsAwayRowsAfterTheCategories() {
        let table = ActivityTableCard.day(work, away: aways, categories: ActivityCategory.defaults)
        #expect(table.rows.map(\.name) == ["Coding", "Lunch · Away", Copywriter.trackerAway])
        #expect(table.rows[1].colorHex == NightHex.trackerAway)
    }

    @Test func awayRowsShowNoPercentAndStayOutOfTheTotalAndCount() {
        let table = ActivityTableCard.day(work, away: aways, categories: ActivityCategory.defaults)
        #expect(table.rows[1].percentText == "—")
        #expect(table.rows[0].percentText == "100%")
        #expect(table.totalSeconds == 7200)
        #expect(table.categoryRowCount == 1)
    }

    @Test func dayTableWithoutAwayIsUnchanged() {
        let table = ActivityTableCard.day(work, away: [], categories: ActivityCategory.defaults)
        #expect(table.rows.count == 1)
        #expect(table.categoryRowCount == 1)
    }

    @Test func rangeTableKeepsEveryAwayPlaceAsARow() {
        let totals = [
            ActivityRangeTotal(name: "Lunch", kind: .away, isNamed: true, seconds: 9000, percent: 0, change: .none),
            ActivityRangeTotal(name: "Coding", kind: .category, isNamed: true, seconds: 3600, percent: 100, change: .none),
            ActivityRangeTotal(name: "Walk", kind: .away, isNamed: true, seconds: 600, percent: 0, change: .none)
        ]
        let table = ActivityTableCard.range(totals, categories: ActivityCategory.defaults)
        #expect(table.rows.map(\.name) == ["Coding", "Lunch · Away", "Walk · Away"])
        #expect(table.totalSeconds == 3600)
        #expect(table.categoryRowCount == 1)
    }

    @Test func tableWithoutTheFlagKeepsOldBehavior() {
        let table = CategoryTable([
            CategoryTableInput(name: "A", colorHex: 1, seconds: 60),
            CategoryTableInput(name: "B", colorHex: 2, seconds: 120)
        ])
        #expect(table.rows.map(\.name) == ["B", "A"])
        #expect(table.totalSeconds == 180)
        #expect(table.categoryRowCount == 2)
    }
}
