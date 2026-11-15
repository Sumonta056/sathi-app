@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Menu panel to-do refresh")
struct MenuPanelTodoRefreshTests {
    @Test func openingThePanelReadsTheTodosAgain() async throws {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { $0.prefs.todos.isOn = true }
        h.todos.listsValue = [makeTodoList("inbox")]
        h.engine.start()
        await h.engine.refreshTodosNow()
        let reads = h.todos.readRequests.count
        h.todos.todosValue = [makeTodo("a", "Alpha", due: timedDue(11))]
        h.todos.revision += 1
        try MenuPanel().environmentObject(h.engine).inspect().vStack().callOnAppear()
        await h.engine.todoRuntime.refreshTask?.value
        #expect(h.todos.readRequests.count == reads + 1)
        #expect(h.engine.quickTodos?.count == 1)
    }
}
