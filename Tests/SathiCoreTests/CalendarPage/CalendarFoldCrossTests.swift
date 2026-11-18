import Foundation
@testable import SathiCore
import Testing

@Suite("Calendar split layout: blocks never cover a fold strip")
struct CalendarFoldCrossTests {
    private func coversNoStrip(_ grid: CalendarGridLayout) -> Bool {
        let strips = grid.rows.filter(\.isFold)
        return grid.days.values.joined().filter { !$0.isTodo }.allSatisfy { b in
            strips.allSatisfy { s in b.bottom <= s.top || b.top >= s.bottom }
        }
    }

    @Test func awayEndingInsideAStripEndsAtTheStripTop() {
        let grid = Split.layout(
            [Split.activity("work", "10:00", "11:00"), Split.away("out", "10:30", "13:00")], metrics: Split.week
        )
        let strip = grid.rowAt(2)
        #expect(strip?.isFold == true)
        #expect(Split.laid(grid, "out")?.top == 52)
        #expect(Split.laid(grid, "out")?.bottom == strip?.top)
        #expect(coversNoStrip(grid))
    }

    @Test func awayCrossingAWholeStripIsDrawnInTwoParts() {
        let grid = Split.layout(
            [Split.activity("a", "10:00", "11:00"), Split.activity("b", "14:00", "15:00"), Split.away("out", "10:30", "14:30")],
            metrics: Split.week
        )
        let parts = grid.days[Split.page]?.filter { $0.block.id == "out" } ?? []
        #expect(parts.count == 2)
        #expect(Set(parts.map(\.id)).count == 2)
        #expect(parts.map(\.top) == [52, 104])
        #expect(parts.first?.bottom == grid.rowAt(2)?.top)
        #expect(parts.allSatisfy { $0.rounded == Split.span("10:30", "14:30") })
        #expect(coversNoStrip(grid))
    }

    @Test func aShortPartAboveAStripNeverReachesIntoIt() {
        let grid = Split.layout(
            [Split.activity("work", "10:00", "11:00"), Split.away("out", "10:55", "13:00")], metrics: Split.week
        )
        #expect(Split.laid(grid, "out")?.bottom == grid.rows.first { $0.isFold && $0.startMinute == 300 }?.top)
        #expect(coversNoStrip(grid))
    }
}
