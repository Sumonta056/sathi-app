import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar split layout: blocks fit their start row")
struct CalendarSplitRowFitTests {
    private let tenAMRow = 4
    private let onePMRow = 7

    private let morning = [
        Split.activity("break", "9:58", "10:23"), Split.activity("check", "10:23", "10:26"),
        Split.activity("reading", "10:26", "10:36"), Split.activity("vue", "10:37", "11:14"),
        Split.activity("review", "11:14", "11:50"), Split.activity("lunch", "11:50", "12:10"),
        Split.activity("mail", "12:10", "12:24"), Split.activity("wrap", "12:24", "12:26"),
        Split.event("scrum", "13:00", "13:25")
    ]

    private func endsInStartRow(_ b: CalendarLaidBlock, _ grid: CalendarGridLayout) -> CalendarGridRow? {
        let from = Split.minute(b.span.start, on: Split.page)
        let to = Split.minute(b.span.end, on: Split.page)
        guard let r = Split.row(grid, holding: from), to <= r.endMinute else { return nil }
        return r
    }

    @Test func noShortActivityCrossesTheHourLineAfterIt() throws {
        let grid = Split.layout(morning, metrics: Split.dayCompact)
        let blocks = try #require(grid.days[Split.page])
        for b in blocks {
            guard let r = endsInStartRow(b, grid) else { continue }
            #expect(b.bottom <= r.top + r.height, "\(b.block.title) ends at \(b.bottom) below its row end \(r.top + r.height)")
        }
        let onePM = try #require(grid.rowAt(onePMRow))
        #expect(onePM.startMinute == 420)
        #expect(try #require(Split.laid(grid, "wrap")).bottom <= onePM.top)
        #expect(Split.laid(grid, "scrum")?.top == onePM.top)
        #expect(Split.laid(grid, "wrap")?.top == 489)
        #expect(onePM.top == 515)
    }

    @Test func nowLineStaysAboveTheNextEvent() throws {
        let grid = Split.layout(morning, metrics: Split.dayCompact)
        let now = Split.at("12:26")
        let line = grid.nowY(now, minute: Split.minute(now, on: Split.page), day: Split.page)
        let scrum = try #require(Split.laid(grid, "scrum"))
        #expect(line <= scrum.top)
    }

    @Test func pushedBlockEndingInItsRowGrowsThatRowToItsBottom() {
        let grid = Split.layout([Split.activity("a", "10:00", "10:10"), Split.activity("b", "10:20", "10:50")])
        let b = Split.laid(grid, "b")
        #expect(b?.top == 290)
        #expect(b?.bottom == 336)
        #expect(grid.rowAt(tenAMRow)?.height == 96)
        #expect(grid.rowAt(tenAMRow + 1)?.top == 336)
        #expect(grid.height == 1476)
    }

    @Test func blockEndingExactlyAtTheRowEndFitsInsideTheRow() {
        let grid = Split.layout([Split.event("late", "10:50", "11:00")])
        #expect(Split.laid(grid, "late")?.top == 290)
        #expect(Split.laid(grid, "late")?.bottom == 336)
        #expect(grid.rowAt(tenAMRow + 1)?.top == 336)
    }

    @Test func blockCrossingIntoTheNextRowKeepsTheTitleRoomRule() {
        let grid = Split.layout([Split.activity("a", "10:00", "10:10"), Split.activity("b", "10:20", "11:10")])
        #expect(Split.laid(grid, "b")?.top == 290)
        #expect(grid.rowAt(tenAMRow)?.height == 72)
        #expect(grid.rowAt(tenAMRow + 1)?.top == 312)
        #expect(Split.laid(grid, "b")?.bottom == 336)
    }

    @Test func weekBlockEndingInItsRowAlsoFits() {
        let grid = Split.layout([Split.activity("a", "10:00", "10:05"), Split.activity("b", "10:10", "10:40")], metrics: Split.weekFlat)
        #expect(Split.laid(grid, "b")?.top == 276)
        #expect(Split.laid(grid, "b")?.bottom == 310)
        #expect(grid.rowAt(tenAMRow)?.height == 70)
    }
}
