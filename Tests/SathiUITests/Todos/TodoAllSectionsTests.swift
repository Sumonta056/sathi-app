import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo All sections")
struct TodoAllSectionsTests {
    @Test func allShowsAHeaderForEachListWithOpenTodos() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: .smart(.all)), h).inspect()
        for id in ["inbox", "work", "ro"] {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.section." + id) }
        }
        let header = try sut.find(viewWithAccessibilityIdentifier: "todos.section.work")
        #expect(throws: Never.self) { try header.find(text: "Work") }
        #expect(throws: Never.self) { try header.find(viewWithAccessibilityIdentifier: "todos.section.dot.work") }
    }

    @Test func allStillShowsEveryOpenTodo() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: .smart(.all)), h).inspect()
        for title in ["Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot"] {
            #expect(throws: Never.self) { try sut.find(text: title) }
        }
    }

    @Test(arguments: [TodoSelection.smart(.today), .smart(.scheduled), .list("inbox")])
    func otherPagesShowNoSectionHeaders(_ selection: TodoSelection) async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: selection), h).inspect()
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.section.inbox")) == nil)
    }
}
