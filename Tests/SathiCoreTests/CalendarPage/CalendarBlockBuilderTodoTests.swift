import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("CalendarBlockBuilder to-dos")
struct CalendarBlockBuilderTodoTests {
    private let zone = FixedZone.berlin
    private var calendar: Calendar { zone.calendar }
    private var wednesday: DateInterval {
        DateInterval(start: zone.date(2026, 3, 4), end: zone.date(2026, 3, 5))
    }

    private func build(_ todos: [Todo], colors: [String: UInt32] = ["inbox": 0xE58CF5]) -> [CalendarBlock] {
        CalendarBlockBuilder.todoBlocks(todos, colors: colors, interval: wednesday, calendar: calendar)
    }

    @Test func timedTodoIsAChipAtItsTime() throws {
        let due = zone.date(2026, 3, 4, 15, 30)
        let blocks = build([makeTodo("t1", "Call Rina", due: TodoDue(date: due, hasTime: true))])
        let block = try #require(blocks.first)
        #expect(blocks.count == 1)
        #expect(block.title == "Call Rina")
        #expect(!block.isAllDay)
        #expect(block.interval.start == due)
        #expect(block.source == .todo("t1"))
        #expect(block.id == "t-t1")
        #expect(block.activityIDs.isEmpty)
    }

    @Test func dateOnlyTodoGoesToTheAllDayRow() throws {
        let due = zone.date(2026, 3, 4, 9)
        let blocks = build([makeTodo("t2", "Pay rent", due: TodoDue(date: due, hasTime: false))])
        let block = try #require(blocks.first)
        #expect(blocks.count == 1)
        #expect(block.isAllDay)
        #expect(block.interval.start == zone.date(2026, 3, 4))
        #expect(block.source == .todo("t2"))
    }

    @Test func todoStyleCarriesTheListColor() throws {
        let due = TodoDue(date: zone.date(2026, 3, 4, 10), hasTime: true)
        let blocks = build([makeTodo("t3", list: "inbox", due: due)], colors: ["inbox": 0x112233])
        #expect(try #require(blocks.first).style == .todo(colorHex: 0x112233))
    }

    @Test func doneTodoDoesNotShow() {
        let due = TodoDue(date: zone.date(2026, 3, 4, 10), hasTime: true)
        let done = makeTodo("t4", due: due, done: true, doneAt: zone.date(2026, 3, 4, 11))
        #expect(build([done]).isEmpty)
    }

    @Test func todoWithNoDueDateDoesNotShow() {
        #expect(build([makeTodo("t5")]).isEmpty)
    }

    @Test func todoOutsideTheRangeDoesNotShow() {
        let before = TodoDue(date: zone.date(2026, 3, 3, 23, 59), hasTime: true)
        let after = TodoDue(date: zone.date(2026, 3, 5, 0, 0), hasTime: true)
        let dateOnlyAfter = TodoDue(date: zone.date(2026, 3, 5, 9), hasTime: false)
        let blocks = build([
            makeTodo("b", due: before),
            makeTodo("a", due: after),
            makeTodo("d", due: dateOnlyAfter)
        ])
        #expect(blocks.isEmpty)
    }

    @Test func dateOnlyTodoAtLateEveningStaysOnItsOwnDay() throws {
        let due = TodoDue(date: zone.date(2026, 3, 4, 23, 30), hasTime: false)
        let blocks = build([makeTodo("late", due: due)])
        #expect(try #require(blocks.first).interval.start == zone.date(2026, 3, 4))
    }

    private func pageDay(_ d: Int) -> DateInterval {
        CalendarPageDay.interval(of: DayKey(zone.date(2026, 3, d), calendar: calendar), calendar: calendar)
    }

    private func timedAt(_ date: Date, in interval: DateInterval) -> Int {
        CalendarBlockBuilder.todoBlocks(
            [makeTodo("e", due: TodoDue(date: date, hasTime: true))],
            colors: [:], interval: interval, calendar: calendar
        ).count
    }

    @Test func oneAMBelongsToThePreviousPageDay() {
        let due = zone.date(2026, 3, 5, 1)
        #expect(timedAt(due, in: pageDay(4)) == 1)
        #expect(timedAt(due, in: pageDay(5)) == 0)
    }

    @Test func fiveFiftyNineBelongsToThePreviousPageDay() {
        let due = zone.date(2026, 3, 5, 5, 59)
        #expect(timedAt(due, in: pageDay(4)) == 1)
        #expect(timedAt(due, in: pageDay(5)) == 0)
    }

    @Test func sixAMBelongsToTheNewPageDay() {
        let due = zone.date(2026, 3, 5, 6)
        #expect(timedAt(due, in: pageDay(4)) == 0)
        #expect(timedAt(due, in: pageDay(5)) == 1)
    }
}
