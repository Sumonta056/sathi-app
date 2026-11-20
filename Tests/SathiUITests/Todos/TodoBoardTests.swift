import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo board")
struct TodoBoardTests {
    private func column(_ h: EngineHarness, _ sel: TodoSelection = .smart(.all)) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoItemsColumn(selection: sel), h).inspect()
    }

    private func card(_ sut: InspectableView<ViewType.ClassifiedView>, _ id: String) throws -> InspectableView<ViewType.ClassifiedView> {
        try sut.find(viewWithAccessibilityIdentifier: "todos.board.card." + id)
    }

    @Test func allShowsTheBoardWhenTheViewIsBoard() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let sut = try column(h)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.board") }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.section.inbox")) == nil)
    }

    @Test func allShowsSectionsWhenTheViewIsList() async throws {
        let h = await EngineHarness.pageFixture(allView: .list)
        let sut = try column(h)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.board")) == nil)
        for id in ["inbox", "work", "ro"] {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.section." + id) }
        }
    }

    @Test func theBoardHasOneCardForEachListWithOpenTodos() async throws {
        let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("work", "Work"), makeTodoList("empty", "Empty")]
        let h = await EngineHarness.todosReady(lists: lists, items: [
            makeTodo("a", "Alpha", list: "inbox"),
            makeTodo("b", "Bravo", list: "work"),
            makeTodo("z", "Zulu", list: "empty", done: true, doneAt: day(2026, 3, 3, 12))
        ]) { $0.prefs.todos.allView = .board }
        let sut = try column(h)
        #expect(throws: Never.self) { try card(sut, "inbox") }
        #expect(throws: Never.self) { try card(sut, "work") }
        #expect((try? card(sut, "empty")) == nil)
    }

    @Test func eachCardHoldsOnlyItsOwnOpenTodos() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let sut = try column(h)
        let inbox = try card(sut, "inbox")
        for title in ["Alpha", "Charlie", "Foxtrot"] {
            #expect(throws: Never.self) { try inbox.find(text: title) }
        }
        for title in ["Bravo", "Delta", "Echo", "Golf", "Hotel"] {
            #expect(Find.lacks(inbox, text: title))
        }
        let work = try card(sut, "work")
        for title in ["Bravo", "Delta"] {
            #expect(throws: Never.self) { try work.find(text: title) }
        }
        for title in ["Alpha", "Hotel"] {
            #expect(Find.lacks(work, text: title))
        }
    }

    @Test func eachCardHeaderShowsTheNameAndTheOpenCount() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let inbox = try card(column(h), "inbox")
        #expect(throws: Never.self) { try inbox.find(text: "Inbox") }
        #expect(throws: Never.self) { try inbox.find(text: "3") }
        #expect(throws: Never.self) { try inbox.find(viewWithAccessibilityIdentifier: "todos.board.dot.inbox") }
    }

    @Test func eachCardHasAPlusButtonThatNamesItsList() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let sut = try column(h)
        for (id, name) in [("inbox", "Inbox"), ("work", "Work")] {
            let c = try card(sut, id)
            #expect(throws: Never.self) { try c.find(viewWithAccessibilityIdentifier: "todos.board.add." + id) }
            #expect(throws: Never.self) { try Find.button(c, label: "Add to-do to " + name) }
        }
    }

    @Test func eachCardRowIsATodoRow() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let work = try card(column(h), "work")
        #expect(work.findAll(TodoRow.self).count == 2)
    }

    @Test func theSwitchShowsOnAllOnly() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let all = try column(h)
        #expect(throws: Never.self) { try all.find(viewWithAccessibilityIdentifier: "todos.view.switch") }
        for selection in [TodoSelection.smart(.today), .smart(.scheduled), .smart(.completed), .list("inbox")] {
            let sut = try column(h, selection)
            #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.view.switch")) == nil)
        }
    }

    @Test func theSwitchHasListAndBoardButtons() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let sw = try column(h).find(viewWithAccessibilityIdentifier: "todos.view.switch")
        #expect(throws: Never.self) { try Find.button(sw, holding: "List") }
        #expect(throws: Never.self) { try Find.button(sw, holding: "Board") }
    }

    @Test func tappingListSavesTheListView() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let sw = try column(h).find(viewWithAccessibilityIdentifier: "todos.view.switch")
        try Find.button(sw, holding: "List").tap()
        #expect(h.engine.data.prefs.todos.allView == .list)
    }

    @Test func tappingBoardSavesTheBoardView() async throws {
        let h = await EngineHarness.pageFixture(allView: .list)
        let sw = try column(h).find(viewWithAccessibilityIdentifier: "todos.view.switch")
        try Find.button(sw, holding: "Board").tap()
        #expect(h.engine.data.prefs.todos.allView == .board)
    }

    @Test func theCompletedToggleIsHiddenInBoardAndShownOnListPages() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let board = try column(h)
        #expect(Find.lacks(board, text: Copywriter.todoCompletedToggle(2)))
        #expect(Find.lacks(board, text: Copywriter.todoHideCompleted))
        let inbox = try column(h, .list("inbox"))
        #expect(throws: Never.self) { try inbox.find(text: Copywriter.todoCompletedToggle(1)) }
    }

    @Test func aReadOnlyListHasNoPlusButton() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let ro = try card(column(h), "ro")
        #expect((try? ro.find(viewWithAccessibilityIdentifier: "todos.board.add.ro")) == nil)
    }

    @Test func theHeaderStillShowsTheTitleAndCountInBoard() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let header = try column(h).find(viewWithAccessibilityIdentifier: "todos.header")
        let page = h.engine.todoPage(.smart(.all))
        #expect(throws: Never.self) { try header.find(text: page.title) }
        #expect(throws: Never.self) { try header.find(text: "6 open · 3 lists") }
    }

    @Test func listPagesStayFlatWhenTheViewIsBoard() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let sut = try column(h, .list("inbox"))
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.board")) == nil)
        #expect(throws: Never.self) { try sut.find(text: "Alpha") }
    }

    @Test func movingATodoInOneBoardLeavesTheOtherBoardsOrder() async {
        let h = await EngineHarness.pageFixture(allView: .board)
        let workBefore = h.engine.todoPage(.list("work")).open.map(\.id)
        let roBefore = h.engine.todoPage(.list("ro")).open.map(\.id)
        h.engine.moveTodo("c", before: "a")
        #expect(h.engine.todoPage(.list("inbox")).open.map(\.id) == ["f", "c", "a"])
        #expect(h.engine.todoPage(.list("work")).open.map(\.id) == workBefore)
        #expect(h.engine.todoPage(.list("ro")).open.map(\.id) == roBefore)
        #expect(h.engine.data.prefs.todos.order.keys.sorted() == ["inbox"])
    }

    @Test func aDragInOneBoardMovesNoRowOfAnotherBoard() {
        var s = TodoReorder()
        s.start(id: "a", peers: ["a", "c", "f"], frames: [
            "a": CGRect(x: 0, y: 0, width: 100, height: 20),
            "c": CGRect(x: 0, y: 20, width: 100, height: 20),
            "f": CGRect(x: 0, y: 40, width: 100, height: 20)
        ])
        s.update(dy: 25)
        for other in ["b", "d", "e"] {
            #expect(s.offset(other) == 0)
        }
        #expect(s.offset("a") == 25)
    }
}
