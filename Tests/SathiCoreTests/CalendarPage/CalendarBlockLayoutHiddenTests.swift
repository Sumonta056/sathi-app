import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockLayout hidden blocks")
struct CalendarBlockLayoutHiddenTests {
    private func reachable(_ placed: [CalendarPlacedBlock]) -> Set<String> {
        Set(placed.flatMap { [$0.block.id] + $0.children.map(\.block.id) + $0.hidden.map(\.block.id) })
    }

    @Test func childOfAHiddenHostStaysOnTheGrid() {
        let blocks = [Lay.event("A", 0, 20), Lay.event("B", 5, 20), Lay.event("C", 10, 60), Lay.activity("c1", 40, 58)]
        let placed = CalendarBlockLayout.place(blocks)
        let top = Lay.byID(placed)
        #expect(top["c1"] != nil)
        #expect(top["c1"]?.hostID == nil)
        #expect(top["A"]?.hidden.map(\.block.id) == ["C"])
        #expect(reachable(placed) == ["A", "B", "C", "c1"])
    }

    @Test func childOfAHiddenHostMovesToAPlacedHostThatAlsoFits() {
        let blocks = [
            Lay.event("A", 0, 20), Lay.event("B", 5, 20), Lay.event("C", 10, 60), Lay.event("E", 30, 60), Lay.activity("c1", 40, 58)
        ]
        let placed = CalendarBlockLayout.place(blocks)
        #expect(reachable(placed) == ["A", "B", "C", "E", "c1"])
        #expect(Lay.byID(placed)["E"]?.children.map(\.block.id) == ["c1"])
    }

    @Test func hiddenBlocksAreKeptOnTheGroupsFirstBlock() {
        let placed = Lay.byID(CalendarBlockLayout.place([Lay.activity("a", 0, 60), Lay.activity("b", 5, 60), Lay.activity("c", 10, 60)]))
        #expect(placed["a"]?.hidden.map(\.block.id) == ["c"])
        #expect(placed["a"]?.hiddenCount == 1)
        #expect(placed["a"]?.hidden.first?.span == Lay.span(10, 60))
    }

    @Test func blocksBeyondTheDepthCapAreHiddenNotStacked() {
        let blocks = [Lay.event("A", 0, 300), Lay.event("B", 60, 300), Lay.event("C", 120, 300), Lay.event("D", 180, 300)]
        let placed = CalendarBlockLayout.place(blocks)
        let top = Lay.byID(placed)
        #expect(placed.filter { $0.depth == Limits.calendarCascadeMaxDepth }.map(\.block.id) == ["C"])
        #expect(top["C"]?.hidden.map(\.block.id) == ["D"])
        #expect(reachable(placed) == ["A", "B", "C", "D"])
    }

    @Test func everyBlockIsReachableInACrowdedColumn() {
        let blocks = [
            Lay.event("A", 0, 300), Lay.event("B", 5, 300), Lay.event("C", 10, 300), Lay.event("D", 60, 200),
            Lay.event("E", 120, 180), Lay.event("F", 130, 170), Lay.activity("x", 125, 160), Lay.activity("y", 200, 230)
        ]
        #expect(reachable(CalendarBlockLayout.place(blocks)) == ["A", "B", "C", "D", "E", "F", "x", "y"])
    }
}
