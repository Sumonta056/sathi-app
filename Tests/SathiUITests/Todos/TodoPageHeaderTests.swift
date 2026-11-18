import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo page header")
struct TodoPageHeaderTests {
    private func header(_ h: EngineHarness, _ sel: TodoSelection) throws -> InspectableView<ViewType.HStack> {
        try hosted(TodoItemsColumn(selection: sel), h).inspect().find(viewWithAccessibilityIdentifier: "todos.header").hStack()
    }

    @Test func theAllHeaderShowsTheTitleTheOpenCountAndTheListCount() async throws {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.smart(.all))
        let sut = try header(h, .smart(.all))
        #expect(throws: Never.self) { try sut.find(text: page.title) }
        let count = Copywriter.todoPageCount(open: page.open.count, lists: page.sections.count)
        #expect(count == "6 open · 3 lists")
        #expect(throws: Never.self) { try sut.find(text: count) }
        if !page.completed.isEmpty {
            #expect(throws: Never.self) { try sut.find(text: Copywriter.todoCompletedToggle(page.completed.count)) }
        }
    }

    @Test func aListHeaderShowsTheOpenCountWithoutLists() async throws {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.list("inbox"))
        let sut = try header(h, .list("inbox"))
        #expect(throws: Never.self) { try sut.find(text: page.title) }
        #expect(throws: Never.self) { try sut.find(text: "3 open") }
        #expect(Find.lacks(sut, text: "3"))
    }

    @Test func theCompletedToggleSitsInTheHeader() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try header(h, .list("inbox"))
        #expect(throws: Never.self) { try Find.button(sut, holding: Copywriter.todoCompletedToggle(1)) }
    }

    @Test func noToggleInTheHeaderWhenNothingIsDone() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try header(h, .list("ro"))
        #expect(throws: Never.self) { try sut.find(text: "1 open") }
        #expect(Find.lacks(sut, text: Copywriter.todoCompletedToggle(0)))
    }
}
