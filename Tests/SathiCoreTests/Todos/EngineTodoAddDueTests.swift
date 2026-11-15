import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoAddDue")
struct EngineTodoAddDueTests {
    private let today = TodoDue(date: day(2026, 3, 4), hasTime: false)

    @Test(arguments: [TodoSmartList.today, .scheduled])
    func todayAndScheduledAddWithADueOfToday(_ smart: TodoSmartList) async {
        let h = await EngineHarness.pageFixture()
        #expect(h.engine.todoPage(.smart(smart)).defaultDue == today)
    }

    @Test func allAndListPagesAddWithoutADue() async {
        let h = await EngineHarness.pageFixture()
        #expect(h.engine.todoPage(.smart(.all)).defaultDue == nil)
        #expect(h.engine.todoPage(.list("inbox")).defaultDue == nil)
        #expect(h.engine.todoPage(.smart(.completed)).defaultDue == nil)
    }

    @Test func anAddOnTodayWritesADueOfTodayAndStaysOnToday() async {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.smart(.today))
        let target = page.targetListID ?? ""
        h.todos.todosValue.append(makeTodo("n", "New", list: target, due: page.defaultDue))
        _ = await h.engine.addTodo(TodoDraft(listID: target, title: "New", notes: "", due: page.defaultDue))
        #expect(h.todos.calls == [.added(TodoDraft(listID: "inbox", title: "New", notes: "", due: today))])
        #expect(h.engine.todoPage(.smart(.today)).open.contains { $0.id == "n" })
    }

    @Test func aSaveWhoseMoveFailsIsReportedAsPartlySaved() async throws {
        let h = await EngineHarness.pageFixture()
        h.todos.moveResult = .failed
        let todo = try #require(h.engine.todoSnapshot.open.first { $0.id == "a" })
        var form = TodoEditForm(todo: todo, calendar: .current)
        form.title = "Alpha 2"
        form.listID = "work"
        let r = await h.engine.saveTodo(todo, form)
        #expect(r == .partlySaved)
        #expect(h.todos.calls.count == 2)
    }

    @Test func aFullSaveIsSavedAndAFailedUpdateDoesNotMove() async throws {
        let h = await EngineHarness.pageFixture()
        let todo = try #require(h.engine.todoSnapshot.open.first { $0.id == "a" })
        var form = TodoEditForm(todo: todo, calendar: .current)
        form.listID = "work"
        #expect(await h.engine.saveTodo(todo, form) == .saved)
        h.todos.nextResult = .failed
        #expect(await h.engine.saveTodo(todo, form) == .failed)
        #expect(h.todos.calls.filter { if case .moved = $0 { true } else { false } }.count == 1)
    }

    @Test func dueFieldsBuildTheDue() {
        let cal = Calendar.current
        #expect(TodoDue.make(hasDate: false, date: day(2026, 3, 5, 7), minutes: 60, calendar: cal) == nil)
        #expect(TodoDue.make(hasDate: true, date: day(2026, 3, 5, 7), minutes: nil, calendar: cal)
            == TodoDue(date: day(2026, 3, 5), hasTime: false))
        #expect(TodoDue.make(hasDate: true, date: day(2026, 3, 5, 7), minutes: 9 * 60 + 5, calendar: cal)
            == TodoDue(date: day(2026, 3, 5, 9, 5), hasTime: true))
        #expect(TodoDue(date: day(2026, 3, 5, 9, 5), hasTime: true).minutes(calendar: cal) == 9 * 60 + 5)
        #expect(TodoDue(date: day(2026, 3, 5), hasTime: false).minutes(calendar: cal) == nil)
    }

    @Test func theAddTitleClearsOnlyAfterADoneAdd() {
        #expect(TodoAddRule.titleAfterAdd(current: "Milk", sent: "Milk", result: .done(id: "x")) == "")
        #expect(TodoAddRule.titleAfterAdd(current: "Milk", sent: "Milk", result: .failed) == "Milk")
        #expect(TodoAddRule.titleAfterAdd(current: "Milk", sent: "Milk", result: .missing) == "Milk")
        #expect(TodoAddRule.titleAfterAdd(current: "Milk 2", sent: "Milk", result: .done(id: "x")) == "Milk 2")
    }
}
