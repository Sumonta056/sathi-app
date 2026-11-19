import Foundation
@testable import SathiCore
import Testing

@Suite("Calendar split layout: page-day cut")
struct CalendarSplitCutTests {
    private let tuesday = Split.monday + 1
    private var days: [DayKey] { [Split.page, Split.key(tuesday)] }

    @Test func blockAcrossSixAMIsCutForEachColumn() {
        let block = Split.activity("late", DateInterval(start: Split.at("04:00"), end: Split.at("08:00", on: tuesday)))
        let grid = Split.layout([block], days: days, metrics: Split.weekFlat)
        let sixAM = Split.at("06:00", on: tuesday)
        let monday = Split.laid(grid, "late")
        #expect(monday?.span == DateInterval(start: Split.at("04:00"), end: sixAM))
        #expect(Split.laid(grid, "late", on: Split.key(tuesday))?.span == DateInterval(start: sixAM, end: Split.at("08:00", on: tuesday)))
        #expect(monday?.block.interval == block.interval)
    }

    @Test func blockOutsideTheColumnIsDropped() {
        let grid = Split.layout([Split.activity("next", "09:00", "10:00", on: tuesday)])
        #expect(Split.laid(grid, "next") == nil)
    }

    @Test func zeroLengthBlockAtTheColumnStartBelongsToThatDay() {
        let grid = Split.layout([Split.todo("due", "06:00", on: tuesday)], days: days, metrics: Split.weekFlat)
        #expect(Split.laid(grid, "due", on: Split.key(tuesday)) != nil)
        #expect(Split.laid(grid, "due") == nil)
    }
}
