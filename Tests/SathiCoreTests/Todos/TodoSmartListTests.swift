import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoSmartList")
struct TodoSmartListTests {
    private let z = FixedZone.berlin
    private var cal: Calendar { z.calendar }
    private var now: Date { z.date(2026, 3, 4, 10) }

    private func timed(_ d: Int, _ h: Int) -> TodoDue {
        TodoDue(date: z.date(2026, 3, d, h), hasTime: true)
    }

    private func dateOnly(_ d: Int) -> TodoDue {
        TodoDue(date: z.date(2026, 3, d), hasTime: false)
    }

    private var items: [Todo] {
        [
            makeTodo("overdue", due: timed(3, 9)),
            makeTodo("today", due: timed(4, 15)),
            makeTodo("todayDate", due: dateOnly(4)),
            makeTodo("tomorrow", due: timed(5, 9)),
            makeTodo("noDate"),
            makeTodo("doneRecent", due: dateOnly(4), done: true, doneAt: z.date(2026, 3, 4, 8)),
            makeTodo("doneOlder", done: true, doneAt: z.date(2026, 3, 1, 8)),
            makeTodo("doneAncient", done: true, doneAt: z.date(2026, 1, 1, 8))
        ]
    }

    private func ids(_ list: TodoSmartList) -> [String] {
        list.todos(in: items, now: now, calendar: cal).map(\.id)
    }

    @Test func thereAreFourListsInOrder() {
        #expect(TodoSmartList.allCases == [.today, .scheduled, .all, .completed])
    }

    @Test func todayHoldsOpenToDosDueTodayOrEarlier() {
        #expect(ids(.today) == ["overdue", "todayDate", "today"])
    }

    @Test func scheduledHoldsOpenToDosWithADueDate() {
        #expect(ids(.scheduled) == ["overdue", "todayDate", "today", "tomorrow"])
    }

    @Test func allHoldsEveryOpenToDo() {
        #expect(ids(.all) == ["overdue", "todayDate", "today", "tomorrow", "noDate"])
    }

    @Test func completedHoldsTheLast30DaysNewestFirst() {
        #expect(ids(.completed) == ["doneRecent", "doneOlder"])
    }

    @Test func countsMatchTheLists() {
        for list in TodoSmartList.allCases {
            #expect(list.count(in: items, now: now, calendar: cal) == ids(list).count)
        }
        #expect(TodoSmartList.today.count(in: items, now: now, calendar: cal) == 3)
        #expect(TodoSmartList.completed.count(in: items, now: now, calendar: cal) == 2)
    }

    @Test func matchesAgreesWithTheListContent() {
        let overdue = makeTodo("o", due: timed(3, 9))
        #expect(TodoSmartList.today.matches(overdue, now: now, calendar: cal))
        #expect(TodoSmartList.scheduled.matches(overdue, now: now, calendar: cal))
        #expect(TodoSmartList.all.matches(overdue, now: now, calendar: cal))
        #expect(!TodoSmartList.completed.matches(overdue, now: now, calendar: cal))
        let done = makeTodo("d", done: true, doneAt: z.date(2026, 3, 4, 8))
        #expect(TodoSmartList.completed.matches(done, now: now, calendar: cal))
        #expect(!TodoSmartList.all.matches(done, now: now, calendar: cal))
    }

    @Test func emptyInputGivesEmptyLists() {
        for list in TodoSmartList.allCases {
            #expect(list.todos(in: [], now: now, calendar: cal).isEmpty)
            #expect(list.count(in: [], now: now, calendar: cal) == 0)
        }
    }
}
