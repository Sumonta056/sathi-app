import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Activity prompt todo carry")
struct ActivityPromptTodoCarryTests {
    @Test func aJoiningTodoKeepsTheTypedTextAndThePick() {
        let a = makeTodo("a", "Write report", due: TodoDue(date: Prompt.now, hasTime: true))
        let b = makeTodo("b", "Call Sam", due: TodoDue(date: Prompt.now, hasTime: true))
        let c = makeTodo("c", "Pay rent", due: TodoDue(date: Prompt.now, hasTime: true))
        let old = ActivityPromptModel(Prompt.state(.todoDue) { $0.todos = [a, b] })
        old.pick(todo: PromptTodo(id: "b", title: "Call Sam", detail: ""))
        old.draft.text = "Call Sam about rent"
        let joined = ActivityPromptModel(Prompt.state(.todoDue) { $0.todos = [a, b, c] })
        joined.carry(from: old)
        #expect(joined.draft.text == "Call Sam about rent")
        #expect(joined.todoID == "b")
    }
}
