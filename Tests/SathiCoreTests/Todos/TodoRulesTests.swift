import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoRules")
struct TodoRulesTests {
    private let z = FixedZone.berlin
    private var cal: Calendar { z.calendar }
    private var now: Date { z.date(2026, 3, 4, 10) }

    private func timed(_ d: Int, _ h: Int, _ m: Int = 0) -> TodoDue {
        TodoDue(date: z.date(2026, 3, d, h, m), hasTime: true)
    }

    private func dateOnly(_ d: Int) -> TodoDue {
        TodoDue(date: z.date(2026, 3, d), hasTime: false)
    }

    private func ids(_ items: [Todo]) -> [String] { items.map(\.id) }

    @Test func dueDatesComeFirstEarliestFirstThenNoDateNewestFirst() {
        let old = z.date(2026, 3, 1)
        let new = z.date(2026, 3, 3)
        let items = [
            makeTodo("noDateOld", due: nil, created: old),
            makeTodo("later", due: timed(5, 9)),
            makeTodo("noDateNew", due: nil, created: new),
            makeTodo("sooner", due: timed(4, 9))
        ]
        #expect(ids(TodoRules.sorted(items)) == ["sooner", "later", "noDateNew", "noDateOld"])
    }

    @Test func sameDueMomentKeepsTitleOrder() {
        let items = [
            makeTodo("1", "Beta", due: timed(4, 9)),
            makeTodo("2", "Alpha", due: timed(4, 9))
        ]
        #expect(ids(TodoRules.sorted(items)) == ["2", "1"])
    }

    @Test func sameCreatedTimeWithNoDateKeepsTitleOrder() {
        let t = z.date(2026, 3, 1)
        let items = [
            makeTodo("1", "Beta", created: t),
            makeTodo("2", "Alpha", created: t)
        ]
        #expect(ids(TodoRules.sorted(items)) == ["2", "1"])
    }

    @Test func dueTodayIncludesOverdueAndDateOnly() {
        #expect(TodoRules.isDueToday(makeTodo("a", due: dateOnly(4)), now: now, calendar: cal))
        #expect(TodoRules.isDueToday(makeTodo("b", due: timed(4, 23)), now: now, calendar: cal))
        #expect(TodoRules.isDueToday(makeTodo("c", due: timed(3, 8)), now: now, calendar: cal))
        #expect(TodoRules.isDueToday(makeTodo("d", due: dateOnly(1)), now: now, calendar: cal))
    }

    @Test func dueTodayExcludesTomorrowNoDateAndDone() {
        #expect(!TodoRules.isDueToday(makeTodo("a", due: timed(5, 0, 30)), now: now, calendar: cal))
        #expect(!TodoRules.isDueToday(makeTodo("b", due: dateOnly(5)), now: now, calendar: cal))
        #expect(!TodoRules.isDueToday(makeTodo("c"), now: now, calendar: cal))
        let done = makeTodo("d", due: dateOnly(4), done: true, doneAt: now)
        #expect(!TodoRules.isDueToday(done, now: now, calendar: cal))
    }

    @Test func aTimedToDoIsOverdueOnlyAfterItsMoment() {
        #expect(TodoRules.isOverdue(makeTodo("a", due: timed(4, 9, 59)), now: now, calendar: cal))
        #expect(!TodoRules.isOverdue(makeTodo("b", due: timed(4, 10)), now: now, calendar: cal))
        #expect(!TodoRules.isOverdue(makeTodo("c", due: timed(4, 10, 1)), now: now, calendar: cal))
    }

    @Test func aDateOnlyToDoIsOverdueFromTheNextDay() {
        #expect(!TodoRules.isOverdue(makeTodo("a", due: dateOnly(4)), now: now, calendar: cal))
        #expect(TodoRules.isOverdue(makeTodo("b", due: dateOnly(3)), now: now, calendar: cal))
        let lateToday = z.date(2026, 3, 4, 23, 59)
        #expect(!TodoRules.isOverdue(makeTodo("c", due: dateOnly(4)), now: lateToday, calendar: cal))
        let nextDay = z.date(2026, 3, 5, 0, 1)
        #expect(TodoRules.isOverdue(makeTodo("d", due: dateOnly(4)), now: nextDay, calendar: cal))
    }

