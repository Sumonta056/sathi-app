import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Day summary card todos line")
struct DaySummaryTodosCardTests {
    private func harness(on: Bool = true, access: TodoAccess = .allowed) async -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 22)) { $0.prefs.todos.isOn = on }
        h.todos.access = access
        h.todos.listsValue = [makeTodoList("inbox")]
        h.todos.todosValue = [
            makeTodo("a", done: true, doneAt: day(2026, 3, 4, 9)),
            makeTodo("b", done: true, doneAt: day(2026, 3, 4, 12)),
            makeTodo("c", due: timedDue(23))
        ]
        h.engine.start()
        await h.engine.refreshTodosNow()
        return h
    }

    private func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try DaySummaryCard().environmentObject(h.engine).inspect()
    }

    @Test func showsTheTodosLine() async throws {
        let sut = try await card(harness())
        #expect(MenuFind.texts(sut).contains("To-dos: 2 done · 1 left for today"))
        #expect(MenuFind.texts(sut).contains(Copywriter.todoDaySummaryLine(done: 2, left: 1)))
    }

    @Test func hidesTheLineWhenTodosAreOff() async throws {
        let sut = try await card(harness(on: false))
        #expect(!MenuFind.hasText(sut, containing: "To-dos:"))
    }

    @Test func hidesTheLineWithoutAccess() async throws {
        let sut = try await card(harness(access: .denied))
        #expect(!MenuFind.hasText(sut, containing: "To-dos:"))
    }

    @Test func theFourBuddyRowsStayAndTheTitleIsUnchanged() async throws {
        let sut = try await card(harness())
        for name in ["FOTA · WATER", "BOI · READING", "SHANTI · MEDITATION", "SHOKTI · GYM"] {
            #expect(throws: Never.self) { try sut.find(text: name) }
        }
        #expect(throws: Never.self) { try sut.find(text: "Good night") }
    }
}
