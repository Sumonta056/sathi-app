import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
final class TodoPromptCalls {
    var started: [(String, ActivityDraft, Date?)] = []
    var done: [String] = []
    var marked: [Bool] = []
    var closes = 0
    var startWorks = true
}

@MainActor
@Suite("Activity prompt todo")
struct ActivityPromptTodoTests {
    private let write = makeTodo("a", "Write report", due: TodoDue(date: Prompt.now, hasTime: true))
    private let call = makeTodo("b", "Call Sam", due: TodoDue(date: Prompt.now, hasTime: true))

    private func state(
        _ calls: TodoPromptCalls,
        todos: [Todo]? = nil,
        running: Bool = false
    ) -> TrackerPromptState {
        Prompt.state(.todoDue) { s in
            s.todos = todos ?? [write]
            if running { s.running = Reasons.running() }
            s.actions.startTodo = { id, draft, at in
                calls.started.append((id, draft, at))
                return calls.startWorks
            }
            s.actions.doneTodo = { calls.done.append($0) }
            s.actions.markTodoDone = { calls.marked.append($0) }
            s.actions.close = { calls.closes += 1 }
        }
    }

    @Test func idleShowsTheTagTheTitleAndTheThreeButtons() throws {
        let sut = try Prompt.view(state(TodoPromptCalls()))
        #expect(Prompt.hasText(sut, "TO-DO DUE"))
        #expect(Prompt.hasText(sut, "Write report"))
        #expect(try Prompt.buttonText(sut, "tracker.later") == ["Later"])
        #expect(try Prompt.buttonText(sut, "prompt.todoDone") == ["Done"])
        #expect(try Prompt.buttonText(sut, "tracker.start") == ["Start it"])
        #expect(!Prompt.has(sut, "prompt.keep"))
        #expect(!Prompt.has(sut, "tracker.skip"))
    }

    @Test func runningShowsKeepAndSwitchToIt() throws {
        let sut = try Prompt.view(state(TodoPromptCalls(), running: true))
        #expect(try Prompt.buttonText(sut, "tracker.later") == ["Later"])
        #expect(try Prompt.buttonText(sut, "prompt.todoDone") == ["Done"])
        #expect(try Prompt.buttonText(sut, "prompt.keep") == ["Keep Code review"])
        #expect(try Prompt.buttonText(sut, "tracker.start") == ["Switch to it"])
    }

    @Test func laterClosesAndChangesNothing() throws {
        let calls = TodoPromptCalls()
        try Prompt.tap(Prompt.view(state(calls, running: true)), "tracker.later")
        #expect(calls.closes == 1)
        #expect(calls.done.isEmpty)
        #expect(calls.started.isEmpty)
    }

    @Test func keepClosesAndChangesNothing() throws {
        let calls = TodoPromptCalls()
        try Prompt.tap(Prompt.view(state(calls, running: true)), "prompt.keep")
        #expect(calls.closes == 1)
        #expect(calls.done.isEmpty)
        #expect(calls.started.isEmpty)
    }

    @Test func doneMarksTheShownTodo() throws {
        let calls = TodoPromptCalls()
        try Prompt.tap(Prompt.view(state(calls)), "prompt.todoDone")
        #expect(calls.done == ["a"])
        #expect(calls.started.isEmpty)
    }

    @Test func startItStartsTheTodoWithItsTitle() throws {
        let calls = TodoPromptCalls()
        try Prompt.tap(Prompt.view(state(calls)), "tracker.start")
        #expect(calls.started.count == 1)
        #expect(calls.started.first?.0 == "a")
        #expect(calls.started.first?.1.text == "Write report")
        #expect(calls.started.first?.2 == nil)
    }

    @Test func switchToItStartsTheTodoToo() throws {
        let calls = TodoPromptCalls()
        try Prompt.tap(Prompt.view(state(calls, running: true)), "tracker.start")
        #expect(calls.started.first?.0 == "a")
    }

    @Test func twoTodosShowTwoRowsAndTheFirstIsPicked() throws {
        let calls = TodoPromptCalls()
        let s = state(calls, todos: [write, call])
        let model = ActivityPromptModel(s)
        let sut = try Prompt.view(s, model: model)
        #expect(Prompt.has(sut, "prompt.todo.a"))
        #expect(Prompt.has(sut, "prompt.todo.b"))
        #expect(model.todoID == "a")
    }

    @Test func tappingARowPicksThatTodoForDoneAndStart() throws {
        let calls = TodoPromptCalls()
        let s = state(calls, todos: [write, call])
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "prompt.todo.b")
        #expect(model.todoID == "b")
        try Prompt.tap(Prompt.view(s, model: model), "prompt.todoDone")
        #expect(calls.done == ["b"])
    }

    @Test func startUsesThePickedTodo() throws {
        let calls = TodoPromptCalls()
        let s = state(calls, todos: [write, call])
        let model = ActivityPromptModel(s)
        model.todoID = "b"
        model.draft.text = "Call Sam"
        try Prompt.tap(Prompt.view(s, model: model), "tracker.start")
        #expect(calls.started.first?.0 == "b")
        #expect(calls.started.first?.1.text == "Call Sam")
    }

    @Test func otherReasonsShowNoTodoControls() throws {
        let sut = try Prompt.view(Reasons.withKeep(.stillOnIt))
        #expect(!Prompt.has(sut, "prompt.todoDone"))
        #expect(!Prompt.has(sut, "tracker.later"))
        #expect(!Prompt.has(sut, "prompt.todoDoneCard"))
    }

    @Test func theEndsScreenShowsTheMarkDoneCard() throws {
        let calls = TodoPromptCalls()
        var s = Reasons.withKeep(.stillOnIt)
        s.todoDoneAsk = write
        s.actions.markTodoDone = { calls.marked.append($0) }
        let sut = try Prompt.view(s)
        #expect(Prompt.has(sut, "prompt.todoDoneCard"))
        #expect(Prompt.hasText(sut, "Mark Write report done?"))
        #expect(try Prompt.buttonText(sut, "prompt.markDone") == ["Mark done"])
        #expect(try Prompt.buttonText(sut, "prompt.notYet") == ["Not yet"])
        try Prompt.tap(sut, "prompt.markDone")
        try Prompt.tap(sut, "prompt.notYet")
        #expect(calls.marked == [true, false])
    }

    @Test func noMarkDoneCardWithoutAnAsk() throws {
        let sut = try Prompt.view(Reasons.withKeep(.stillOnIt))
        #expect(!Prompt.has(sut, "prompt.todoDoneCard"))
        #expect(!Prompt.has(sut, "prompt.markDone"))
    }
}
