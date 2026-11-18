import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo row")
struct TodoRowTests {
    private func row(
        _ h: EngineHarness,
        _ todo: Todo,
        canEdit: Bool = true,
        onSelect: @escaping () -> Void = {}
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoRow(todo: todo, canEdit: canEdit, onSelect: onSelect), h).inspect()
    }

    @Test func showsTheTitle() async throws {
        let h = await EngineHarness.pageFixture()
        #expect(throws: Never.self) { try row(h, makeTodo("a", "Buy milk")).find(text: "Buy milk") }
    }

    @Test func showsTheDueText() async throws {
        let h = await EngineHarness.pageFixture()
        let todo = makeTodo("a", due: TodoDue(date: day(2026, 3, 4, 14, 30), hasTime: true))
        let expected = try Copywriter.todoDueText(#require(todo.due), now: day(2026, 3, 4, 10), calendar: .current)
        let sut = try row(h, todo)
        let due = try sut.find(viewWithAccessibilityIdentifier: "todos.row.due.a")
        #expect(throws: Never.self) { try due.find(text: expected) }
    }

    @Test func noDueShowsNoDueText() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, makeTodo("a"))
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.row.due.a")) == nil)
    }

    @Test func repeatingTodoShowsTheRepeatsLabel() async throws {
        let h = await EngineHarness.pageFixture()
        var todo = makeTodo("a")
        todo.repeats = true
        #expect(throws: Never.self) { try row(h, todo).find(text: Copywriter.todoRepeats) }
        let plain = try row(h, makeTodo("b"))
        #expect(Find.lacks(plain, text: Copywriter.todoRepeats))
    }

    @Test func tickMarksTheTodoDone() async throws {
        let h = await EngineHarness.pageFixture()
        try Find.button(row(h, makeTodo("a")), label: Copywriter.todoMarkDone).tap()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.doneSet("a", true)])
    }

    @Test func tickOnADoneTodoMarksItNotDone() async throws {
        let h = await EngineHarness.pageFixture()
        let done = makeTodo("g", done: true, doneAt: day(2026, 3, 3))
        try Find.button(row(h, done), label: Copywriter.todoMarkNotDone).tap()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.doneSet("g", false)])
    }

    @Test func aReadOnlyRowHasADisabledTick() async throws {
        let h = await EngineHarness.pageFixture()
        let tick = try Find.button(row(h, makeTodo("e", list: "ro"), canEdit: false), label: Copywriter.todoMarkDone)
        #expect(tick.isDisabled())
        try? tick.tap()
        #expect(h.todos.calls.isEmpty)
    }

    @Test func tapOnTheRowCallsOnSelectWithoutAButton() async throws {
        let h = await EngineHarness.pageFixture()
        var selected = 0
        let sut = try row(h, makeTodo("a"), onSelect: { selected += 1 })
        let body = try sut.find(viewWithAccessibilityIdentifier: "todos.row.a")
        #expect((try? body.find(ViewType.Button.self, relation: .parent)) == nil)
        try body.callOnTapGesture()
        #expect(selected == 1)
    }

    @Test func doneRowIsMarkedByItsAccessibilityValue() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try row(h, makeTodo("g", done: true, doneAt: day(2026, 3, 3)))
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: Copywriter.todoMarkNotDone) }
    }
}
