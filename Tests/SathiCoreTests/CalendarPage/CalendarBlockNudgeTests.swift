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

    @Test func blocksNearTheColumnEndStayInsideTheColumn() {
        let column = Lay.span(0, 60)
        let blocks = [Lay.activity("a", 50, 52), Lay.activity("b", 52, 54), Lay.activity("c", 54, 56), Lay.activity("d", 56, 58)]
        let placed = CalendarBlockLayout.place(blocks, within: column, minimumMinutes: 26)
        #expect(placed.count == 4)
        for p in placed {
            #expect(p.displaySpan.start >= column.start)
            #expect(p.displaySpan.start < column.end)
            #expect(p.displaySpan.end <= column.end)
        }
    }

    @Test func aChildNearTheColumnEndStaysInsideTheColumn() {
        let column = Lay.span(0, 60)
        let placed = CalendarBlockLayout.place([Lay.event("e", 40, 60), Lay.activity("a", 50, 58)], within: column, minimumMinutes: 26)
        let child = placed.first?.children.first
        #expect(child?.displaySpan.start ?? column.end < column.end)
        #expect(child?.displaySpan.end ?? column.end <= column.end)
        #expect(placed.first?.displaySpan.end ?? column.end <= column.end)
    }
}

@Suite("CalendarBlockNudge raised blocks")
struct CalendarBlockNudgeRaisedTests {
    func shown(_ blocks: [CalendarBlock]) -> [String: CalendarPlacedBlock] {
        Lay.byID(CalendarBlockLayout.place(blocks, minimumMinutes: 20))
    }

    private var chain: [CalendarBlock] {
        [Lay.activity("x", 0, 2), Lay.activity("y", 2, 4), Lay.activity("z", 4, 6), Lay.event("e", 6, 40), Lay.event("r", 36, 50)]
    }

    @Test func aRaisedBlockMovesBelowNudgedBlocksAndTheTitleOfItsHost() {
        let r = shown(chain)
        #expect(r["e"]?.displaySpan == Lay.span(60, 94))
        #expect(r["r"]?.depth == 1)
        #expect(r["r"]?.displaySpan == Lay.span(80, 100))
    }

    @Test func aLaterBlockMovesBelowARaisedBlock() {
        let r = shown(chain + [Lay.activity("s", 52, 54)])
        #expect(r["s"]?.depth == 0)
        #expect(r["s"]?.displaySpan == Lay.span(100, 120))
    }

    @Test func aRaisedBlockNeverCoversTheTitleOfTheBlockBelow() {
        let r = shown([Lay.activity("p", 0, 2), Lay.activity("l", 2, 60), Lay.event("r", 35, 43)])
        #expect(r["l"]?.displaySpan == Lay.span(20, 78))
        #expect(r["r"]?.depth == 1)
        #expect(r["r"]?.displaySpan == Lay.span(40, 60))
    }

    @Test func aRaisedBlockNeverCoversAChildOfTheBlockBelow() {
        let r = shown([Lay.event("e", 0, 120), Lay.activity("c", 5, 100), Lay.event("r", 40, 50)])
        #expect(r["e"]?.children.first?.displaySpan == Lay.span(20, 115))
        #expect(r["r"]?.depth == 1)
        #expect(r["r"]?.displaySpan == Lay.span(115, 135))
    }

    @Test func aRaisedBlockStillSitsOnTheOpenPartOfALongBlock() {
        let r = shown([Lay.activity("a", 0, 120), Lay.activity("b", 40, 50)])
        #expect(r["b"]?.depth == 1)
        #expect(r["b"]?.displaySpan == Lay.span(40, 60))
    }
}
