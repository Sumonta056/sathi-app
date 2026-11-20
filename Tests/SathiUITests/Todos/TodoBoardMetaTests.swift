import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo board row meta")
struct TodoBoardMetaTests {
    private func row(_ h: EngineHarness, _ todo: Todo, below: Bool) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoRow(todo: todo, canEdit: true, metaBelow: below, onSelect: {}), h).inspect()
    }

    private func todo(due: TodoDue? = nil, repeats: Bool = false) -> Todo {
        var t = makeTodo("a", "Linkedin Posting Every 2 Weeks", due: due)
        t.repeats = repeats
        return t
    }

    private func texts(_ view: InspectableView<some BaseViewType>) -> [String] {
        view.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    private func dueText(_ h: EngineHarness, _ due: TodoDue) -> String {
        Copywriter.todoDueText(due, now: h.engine.now, calendar: h.engine.calendar)
    }

    private var future: TodoDue { TodoDue(date: day(2026, 3, 6, 14, 30), hasTime: true) }
    private var overdue: TodoDue { TodoDue(date: day(2026, 3, 2, 9), hasTime: false) }

    @Test func belowMetaShowsRepeatsThenDueUnderTheTitle() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, todo(due: future, repeats: true), below: true)
        let line = try sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.below.a")
        #expect(texts(line) == [Copywriter.todoRepeats, Copywriter.todoBoardMetaSeparator, dueText(h, future)])
        let column = try line.find(ViewType.VStack.self, relation: .parent)
        #expect(throws: Never.self) { try column.find(viewWithAccessibilityIdentifier: "todos.row.title.a") }
    }

    @Test func belowMetaWithOnlyADueDateHasNoSeparator() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, todo(due: future), below: true)
        let line = try sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.below.a")
        #expect(texts(line) == [dueText(h, future)])
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.sep.a")) == nil)
    }

    @Test func belowMetaWithOnlyRepeatsHasNoSeparator() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, todo(repeats: true), below: true)
        let line = try sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.below.a")
        #expect(texts(line) == [Copywriter.todoRepeats])
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.sep.a")) == nil)
    }

    @Test func belowSeparatorHasItsIdentifierWhenBothExist() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, todo(due: future, repeats: true), below: true)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.sep.a") }
    }

    @Test func belowRowWithNoMetaHasNoSecondLine() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, todo(), below: true)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.below.a")) == nil)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.a")) == nil)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.row.title.a") }
    }

    @Test func belowTitleSharesNoLineWithTheMeta() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, todo(due: future, repeats: true), below: true)
        let title = try sut.find(viewWithAccessibilityIdentifier: "todos.row.title.a")
        let column = try title.find(ViewType.VStack.self, relation: .parent)
        let rowsInColumn = column.findAll(ViewType.HStack.self)
        for line in rowsInColumn {
            #expect((try? line.find(viewWithAccessibilityIdentifier: "todos.row.title.a")) == nil)
        }
    }

    @Test func belowDueKeepsItsIdentifier() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, todo(due: future), below: true)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.row.due.a") }
    }

    @Test func overdueDueTextStaysCoralBelow() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, todo(due: overdue), below: true)
        let due = try sut.find(viewWithAccessibilityIdentifier: "todos.row.due.a")
        #expect(try due.foregroundStyleShapeStyle(Color.self) == Night.todoOverdue)
    }

    @Test func listRowKeepsTheMetaOnTheTitleRowByDefault() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoRow(todo: todo(due: future, repeats: true), canEdit: true, onSelect: {}), h).inspect()
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.below.a")) == nil)
        let meta = try sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.a")
        let titleRow = try meta.find(ViewType.HStack.self, relation: .parent)
        #expect(throws: Never.self) { try titleRow.find(viewWithAccessibilityIdentifier: "todos.row.title.a") }
    }

    @Test func aBoardCardRowShowsItsMetaBelowTheTitle() async throws {
        var item = todo(due: future, repeats: true)
        item.listID = "inbox"
        let h = await EngineHarness.todosReady(lists: [makeTodoList("inbox", "Inbox")], items: [item]) { $0.prefs.todos.allView = .board }
        let sut = try hosted(TodoItemsColumn(selection: .smart(.all)), h).inspect()
        let card = try sut.find(viewWithAccessibilityIdentifier: "todos.board.card.inbox")
        #expect(throws: Never.self) { try card.find(viewWithAccessibilityIdentifier: "todos.row.meta.below.a") }
    }

    @Test func aListSectionRowKeepsItsMetaOnTheRight() async throws {
        var item = todo(due: future, repeats: true)
        item.listID = "inbox"
        let h = await EngineHarness.todosReady(lists: [makeTodoList("inbox", "Inbox")], items: [item]) { $0.prefs.todos.allView = .list }
        let sut = try hosted(TodoItemsColumn(selection: .smart(.all)), h).inspect()
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.below.a")) == nil)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.row.meta.a") }
    }
}
