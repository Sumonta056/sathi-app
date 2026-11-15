import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todos page")
struct TodosPageTests {
    @Test func allowedShowsTheSideColumnAndTheItemsColumn() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodosPage(), h).inspect()
        #expect(throws: Never.self) { try sut.find(TodoSideColumn.self) }
        #expect(throws: Never.self) { try sut.find(TodoItemsColumn.self) }
        #expect((try? sut.find(TodoAccessGate.self)) == nil)
    }

    @Test func notAskedShowsTheAllowButtonAndAsksOnTap() async throws {
        let h = await EngineHarness.todosReady(access: .notAsked)
        h.todos.accessAfterRequest = .allowed
        let sut = try hosted(TodosPage(), h).inspect()
        #expect(throws: Never.self) { try sut.find(TodoAccessGate.self) }
        #expect((try? sut.find(TodoSideColumn.self)) == nil)
        try Find.button(sut, holding: "Allow Reminders access").tap()
        await waitUntil { h.todos.requestCount == 1 }
        #expect(h.todos.requestCount == 1)
        #expect(Find.lacks(sut, text: "Open System Settings"))
    }

    @Test func deniedShowsOpenSystemSettingsAndOpensThePrivacyPane() async throws {
        let h = await EngineHarness.todosReady(access: .denied)
        let sut = try hosted(TodosPage(), h).inspect()
        #expect(Find.lacks(sut, text: "Allow Reminders access"))
        try Find.button(sut, holding: "Open System Settings").tap()
        #expect(h.links.opened.map(\.absoluteString) == [todoRemindersPrivacyURL])
        #expect(h.todos.requestCount == 0)
    }

    @Test func theGateHasStableIdentifiers() async throws {
        let notAsked = try await hosted(TodoAccessGate(), EngineHarness.todosReady(access: .notAsked)).inspect()
        #expect(throws: Never.self) { try notAsked.find(viewWithAccessibilityIdentifier: "todos.access.allow") }
        let denied = try await hosted(TodoAccessGate(), EngineHarness.todosReady(access: .denied)).inspect()
        #expect(throws: Never.self) { try denied.find(viewWithAccessibilityIdentifier: "todos.access.open") }
    }

    @Test func pageOpensOnTodayByDefault() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodosPage(), h).inspect()
        #expect(try sut.find(TodoItemsColumn.self).actualView().selection == .smart(.today))
    }

    @Test func pageCanOpenOnAGivenSelection() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodosPage(selection: .list("work")), h).inspect()
        #expect(try sut.find(TodoItemsColumn.self).actualView().selection == .list("work"))
    }
}

@MainActor
@Suite("Todos side column")
struct TodoSideColumnTests {
    private func column(_ h: EngineHarness, _ box: Box<TodoSelection>) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoSideColumn(selection: box.binding), h).inspect()
    }

    @Test func showsFourSmartTilesWithCounts() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try column(h, Box(.smart(.today)))
        for (list, count) in [(TodoSmartList.today, 3), (.scheduled, 4), (.all, 6), (.completed, 2)] {
            let tile = try sut.find(viewWithAccessibilityIdentifier: "todos.tile.\(list.rawValue)")
            #expect(throws: Never.self) { try tile.find(text: Copywriter.todoSmartListName(list)) }
            #expect(throws: Never.self) { try tile.find(text: "\(count)") }
        }
    }

    @Test func listsEveryShownListWithItsOpenCount() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try column(h, Box(.smart(.today)))
        for (id, name, count) in [("inbox", "Inbox", 3), ("work", "Work", 2), ("ro", "Shared", 1)] {
            let row = try sut.find(viewWithAccessibilityIdentifier: "todos.list.\(id)")
            #expect(throws: Never.self) { try row.find(text: name) }
            #expect(throws: Never.self) { try row.find(text: "\(count)") }
        }
    }

    @Test func aHiddenListHasNoRow() async throws {
        let h = await EngineHarness.pageFixture()
        h.engine.setTodoListShown("work", false)
        await h.engine.refreshTodosNow()
        let sut = try column(h, Box(.smart(.today)))
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.list.work")) == nil)
    }

    @Test func tapOnATileSelectsIt() async throws {
        let h = await EngineHarness.pageFixture()
        let box = Box(TodoSelection.smart(.today))
        let sut = try column(h, box)
        try sut.find(viewWithAccessibilityIdentifier: "todos.tile.completed").find(ViewType.Button.self, relation: .parent).tap()
        #expect(box.value == .smart(.completed))
    }

    @Test func tapOnAListRowSelectsIt() async throws {
        let h = await EngineHarness.pageFixture()
        let box = Box(TodoSelection.smart(.today))
        let sut = try column(h, box)
        try sut.find(viewWithAccessibilityIdentifier: "todos.list.work").find(ViewType.Button.self, relation: .parent).tap()
        #expect(box.value == .list("work"))
    }

    @Test func hasANewListButton() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try column(h, Box(.smart(.today)))
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.list.new") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todoNewList) }
    }
}

@MainActor
@Suite("Todos items column")
struct TodoItemsColumnTests {
    private func column(_ h: EngineHarness, _ sel: TodoSelection, shown: Bool = false) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoItemsColumn(selection: sel, showCompleted: shown), h).inspect()
    }

    private func rowIDs(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(TodoRow.self).compactMap { try? $0.actualView().todo.id }
    }

    @Test func showsTheTitleAndTheRowsInOrder() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try column(h, .smart(.today))
        #expect(throws: Never.self) { try sut.find(text: "Today") }
        #expect(rowIDs(sut) == ["f", "a", "b"])
    }

    @Test func aListPageHidesDoneTodosBehindTheToggle() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try column(h, .list("inbox"))
        #expect(rowIDs(sut) == ["f", "a", "c"])
        #expect(throws: Never.self) { try sut.find(text: "1 Completed · Show") }
    }

    @Test func shownCompletedListsTheDoneRowsAfterTheOpenOnes() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try column(h, .list("inbox"), shown: true)
        #expect(rowIDs(sut) == ["f", "a", "c", "g"])
    }

    @Test func noToggleWhenNothingIsDone() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try column(h, .list("ro"))
        #expect(Find.lacks(sut, text: Copywriter.todoCompletedToggle(0)))
        #expect(Find.lacks(sut, text: "1 Completed · Show"))
    }

    @Test func theCompletedTileListsDoneTodos() async throws {
        let h = await EngineHarness.pageFixture()
        #expect(try rowIDs(column(h, .smart(.completed))) == ["g", "h"])
    }

    @Test func anEmptyListShowsTheEmptyText() async throws {
        let h = await EngineHarness.todosReady()
        let sut = try column(h, .list("inbox"))
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todoEmptyList) }
    }

    @Test func theAddFieldShowsOnAnEditableListAndNotOnAReadOnlyOne() async throws {
        let h = await EngineHarness.pageFixture()
        #expect(throws: Never.self) { try column(h, .list("inbox")).find(TodoAddField.self) }
        #expect((try? column(h, .list("ro")).find(TodoAddField.self)) == nil)
        #expect((try? column(h, .smart(.completed)).find(TodoAddField.self)) == nil)
    }

    @Test func aReadOnlyListShowsItsRowsAsReadOnly() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try column(h, .list("ro"))
        #expect(try !sut.find(TodoRow.self).actualView().canEdit)
    }
}
