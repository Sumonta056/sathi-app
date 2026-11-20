import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo board add")
struct TodoBoardAddTests {
    private final class Box { var got: [String] = [] }

    @Test func tappingAPlusSendsItsListID() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let box = Box()
        let board = TodoBoard(
            sections: h.engine.todoPage(.smart(.all)).sections,
            editingID: .constant(nil),
            reorder: .constant(TodoReorder())
        ) { box.got.append($0) }
        let sut = try hosted(board, h).inspect()
        try Find.button(sut, label: "Add to-do to Work").tap()
        try Find.button(sut, label: "Add to-do to Inbox").tap()
        #expect(box.got == ["work", "inbox"])
    }

    @Test func aChosenListIsTheTargetOnlyInBoard() async {
        let h = await EngineHarness.pageFixture(allView: .board)
        let page = h.engine.todoPage(.smart(.all))
        let fallback = page.targetListID
        #expect(TodoItemsColumn.addTarget(page, chosen: "work", board: true) == "work")
        #expect(TodoItemsColumn.addTarget(page, chosen: "work", board: false) == fallback)
        #expect(TodoItemsColumn.addTarget(page, chosen: nil, board: true) == fallback)
        #expect(TodoItemsColumn.addTarget(page, chosen: "gone", board: true) == fallback)
    }

    @Test func aPageWithNoTargetHasNoField() async {
        let h = await EngineHarness.pageFixture(allView: .board)
        let page = h.engine.todoPage(.smart(.completed))
        #expect(TodoItemsColumn.addTarget(page, chosen: "work", board: true) == nil)
    }

    @Test func theAddFieldShowsAChosenList() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoAddField(listID: "work", listName: "Work"), h).inspect()
        let chip = try sut.find(viewWithAccessibilityIdentifier: "todos.add.list")
        #expect(throws: Never.self) { try chip.find(text: Copywriter.todoAddInList("Work")) }
    }

    @Test func theAddFieldShowsNoListByDefault() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoAddField(listID: "inbox"), h).inspect()
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.add.list")) == nil)
    }

    @Test func onlyARealWidthKeepsThePlacement() {
        let kept = TodoBoardLayout.Cache(ids: ["a", "b"], columns: 2, assign: [1, 0])
        #expect(TodoBoardLayout.previous(kept, ids: ["a", "b"], columns: 2, real: true) == [1, 0])
        #expect(TodoBoardLayout.previous(kept, ids: ["a", "b"], columns: 2, real: false) == nil)
        #expect(TodoBoardLayout.previous(kept, ids: ["b", "a"], columns: 2, real: true) == nil)
        #expect(TodoBoardLayout.previous(kept, ids: ["a", "b"], columns: 3, real: true) == nil)
    }

    @Test func aProbeWidthNeverSeedsThePlacement() {
        let empty = TodoBoardLayout.Cache()
        let probe = TodoBoardLayout.stored(empty, ids: ["a", "b"], columns: 2, assign: [0, 0], real: false)
        #expect(probe.assign.isEmpty)
        let real = TodoBoardLayout.stored(empty, ids: ["a", "b"], columns: 2, assign: [0, 1], real: true)
        #expect(real.assign == [0, 1])
    }
}
