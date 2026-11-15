import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Activity prompt todo screens")
struct ActivityPromptTodoBuilderTests {
    private typealias Fix = PromptFixture

    private let second = makeTodo("b", "Call Sam", due: TodoDue(date: Fix.at(10, 30), hasTime: true))

    @Test func idleScreenOffersLaterDoneAndStartIt() {
        let s = Fix.screen(.todoDue)
        #expect(s.reason == .todo)
        #expect(s.tag == "TO-DO DUE")
        #expect(s.title == "Write report")
        #expect(s.startLabel == "Start it")
        #expect(s.skip == .later)
        #expect(s.doneLabel == "Done")
        #expect(s.keep == nil)
        #expect(s.card == nil)
    }

    @Test func runningScreenOffersKeepAndSwitchToIt() {
        let s = Fix.screen(.todoDue) { $0.running = Fix.running() }
        #expect(s.startLabel == "Switch to it")
        #expect(s.keep == .keep("Code review"))
        #expect(s.keep?.label == "Keep Code review")
        #expect(s.skip == .later)
        #expect(s.doneLabel == "Done")
        #expect(s.card?.text == "Code review")
    }

    @Test func theScreenShowsAtMostTheCappedNumberOfTodosSoThePaneNeverScrolls() {
        let more = (1 ... 7).map { makeTodo("x\($0)", "Task \($0)", due: TodoDue(date: Fix.at(10, 30), hasTime: true)) }
        let s = Fix.screen(.todoDue) { $0.todos.append(contentsOf: more) }
        #expect(Limits.promptTodosShown == 5)
        #expect(s.todos.map(\.id) == ["a", "x1", "x2", "x3", "x4"])
    }

    @Test func theScreenListsTheDueTodosInOrder() {
        let s = Fix.screen(.todoDue) { $0.todos.append(second) }
        #expect(s.todos.map(\.id) == ["a", "b"])
        #expect(s.todos.map(\.title) == ["Write report", "Call Sam"])
        #expect(s.todos.allSatisfy { $0.detail.contains(Fix.clock(Fix.at(10, 30))) })
    }

    @Test func theTimeTextShowsTheDueTime() {
        let s = Fix.screen(.todoDue)
        #expect(s.timeText == Fix.clock(Fix.at(10, 30)))
    }

    @Test func otherReasonsHaveNoTodoParts() {
        for kind in PromptKind.allCases where kind != .todoDue {
            let s = Fix.screen(kind)
            #expect(s.todos.isEmpty)
            #expect(s.doneLabel == nil)
            #expect(s.skip != .later)
        }
    }

    @Test func endsScreenShowsTheMarkDoneCard() {
        let todo = makeTodo("a", "Write report")
        let s = Fix.screen(.stillOnIt) { $0.todoDoneAsk = todo }
        #expect(s.markDone == PromptMarkDone(todoID: "a", question: "Mark Write report done?"))
        #expect(s.markDone?.question == Copywriter.todoMarkDoneTitle("Write report"))
    }

    @Test func endsScreenWithoutAnAskHasNoCard() {
        #expect(Fix.screen(.stillOnIt).markDone == nil)
    }

    @Test func theCopyForTheNewButtons() {
        #expect(Copywriter.todoDueTag == "TO-DO DUE")
        #expect(Copywriter.todoLater == "Later")
        #expect(Copywriter.todoDone == "Done")
        #expect(Copywriter.todoStartIt == "Start it")
        #expect(Copywriter.todoSwitchToIt == "Switch to it")
        #expect(Copywriter.todoMarkDone == "Mark done")
        #expect(Copywriter.todoNotYet == "Not yet")
    }
}
