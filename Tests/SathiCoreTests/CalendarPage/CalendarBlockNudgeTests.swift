import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockNudge")
struct CalendarBlockNudgeTests {
    func shown(_ blocks: [CalendarBlock], min: Double = 20) -> [String: CalendarPlacedBlock] {
        Lay.byID(CalendarBlockLayout.place(blocks, minimumMinutes: min))
    }

    @Test func shortBlocksBackToBackGetTheMinimumAndMoveDown() {
        let r = shown([Lay.activity("a", 0, 8), Lay.activity("b", 8, 16), Lay.activity("c", 16, 24)])
        #expect(r["a"]?.displaySpan == Lay.span(0, 20))
        #expect(r["b"]?.displaySpan == Lay.span(20, 40))
        #expect(r["c"]?.displaySpan == Lay.span(40, 60))
        #expect(r["b"]?.span == Lay.span(8, 16))
    }

    @Test func aGapAbsorbsTheMove() {
        let r = shown([Lay.activity("a", 0, 8), Lay.activity("b", 30, 38)])
        #expect(r["a"]?.displaySpan == Lay.span(0, 20))
        #expect(r["b"]?.displaySpan == Lay.span(30, 50))
    }

    @Test func aSmallGapAbsorbsPartOfTheMove() {
        let r = shown([Lay.activity("a", 0, 8), Lay.activity("b", 12, 20)])
        #expect(r["b"]?.displaySpan == Lay.span(20, 40))
    }

    @Test func longBlockKeepsItsTime() {
        #expect(shown([Lay.activity("a", 0, 60)])["a"]?.displaySpan == Lay.span(0, 60))
    }

    @Test func noMinimumChangesNothing() {
        let r = shown([Lay.activity("a", 0, 8), Lay.activity("b", 8, 16)], min: 0)
        #expect(r["a"]?.displaySpan == Lay.span(0, 8))
        #expect(r["b"]?.displaySpan == Lay.span(8, 16))
    }

    @Test func hostWithTwoChildrenGrowsToFitThem() {
        let host = shown([Lay.event("e", 0, 30), Lay.activity("a", 2, 10), Lay.activity("b", 10, 18)])["e"]
        #expect(host?.displaySpan == Lay.span(0, 60))
        #expect(host?.span == Lay.span(0, 30))
        #expect(host?.children.map(\.displaySpan) == [Lay.span(20, 40), Lay.span(40, 60)])
        #expect(host?.children.map(\.span) == [Lay.span(2, 10), Lay.span(10, 18)])
    }

    @Test func childKeepsItsTimeWhenItFitsBelowTheTitleRow() {
        let host = shown([Lay.event("e", 0, 120), Lay.activity("a", 50, 60)])["e"]
        #expect(host?.displaySpan == Lay.span(0, 120))
        #expect(host?.children.first?.displaySpan == Lay.span(50, 70))
    }

    @Test func grownHostPushesTheNextBlockDown() {
        let r = shown([Lay.event("e", 0, 30), Lay.activity("a", 2, 10), Lay.activity("b", 10, 18), Lay.event("f", 30, 60)])
        #expect(r["f"]?.displaySpan == Lay.span(60, 90))
    }

    @Test func awayNeverMovesAndNeverGrows() {
        let r = shown([Lay.away("w", 0, 5), Lay.activity("a", 0, 8), Lay.activity("b", 8, 16), Lay.away("x", 8, 70)])
        #expect(r["w"]?.displaySpan == Lay.span(0, 5))
        #expect(r["x"]?.displaySpan == Lay.span(8, 70))
        #expect(r["w"]?.lanes == 1)
        #expect(r["a"]?.lanes == 1)
    }

    @Test func blocksInOtherLanesDoNotPush() {
        let r = shown([Lay.activity("a", 0, 8), Lay.activity("b", 5, 13)])
        #expect(r["a"]?.lanes == 2)
        #expect(r["b"]?.displaySpan == Lay.span(5, 25))
    }

    @Test func raisedBlocksPushOnlyAtTheirDepth() {
        let r = shown([Lay.activity("a", 0, 60), Lay.activity("b", 30, 38), Lay.activity("c", 38, 46)])
        #expect(r["a"]?.displaySpan == Lay.span(0, 60))
        #expect(r["b"]?.displaySpan == Lay.span(30, 50))
        #expect(r["c"]?.depth == 1)
        #expect(r["c"]?.displaySpan == Lay.span(50, 70))
    }

    @Test func columnPlacementNudgesTheCutSpan() {
        let column = DateInterval(start: Lay.at(0), end: Lay.at(24 * 60))
        let r = Lay.byID(CalendarBlockLayout.place([Lay.activity("a", 0, 8), Lay.activity("b", 8, 16)], within: column, minimumMinutes: 20))
        #expect(r["b"]?.displaySpan == Lay.span(20, 40))
    }
}
