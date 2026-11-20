import CoreGraphics
@testable import SathiUI
import Testing

@Suite("TodoBoardDropTarget")
struct TodoBoardDropTargetTests {
    private func card(_ id: String, _ y: Double, _ h: Double = 100, x: Double = 0) -> TodoBoardDropCard {
        TodoBoardDropCard(id: id, frame: CGRect(x: x, y: y, width: 200, height: h))
    }

    private var columns: [TodoBoardDropColumn] {
        [
            TodoBoardDropColumn(frame: CGRect(x: 0, y: 0, width: 200, height: 400), cards: [card("a", 0), card("b", 116)]),
            TodoBoardDropColumn(frame: CGRect(x: 216, y: 0, width: 200, height: 400), cards: [card("c", 0, x: 216)]),
            TodoBoardDropColumn(frame: CGRect(x: 432, y: 0, width: 200, height: 400), cards: [])
        ]
    }

    private func target(_ x: Double, _ y: Double, excluding: String? = nil) -> (column: Int, before: String?) {
        TodoBoardDropTarget.target(point: CGPoint(x: x, y: y), columns: columns, excluding: excluding)
    }

    @Test func aPointAboveTheFirstCardsMiddleDropsBeforeIt() {
        let t = target(100, 20)
        #expect(t.column == 0)
        #expect(t.before == "a")
    }

    @Test func aPointBelowAMiddleDropsBeforeTheNextCard() {
        let t = target(100, 80)
        #expect(t.column == 0)
        #expect(t.before == "b")
    }

    @Test func aPointBelowTheLastMiddleDropsAtTheEnd() {
        let t = target(100, 300)
        #expect(t.column == 0)
        #expect(t.before == nil)
    }

    @Test func theColumnComesFromTheXPosition() {
        #expect(target(300, 10).column == 1)
        #expect(target(500, 10).column == 2)
    }

    @Test func anEmptyColumnDropsAtTheEnd() {
        let t = target(500, 50)
        #expect(t.column == 2)
        #expect(t.before == nil)
    }

    @Test func aPointInTheGapGoesToTheNearestColumn() {
        #expect(target(205, 10).column == 0)
        #expect(target(212, 10).column == 1)
    }

    @Test func aPointLeftOfAllColumnsIsTheFirstAndRightOfAllIsTheLast() {
        #expect(target(-500, 10).column == 0)
        #expect(target(5000, 10).column == 2)
    }

    @Test func aPointAboveEverythingDropsBeforeTheFirstCard() {
        let t = target(100, -300)
        #expect(t.column == 0)
        #expect(t.before == "a")
    }

    @Test func theLiftedBoardIsIgnoredWhenFindingTheSlot() {
        let t = target(100, 20, excluding: "a")
        #expect(t.column == 0)
        #expect(t.before == "b")
    }

    @Test func droppingBackOnTheOnlyOtherCardOfAColumnWithTheLiftedBoardGivesTheEnd() {
        let t = target(300, 10, excluding: "c")
        #expect(t.column == 1)
        #expect(t.before == nil)
    }

    @Test func noColumnsGivesColumnZeroWithoutANeighbour() {
        let t = TodoBoardDropTarget.target(point: .zero, columns: [], excluding: nil)
        #expect(t.column == 0)
        #expect(t.before == nil)
    }
}
