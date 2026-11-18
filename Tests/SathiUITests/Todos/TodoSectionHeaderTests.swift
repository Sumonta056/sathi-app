import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo section header")
struct TodoSectionHeaderTests {
    @Test func showsTheDotTheNameTheCountAndTheLine() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoSectionHeader(list: makeTodoList("work", "Work"), count: 4), h).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.section.dot.work") }
        #expect(throws: Never.self) { try sut.find(text: "Work") }
        let count = try sut.find(viewWithAccessibilityIdentifier: "todos.section.count.work")
        #expect(throws: Never.self) { try count.find(text: "4") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.section.rule.work") }
    }

    @Test func theAllPageShowsEachSectionsOpenCount() async throws {
        let h = await EngineHarness.pageFixture()
        let sections = h.engine.todoPage(.smart(.all)).sections
        #expect(sections.map(\.list.id) == ["inbox", "work", "ro"])
        let sut = try hosted(TodoItemsColumn(selection: .smart(.all)), h).inspect()
        for section in sections {
            let count = try sut.find(viewWithAccessibilityIdentifier: "todos.section.count." + section.list.id)
            #expect(throws: Never.self) { try count.find(text: "\(section.todos.count)") }
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.section.rule." + section.list.id) }
        }
    }

    @Test func theFixtureSectionCountsMatchTheOpenTodos() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoItemsColumn(selection: .smart(.all)), h).inspect()
        for (id, count) in [("inbox", 3), ("work", 2), ("ro", 1)] {
            let view = try sut.find(viewWithAccessibilityIdentifier: "todos.section.count." + id)
            #expect(throws: Never.self) { try view.find(text: "\(count)") }
        }
    }
}