    @Test func noDateAndDoneToDosAreNeverOverdue() {
        #expect(!TodoRules.isOverdue(makeTodo("a"), now: now, calendar: cal))
        let done = makeTodo("b", due: dateOnly(1), done: true, doneAt: now)
        #expect(!TodoRules.isOverdue(done, now: now, calendar: cal))
    }

    @Test func dueTodayListIsSortedAndOverdueCountIsCounted() {
        let items = [
            makeTodo("today", due: timed(4, 15)),
            makeTodo("overdue", due: timed(3, 9)),
            makeTodo("tomorrow", due: timed(5, 9)),
            makeTodo("dateOnly", due: dateOnly(4))
        ]
        #expect(ids(TodoRules.dueToday(items, now: now, calendar: cal)) == ["overdue", "dateOnly", "today"])
        #expect(TodoRules.overdueCount(items, now: now, calendar: cal) == 1)
    }

    @Test func quickPanelShowsTheFirstThreeInSortOrder() {
        let items = (1 ... 5).map { makeTodo("t\($0)", due: timed(4, 12 - $0)) }
        let shown = TodoRules.quickPanel(items, now: now, calendar: cal)
        #expect(ids(shown) == ["t5", "t4", "t3"])
        #expect(shown.count == Limits.todoQuickPanelMax)
    }

    @Test func quickPanelIsEmptyWhenNothingIsDue() {
        let items = [makeTodo("a", due: timed(6, 9)), makeTodo("b")]
        #expect(TodoRules.quickPanel(items, now: now, calendar: cal).isEmpty)
    }

    @Test func completedWindowStartsThirtyDaysBackAtDayStart() {
        #expect(TodoRules.completedSince(now: now, calendar: cal) == z.date(2026, 2, 3))
    }

    @Test func completedWindowKeepsDay30AndDropsDay31() {
        let day30 = z.date(2026, 2, 3, 0, 0)
        let day31 = z.date(2026, 2, 2, 23, 59)
        let keep = makeTodo("keep", done: true, doneAt: day30)
        let drop = makeTodo("drop", done: true, doneAt: day31)
        #expect(TodoRules.isRecentlyCompleted(keep, now: now, calendar: cal))
        #expect(!TodoRules.isRecentlyCompleted(drop, now: now, calendar: cal))
    }

    @Test func openToDosAreNeverRecentlyCompleted() {
        #expect(!TodoRules.isRecentlyCompleted(makeTodo("a"), now: now, calendar: cal))
    }

    @Test func hiddenListsAreLeftOut() {
        let items = [makeTodo("a", list: "x"), makeTodo("b", list: "y"), makeTodo("c", list: "x")]
        #expect(ids(TodoRules.shown(items, hiddenListIDs: ["y"])) == ["a", "c"])
        #expect(ids(TodoRules.shown(items, hiddenListIDs: [])) == ["a", "b", "c"])
    }

    @Test func openCountIsPerListAndSkipsDone() {
        let items = [
            makeTodo("a", list: "x"),
            makeTodo("b", list: "x", done: true, doneAt: now),
            makeTodo("c", list: "y")
        ]
        #expect(TodoRules.openCount(listID: "x", in: items) == 1)
        #expect(TodoRules.openCount(listID: "y", in: items) == 1)
        #expect(TodoRules.openCount(listID: "z", in: items) == 0)
    }

    @Test func newListAccountPrefersTheSavedOneThenICloudThenTheFirstThatAllows() {
        let icloud = TodoAccount(id: "ic", name: "Mein iCloud", allowsNewLists: true, isICloud: true)
        let other = TodoAccount(id: "ex", name: "iCloud", allowsNewLists: true)
        let locked = TodoAccount(id: "lk", name: "Locked", allowsNewLists: false)
        #expect(TodoRules.defaultAccountID(accounts: [other, icloud], preferred: "ex") == "ex")
        #expect(TodoRules.defaultAccountID(accounts: [other, icloud], preferred: nil) == "ic")
        #expect(TodoRules.defaultAccountID(accounts: [other, icloud], preferred: "gone") == "ic")
        #expect(TodoRules.defaultAccountID(accounts: [locked, other], preferred: nil) == "ex")
        #expect(TodoRules.defaultAccountID(accounts: [locked, other], preferred: "lk") == "ex")
        #expect(TodoRules.defaultAccountID(accounts: [locked], preferred: nil) == nil)
        #expect(TodoRules.defaultAccountID(accounts: [], preferred: nil) == nil)
    }
}
