import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoPage")
struct EngineTodoPageTests {
    private func ids(_ items: [Todo]) -> [String] { items.map(\.id) }

    @Test func todayListsDueTodayAndOverdueInOrder() async {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.smart(.today))
        #expect(page.title == "Today")
        #expect(ids(page.open) == ["f", "a", "b"])
        #expect(page.completed.isEmpty)
    }

    @Test func scheduledListsEveryOpenTodoWithADate() async {
        let h = await EngineHarness.pageFixture()
        #expect(ids(h.engine.todoPage(.smart(.scheduled)).open) == ["f", "a", "b", "d"])
    }

    @Test func allListsEveryOpenTodoDatedFirstThenNewestNoDate() async {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.smart(.all))
        #expect(page.title == "All")
        #expect(ids(page.open) == ["f", "a", "b", "d", "e", "c"])
    }

    @Test func completedListsDoneTodosNewestFirst() async {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.smart(.completed))
        #expect(page.title == "Completed")
        #expect(ids(page.open) == ["g", "h"])
    }

    @Test func aListPageShowsItsOpenTodosAndKeepsDoneOnesApart() async {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.list("inbox"))
        #expect(page.title == "Inbox")
        #expect(ids(page.open) == ["f", "a", "c"])
        #expect(ids(page.completed) == ["g"])
        #expect(page.canAdd)
        #expect(page.targetListID == "inbox")
    }

    @Test func aReadOnlyListCannotAdd() async {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.list("ro"))
        #expect(ids(page.open) == ["e"])
        #expect(!page.canAdd)
    }

    @Test func anUnknownListIsEmptyAndCannotAdd() async {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.list("zzz"))
        #expect(page.open.isEmpty)
        #expect(page.completed.isEmpty)
        #expect(!page.canAdd)
    }

    @Test func smartListsAddToTheFirstEditableListExceptCompleted() async {
        let h = await EngineHarness.pageFixture()
        for smart in [TodoSmartList.today, .scheduled, .all] {
            let page = h.engine.todoPage(.smart(smart))
            #expect(page.canAdd)
            #expect(page.targetListID == "inbox")
        }
        #expect(!h.engine.todoPage(.smart(.completed)).canAdd)
    }

    @Test func countsFollowTheRules() async {
        let h = await EngineHarness.pageFixture()
        #expect(h.engine.todoCount(.smart(.today)) == 3)
        #expect(h.engine.todoCount(.smart(.scheduled)) == 4)
        #expect(h.engine.todoCount(.smart(.all)) == 6)
        #expect(h.engine.todoCount(.smart(.completed)) == 2)
        #expect(h.engine.todoCount(.list("inbox")) == 3)
        #expect(h.engine.todoCount(.list("work")) == 2)
    }

    @Test func aHiddenListIsNotInAnySmartListOrAsASelection() async {
        let h = await EngineHarness.pageFixture()
        h.engine.setTodoListShown("work", false)
        await h.engine.refreshTodosNow()
        #expect(ids(h.engine.todoPage(.smart(.all)).open) == ["f", "a", "e", "c"])
        #expect(h.engine.todoPage(.list("work")).open.isEmpty)
    }

    @Test func accessDeniedGivesAnEmptyPage() async {
        let h = await EngineHarness.todosReady(items: [makeTodo("a")], access: .denied)
        let page = h.engine.todoPage(.smart(.all))
        #expect(page.open.isEmpty)
        #expect(!page.canAdd)
    }

    @Test func allListsIncludesHiddenOnesForSettings() async {
        let h = await EngineHarness.pageFixture()
        h.engine.setTodoListShown("work", false)
        #expect(h.engine.todoAllLists().map(\.id) == ["inbox", "work", "ro"])
    }

    @Test func settingAListShownAndHiddenEditsThePrefs() async {
        let h = await EngineHarness.pageFixture()
        h.engine.setTodoListShown("work", false)
        #expect(h.engine.data.prefs.todos.hiddenListIDs == ["work"])
        h.engine.setTodoListShown("work", true)
        #expect(h.engine.data.prefs.todos.hiddenListIDs.isEmpty)
    }

    @Test func allListsIsEmptyWhenOffOrWithoutAccess() async {
        let off = await EngineHarness.todosReady(items: [], on: false)
        #expect(off.engine.todoAllLists().isEmpty)
        let denied = await EngineHarness.todosReady(items: [], access: .denied)
        #expect(denied.engine.todoAllLists().isEmpty)
    }
}
