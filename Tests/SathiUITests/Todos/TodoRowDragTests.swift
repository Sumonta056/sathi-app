import SathiCore
@testable import SathiUI
import SwiftUI
import Testing

@Suite("TodoRowDrag")
struct TodoRowDragTests {
    @Test(arguments: [
        (TodoSelection.list("inbox"), true),
        (.smart(.all), true),
        (.smart(.today), false),
        (.smart(.scheduled), false),
        (.smart(.completed), false)
    ])
    func onlyListPagesAndAllDrag(_ selection: TodoSelection, _ expected: Bool) {
        #expect(TodoItemsColumn.canDrag(selection) == expected)
    }
}

@Suite("TodoReorder")
struct TodoReorderTests {
    private let mids: [CGFloat] = [10, 30, 50, 70]

    @Test func noMoveKeepsThePlace() {
        #expect(TodoReorder.target(from: 1, mids: mids, dy: 0) == 1)
    }

    @Test func movingDownPastAMidMovesOnePlace() {
        #expect(TodoReorder.target(from: 0, mids: mids, dy: 21) == 1)
        #expect(TodoReorder.target(from: 0, mids: mids, dy: 19) == 0)
    }

    @Test func movingFarDownGoesToTheEnd() {
        #expect(TodoReorder.target(from: 0, mids: mids, dy: 500) == 3)
    }

    @Test func movingUpGoesToTheTop() {
        #expect(TodoReorder.target(from: 3, mids: mids, dy: -500) == 0)
    }

    @Test func rowsBetweenMakeRoom() {
        #expect(TodoReorder.shift(1, from: 0, to: 2) == -1)
        #expect(TodoReorder.shift(2, from: 0, to: 2) == -1)
        #expect(TodoReorder.shift(3, from: 0, to: 2) == 0)
        #expect(TodoReorder.shift(0, from: 3, to: 1) == 0)
        #expect(TodoReorder.shift(1, from: 3, to: 1) == 1)
        #expect(TodoReorder.shift(2, from: 3, to: 1) == 1)
    }

    @Test func beforeNamesTheTodoAfterTheNewPlace() {
        let ids = ["a", "b", "c", "d"]
        #expect(TodoReorder.before(ids, from: 0, to: 2) == "d")
        #expect(TodoReorder.before(ids, from: 0, to: 3) == nil)
        #expect(TodoReorder.before(ids, from: 3, to: 0) == "a")
        #expect(TodoReorder.before(ids, from: 1, to: 1) == "c")
    }

    @Test func theDraggedRowFollowsThePointerAndOthersShiftByItsHeight() {
        var s = TodoReorder()
        s.start(id: "a", peers: ["a", "b", "c"], frames: [
            "a": CGRect(x: 0, y: 0, width: 100, height: 20),
            "b": CGRect(x: 0, y: 20, width: 100, height: 40),
            "c": CGRect(x: 0, y: 60, width: 100, height: 20)
        ])
        s.update(dy: 45)
        #expect(s.to == 1)
        #expect(s.offset("a") == 45)
        #expect(s.offset("b") == -20)
        #expect(s.offset("c") == 0)
    }

    @Test func aStartWithMissingFramesDoesNotDrag() {
        var s = TodoReorder()
        s.start(id: "a", peers: ["a", "b"], frames: ["a": .zero])
        #expect(s.id == nil)
    }
}
