import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick due today card")
struct QuickDueTodayCardTests {
    private func harness(_ items: [Todo], on: Bool = true, access: TodoAccess = .allowed) async -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { $0.prefs.todos.isOn = on }
        h.todos.access = access
        h.todos.listsValue = [makeTodoList("inbox")]
        h.todos.todosValue = items
        h.engine.start()
        await h.engine.refreshTodosNow()
        return h
    }

    private func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try QuickDueTodayCard().environmentObject(h.engine).environmentObject(TodoFinishing.idle()).inspect()
    }

    private func has(_ h: EngineHarness) -> Bool {
        (try? card(h).find(viewWithAccessibilityIdentifier: "quick.todos")) != nil
    }

    private let four = [
        makeTodo("a", "Alpha", due: timedDue(9)),
        makeTodo("b", "Bravo", due: timedDue(11)),
        makeTodo("c", "Charlie", due: dateOnlyDue()),
        makeTodo("d", "Delta", due: timedDue(15)),
        makeTodo("e", "Echo"),
        makeTodo("f", "Foxtrot", due: dateOnlyDue(on: 5))
    ]

    @Test func showsTheTitleTheCountAndTheFirstThree() async throws {
        let h = await harness(four)
        let sut = try card(h)
        #expect(MenuFind.texts(sut).contains(Copywriter.todoDueToday))
        #expect(MenuFind.texts(sut).contains(Copywriter.todoQuickCount(4)))
        for id in ["a", "b", "c"] {
            #expect(Prompt.has(sut, "quick.todo.\(id)"))
        }
        #expect(!Prompt.has(sut, "quick.todo.d"))
        #expect(MenuFind.texts(sut).contains("Alpha"))
        #expect(!MenuFind.texts(sut).contains("Delta"))
    }

    @Test func overdueTodosShowTheOverdueCountAndAreMarked() async throws {
        let h = await harness(four)
        let sut = try card(h)
        #expect(MenuFind.texts(sut).contains(Copywriter.todoQuickOverdue(1)))
        #expect(Prompt.has(sut, "quick.todo.late.a"))
        #expect(!Prompt.has(sut, "quick.todo.late.b"))
        #expect(!Prompt.has(sut, "quick.todo.late.c"))
    }

    @Test func noOverdueTextWhenNothingIsOverdue() async throws {
        let h = await harness([makeTodo("b", "Bravo", due: timedDue(11))])
        let sut = try card(h)
        #expect(!MenuFind.texts(sut).contains(Copywriter.todoQuickOverdue(0)))
        #expect(!MenuFind.hasText(sut, containing: "overdue"))
    }

    @Test func theMenuPanelProvidesItsOwnFinishingHost() async throws {
        let h = await harness(four)
        let sut = try MenuPanel().environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "quick.todo.b").button() }
    }

    @Test func aTickWritesNothingAtOnce() async throws {
        let h = await harness(four)
        try card(h).find(viewWithAccessibilityIdentifier: "quick.todo.b").button().tap()
        await Task.yield()
        #expect(h.todos.calls.isEmpty)
    }

    @Test func aTickStartsTheFinishAndTheWriteLandsAfterTheFold() async throws {
        let h = await harness(four)
        let gate = TodoFinishingGate()
        let finishing = TodoFinishing(wait: { [gate] in await gate.wait($0) }, write: { [h] in h.engine.doneTodo($0) })
        let sut = try QuickDueTodayCard().environmentObject(h.engine).environmentObject(finishing).inspect()
        try sut.find(viewWithAccessibilityIdentifier: "quick.todo.b").button().tap()
        await waitUntil { gate.waiting == 1 }
        #expect(finishing.phase("b") == .checked)
        #expect(h.todos.calls.isEmpty)
        gate.release()
        await waitUntil { finishing.phase("b") == .leaving && gate.waiting == 1 }
        #expect(h.todos.calls.isEmpty)
        gate.release()
        await waitUntil { !h.todos.calls.isEmpty }
        #expect(h.todos.calls == [.doneSet("b", true)])
    }

    @Test func noCardWhenNothingIsDueToday() async {
        let h = await harness([makeTodo("e", "Echo"), makeTodo("f", "Foxtrot", due: dateOnlyDue(on: 5))])
        #expect(!has(h))
    }

    @Test func noCardWhenTodosAreOff() async {
        let h = await harness(four, on: false)
        #expect(!has(h))
    }

    @Test func noCardWithoutAccess() async {
        let h = await harness(four, access: .denied)
        #expect(!has(h))
    }

    @Test func aDoneTodoIsNotDue() async {
        let done = makeTodo("a", "Alpha", due: timedDue(9), done: true, doneAt: day(2026, 3, 4, 9, 5))
        let h = await harness([done])
        #expect(!has(h))
    }

    @Test func theMenuPanelShowsTheCardOnlyWhenSomethingIsDue() async throws {
        let h = await harness(four)
        let panel = try hosted(MenuPanel(), h).inspect()
        #expect(!panel.findAll(QuickDueTodayCard.self).isEmpty)
        let none = await harness([])
        let empty = try hosted(MenuPanel(), none).inspect()
        #expect(Prompt.has(empty, "quick.todos") == false)
    }
}
