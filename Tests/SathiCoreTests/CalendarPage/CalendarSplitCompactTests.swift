import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar split layout: compact Day cards")
struct CalendarSplitCompactTests {
    private let tenAMRow = 4

    @Test func shortActivityIsACompactCard() {
        let grid = Split.layout([Split.activity("check", "10:00", "10:03")], metrics: Split.dayCompact)
        #expect(Split.laid(grid, "check")?.top == 240)
        #expect(Split.laid(grid, "check")?.bottom == 266)
    }

    @Test func shortEventIsACompactCard() {
        let grid = Split.layout([Split.event("call", "10:00", "10:03")], metrics: Split.dayCompact)
        #expect(Split.laid(grid, "call")?.bottom == 266)
    }

    @Test func activityTallerThanTheCompactHeightKeepsItsRealHeight() {
        let grid = Split.layout([Split.activity("read", "10:00", "10:30")], metrics: Split.dayCompact)
        #expect(Split.laid(grid, "read")?.bottom == 270)
    }

    @Test func activityAtTheMinimumHeightIsNotCompact() {
        let grid = Split.layout([Split.activity("focus", "10:00", "10:46")], metrics: Split.dayCompact)
        #expect(Split.laid(grid, "focus")?.bottom == 286)
    }

    @Test func compactCardsPushLess() {
        let grid = Split.layout(
            [Split.activity("a", "10:00", "10:03"), Split.activity("b", "10:05", "10:08")], metrics: Split.dayCompact
        )
        #expect(Split.laid(grid, "b")?.top == 270)
        #expect(Split.laid(grid, "b")?.bottom == 296)
        #expect(grid.rowAt(tenAMRow)?.height == 60)
    }

    @Test func awayKeepsItsOwnMinimumHeight() {
        let grid = Split.layout([Split.away("lunch", "10:00", "10:03")], metrics: Split.dayCompact)
        #expect(Split.laid(grid, "lunch")?.bottom == 280)
    }

    @Test func withoutACompactHeightAShortBlockKeepsTheMinimumHeight() {
        let week = Split.layout([Split.activity("check", "10:00", "10:03")], metrics: Split.weekFlat)
        let day = Split.layout([Split.activity("check", "10:00", "10:03")], metrics: Split.day)
        #expect(Split.laid(week, "check")?.bottom == 274)
        #expect(Split.laid(day, "check")?.bottom == 286)
    }

    @Test func compactHeightIsKeptByTheMetrics() {
        #expect(Split.dayCompact.compactHeight == 26)
        #expect(Split.weekFlat.compactHeight == nil)
    }
}
