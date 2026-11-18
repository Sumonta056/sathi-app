import Foundation
@testable import SathiCore
import Testing

@Suite("Calendar split layout: lanes and raised blocks")
struct CalendarSplitLanesTests {
    private func shown(_ grid: CalendarGridLayout) -> [String] {
        (grid.days[Split.page] ?? []).map(\.block.id).sorted()
    }

    private func hidden(_ grid: CalendarGridLayout) -> [String] {
        (grid.days[Split.page] ?? []).flatMap(\.hidden).map(\.block.id).sorted()
    }

    @Test func startsUnderThirtyMinutesApartSitSideBySide() {
        let grid = Split.layout([Split.event("a", "10:00", "11:00"), Split.event("b", "10:20", "11:00")])
        let a = Split.laid(grid, "a")
        let b = Split.laid(grid, "b")
        #expect(a?.lanes == 2)
        #expect(b?.lanes == 2)
        #expect(a?.lane == 0)
        #expect(b?.lane == 1)
        #expect(a?.depth == 0)
        #expect(b?.depth == 0)
        #expect(a?.top == 240)
        #expect(b?.top == 260)
    }

    @Test func startsThirtyMinutesApartRaiseTheLaterOne() {
        let grid = Split.layout([Split.activity("a", "10:00", "12:00"), Split.activity("b", "10:30", "11:00")])
        let a = Split.laid(grid, "a")
        let b = Split.laid(grid, "b")
        #expect(a?.depth == 0)
        #expect(a?.lanes == 1)
        #expect(a?.isRaised == false)
        #expect(b?.depth == 1)
        #expect(b?.lanes == 1)
        #expect(b?.isRaised == true)
        #expect(b?.top == 270)
    }

    @Test func thirdSideBySideItemGoesIntoTheFirstLane() {
        let grid = Split.layout([
            Split.event("a", "10:00", "11:00"), Split.event("b", "10:10", "11:00"), Split.event("c", "10:20", "11:00")
        ])
        #expect(shown(grid) == ["a", "b"])
        #expect(Split.laid(grid, "a")?.hidden.map(\.block.id) == ["c"])
        #expect(Split.laid(grid, "b")?.hidden.isEmpty == true)
    }

    @Test func depthThreeGoesIntoAHiddenBadge() {
        let grid = Split.layout([
            Split.activity("a", "10:00", "14:00"), Split.activity("b", "10:30", "14:00"),
            Split.activity("c", "11:00", "14:00"), Split.activity("d", "11:30", "14:00")
        ])
        #expect(Split.laid(grid, "b")?.depth == 1)
        #expect(Split.laid(grid, "c")?.depth == Limits.calendarCascadeMaxDepth)
        #expect(shown(grid) == ["a", "b", "c"])
        #expect(hidden(grid) == ["d"])
    }

    @Test func itemsThatDoNotOverlapInRealTimeNeverShareWidth() {
        let grid = Split.layout([Split.activity("a", "10:00", "10:05"), Split.activity("b", "10:10", "10:40")])
        #expect(Split.laid(grid, "a")?.lanes == 1)
        #expect(Split.laid(grid, "b")?.lanes == 1)
        #expect(Split.laid(grid, "b")?.depth == 0)
    }

    @Test func lanesArePerDay() {
        let tuesday = Split.key(Split.monday + 1)
        let grid = Split.layout(
            [Split.event("mon", "10:00", "11:00"), Split.event("tue", "10:10", "11:00", on: Split.monday + 1)],
            days: [Split.page, tuesday]
        )
        #expect(Split.laid(grid, "mon")?.lanes == 1)
        #expect(Split.laid(grid, "tue", on: tuesday)?.lanes == 1)
    }

    @Test func todoIsPlanAtItsDueTimeWithoutALane() {
        let grid = Split.layout([Split.event("a", "10:00", "11:00"), Split.todo("pay", "10:15")])
        let pay = Split.laid(grid, "pay")
        #expect(pay?.half == .plan)
        #expect(pay?.top == 255)
        #expect(pay?.lane == 0)
        #expect(pay?.lanes == 1)
        #expect(pay?.depth == 0)
        #expect(Split.laid(grid, "a")?.lanes == 1)
    }

    @Test func todoNeverMovesOrHidesAnotherBlock() {
        let others = [
            Split.event("a", "10:00", "11:00"), Split.event("b", "10:20", "10:50"), Split.event("c", "11:01", "11:30"),
            Split.activity("d", "10:00", "10:05"), Split.activity("e", "10:12", "10:30")
        ]
        let todos = [Split.todo("t1", "10:00"), Split.todo("t2", "10:10"), Split.todo("t3", "10:59")]
        let with = Split.layout(others + todos, metrics: Split.weekFlat)
        let without = Split.layout(others, metrics: Split.weekFlat)
        let kept = (with.days[Split.page] ?? []).filter { !SplitCheck.isTodo($0.block) }
        #expect(with.days[Split.page]?.count == others.count + todos.count)
        #expect(kept.sorted { $0.id < $1.id } == (without.days[Split.page] ?? []).sorted { $0.id < $1.id })
        #expect(with.rows == without.rows)
        #expect(hidden(with).allSatisfy { !$0.hasPrefix("t") })
    }

    @Test func allDayTodoIsNotInTheGrid() {
        let grid = Split.layout([Split.todo("bill", "00:00", allDay: true), Split.todo("call", "10:00")])
        #expect(Split.laid(grid, "bill") == nil)
        #expect(Split.laid(grid, "call")?.top == 240)
    }
}
