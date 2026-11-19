import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar now line")
struct CalendarNowLineTests {
    private let blocks = [
        Split.activity("break", "9:58", "10:23"),
        Split.activity("check", "10:23", "10:26"),
        Split.activity("reading", "10:26", "10:36"),
        Split.activity("vue", "10:37", "10:46")
    ]

    private func y(_ grid: CalendarGridLayout, _ clock: String) -> Double {
        let now = Split.at(clock)
        return grid.nowY(now, minute: Split.minute(now, on: Split.page), day: Split.page)
    }

    @Test func lineIsBelowEveryBlockThatEndedBeforeNow() throws {
        let grid = Split.layout(blocks)
        let vue = try #require(Split.laid(grid, "vue"))
        #expect(y(grid, "10:47") >= vue.bottom)
        let clock = try #require(Split.y(grid, "10:47"))
        #expect(y(grid, "10:47") > clock)
    }

    @Test func insideABlockTheLineSitsAtTheSameShareOfItsDrawnHeight() throws {
        let grid = Split.layout(blocks)
        let reading = try #require(Split.laid(grid, "reading"))
        let line = y(grid, "10:31")
        #expect(abs(line - (reading.top + (reading.bottom - reading.top) / 2)) < 0.001)
    }

    @Test func withNoBlockBeforeNowTheLineUsesTheClock() throws {
        let grid = Split.layout(blocks)
        #expect(try y(grid, "8:30") == #require(Split.y(grid, "8:30")))
    }

    @Test func blocksOfOtherDaysDoNotMoveTheLine() {
        let grid = Split.layout(blocks, days: [Split.page, Split.key(Split.monday + 1)])
        let now = Split.at("10:47", on: Split.monday + 1)
        let next = Split.key(Split.monday + 1)
        let line = grid.nowY(now, minute: Split.minute(now, on: next), day: next)
        #expect(line == grid.y(atMinute: Split.minute(now, on: next)))
    }

    @Test func theLineNeverMovesUpAsTimePasses() {
        let grid = Split.layout(blocks)
        let ys = ["10:20", "10:24", "10:30", "10:36", "10:40", "10:47", "10:55"].map { y(grid, $0) }
        #expect(ys == ys.sorted())
    }
}
