import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page to-do lists")
struct EngineCalendarPageTodoListsTests {
    private let lists = [makeTodoList("inbox", "Inbox"), makeTodoList("errands", "Errands")]

    private func loaded(on: Bool = true) async -> EngineHarness {
        let h = EngineHarness.withCalendarTodos(lists: lists, todos: [], todosOn: on)
        await h.loadTodos()
        return h
    }

    @Test func todoListsAreAGroupInShownCalendars() async {
        let h = await loaded()
        let groups = h.engine.shownCalendarGroups()
        let group = groups.last
        #expect(group?.account == "To-do lists")
        #expect(group?.calendars.map(\.choice.id) == ["inbox", "errands"])
        #expect(group?.calendars.map(\.choice.title) == ["Inbox", "Errands"])
        #expect(group?.calendars.allSatisfy(\.isShown) == true)
        #expect(group?.calendars.first?.choice.colorHex == 0xFF3B30)
    }

    @Test func hidingATodoListUsesHiddenCalendarIDs() async {
        let h = await loaded()
        h.engine.setCalendarShown("errands", false)
        #expect(h.engine.data.prefs.calendarPage.hiddenCalendarIDs == ["errands"])
        let group = h.engine.shownCalendarGroups().last
        #expect(group?.calendars.map(\.isShown) == [true, false])
    }

    @Test func noTodoGroupWhenTodosAreOff() async {
        let h = await loaded(on: false)
        #expect(!h.engine.shownCalendarGroups().contains { $0.account == "To-do lists" })
    }

    @Test func hiddenTodoListsFromSettingsAreNotInTheGroup() async {
        let h = EngineHarness.withCalendarTodos(lists: lists, todos: []) { $0.prefs.todos.hiddenListIDs = ["errands"] }
        await h.loadTodos()
        let group = h.engine.shownCalendarGroups().last
        #expect(group?.calendars.map(\.choice.id) == ["inbox"])
    }
}
