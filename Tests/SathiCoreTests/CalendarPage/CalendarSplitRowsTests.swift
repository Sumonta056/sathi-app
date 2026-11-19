import Foundation
@testable import SathiCore
import Testing

@Suite("Calendar split layout: rows")
struct CalendarSplitRowsTests {
    private let hourRows = 24
    private let tenAMRow = 4
    private let grown = 12.0

    @Test func oneRowPerZoomStepAtTheBaseScale() {
        let grid = Split.layout([])
        #expect(grid.rows.count == hourRows)
        #expect(grid.rows.map(\.startMinute) == Array(stride(from: 0, to: 1440, by: 60)))
        #expect(grid.rows.map(\.endMinute) == Array(stride(from: 60, through: 1440, by: 60)))
        #expect(grid.rows.allSatisfy { $0.height == 60 && !$0.isFold })
        #expect(grid.rows.map(\.top) == stride(from: 0, to: 1440, by: 60).map(Double.init))
        #expect(grid.height == 1440)
    }

    @Test(arguments: [(30, 2.0), (15, 4.0)])
    func zoomedRowsKeepTheirHeight(_ rowMinutes: Int, _ ppm: Double) {
        let m = Split.metrics(pointsPerMinute: ppm, minHeight: 46, awayMinHeight: 40, gap: 4, folds: false)
        let grid = Split.layout([], rowMinutes: rowMinutes, metrics: m)
        #expect(grid.rows.count == 1440 / rowMinutes)
        #expect(grid.rowAt(1)?.startMinute == rowMinutes)
        #expect(grid.rows.allSatisfy { $0.height == Double(rowMinutes) * ppm })
    }

    @Test func rowGrowsSoThePushedTitleStartsInsideIt() {
        let grid = Split.layout([Split.activity("a", "10:00", "10:10"), Split.activity("b", "10:20", "11:00")])
        let b = Split.laid(grid, "b")
        #expect(Split.laid(grid, "a")?.bottom == 286)
        #expect(b?.top == 290)
        #expect(b?.bottom == 336)
        #expect(grid.rowAt(tenAMRow)?.top == 240)
        #expect(grid.rowAt(tenAMRow)?.height == 60 + grown)
        #expect(grid.rowAt(tenAMRow + 1)?.top == 300 + grown)
        #expect(grid.rows.enumerated().allSatisfy { $0.offset == tenAMRow || $0.element.height == 60 })
        #expect(grid.height == 1440 + grown)
    }

    @Test func titleRoomFitsWithoutGrowth() {
        let grid = Split.layout([Split.activity("a", "10:00", "10:05"), Split.activity("b", "10:10", "10:40")], metrics: Split.weekFlat)
        #expect(grid.rowAt(tenAMRow)?.height == 60)
    }

    @Test func blockStartingLateInARowGrowsThatRowOnly() {
        let grid = Split.layout([Split.event("late", "10:50", "11:30")])
        #expect(Split.laid(grid, "late")?.top == 290)
        #expect(grid.rowAt(tenAMRow)?.height == 60 + grown)
        #expect(Split.laid(grid, "late")?.bottom == 300 + grown + 30)
    }

    @Test func weekDaysShareTheGrownRows() {
        let tuesday = Split.key(Split.monday + 1)
        let grid = Split.layout(
            [
                Split.activity("a", "10:00", "10:10"),
                Split.activity("b", "10:20", "11:00"),
                Split.event("tue", "11:00", "12:00", on: Split.monday + 1)
            ],
            days: [Split.page, tuesday]
        )
        #expect(grid.rowAt(tenAMRow)?.height == 60 + grown)
        #expect(Split.laid(grid, "tue", on: tuesday)?.top == 300 + grown)
        #expect(Split.laid(grid, "tue", on: tuesday)?.bottom == 360 + grown)
    }

    @Test func zoomedRowGrowsWithTheSameScale() {
        let ppm = 2.0
        let m = Split.metrics(pointsPerMinute: ppm, minHeight: 46, awayMinHeight: 40, gap: 4, folds: false)
        let grid = Split.layout([Split.activity("a", "10:00", "10:05"), Split.activity("b", "10:10", "10:25")], rowMinutes: 30, metrics: m)
        let tenAMHalfRow = 8
        let rowTop = 480.0
        let rowHeight = 60.0
        let pushedTop = rowTop + m.minHeight + m.gap
        let growth = pushedTop + m.titleRoom - (rowTop + rowHeight)
        #expect(Split.laid(grid, "b")?.top == pushedTop)
        #expect(grid.rowAt(tenAMHalfRow)?.height == rowHeight + growth)
        #expect(grid.rowAt(tenAMHalfRow + 1)?.top == rowTop + rowHeight + growth)
    }

    @Test func busyRunHasNoOverlapProblems() {
        let grid = Split.layout([
            Split.activity("a", "15:01", "15:06"), Split.away("b", "15:06", "15:08"), Split.activity("c", "15:08", "15:10"),
            Split.away("d", "15:10", "15:35"), Split.activity("e", "15:35", "15:39"), Split.away("f", "15:41", "16:23"),
            Split.activity("g", "16:23", "16:26")
        ], metrics: Split.weekFlat)
        #expect(SplitCheck.problems(grid, metrics: Split.weekFlat) == [])
        #expect((grid.rowAt(9)?.height ?? 0) > 60)
    }

    @Test func raisedItemNeverSitsAbovePushedParent() {
        let grid = Split.layout([
            Split.activity("p0", "09:40", "09:50"), Split.activity("p1", "09:45", "09:50"),
            Split.activity("a", "10:00", "12:00"), Split.activity("r", "10:30", "11:00"), Split.activity("r2", "10:31", "10:50")
        ], metrics: Split.metrics(minHeight: 80, awayMinHeight: 80, gap: 4, folds: false))
        let a = Split.laid(grid, "a")
        let r = Split.laid(grid, "r")
        #expect(r?.depth == 1)
        #expect(a.map { $0.top > Split.y(grid, "10:00") ?? 0 } == true)
        #expect((r?.top ?? 0) >= (a?.top ?? .infinity))
    }
}
