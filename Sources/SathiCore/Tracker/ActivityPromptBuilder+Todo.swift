import Foundation

extension ActivityPromptBuilder {
    static func todo(_ s: TrackerPromptState) -> ActivityPromptScreen {
        let r = s.running
        let first = s.todos.first
        let list = first.flatMap { s.todoListNames[$0.listID] }
        var p = ActivityPromptScreen(
            reason: .todo, tag: Copywriter.todoDueTag,
            timeText: first?.due.map { Copywriter.trackerClock($0.date, calendar: s.calendar) } ?? "",
            title: first?.title ?? s.draft.text,
            message: Copywriter.todoDueMessage(list: list, running: r?.text),
            startLabel: r == nil ? Copywriter.todoStartIt : Copywriter.todoSwitchToIt, skip: .later
        )
        p.keep = r.map { .keep($0.text) }
        p.card = r.map { runningCard($0, now: s.now, calendar: s.calendar) }
        p.doneLabel = Copywriter.todoDone
        p.todos = s.todos.prefix(Limits.promptTodosShown).map { promptTodo($0, s) }
        return p
    }

    static func markDone(_ s: TrackerPromptState) -> PromptMarkDone? {
        s.todoDoneAsk.map { PromptMarkDone(todoID: $0.id, question: Copywriter.todoMarkDoneTitle($0.title)) }
    }

    private static func promptTodo(_ t: Todo, _ s: TrackerPromptState) -> PromptTodo {
        let list = s.todoListNames[t.listID]
        let detail = t.due.map { Copywriter.todoDueDetail(list: list, due: $0.date, calendar: s.calendar) } ?? (list ?? "")
        return PromptTodo(id: t.id, title: t.title, detail: detail)
    }
}
