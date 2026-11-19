import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
enum CalendarHoverFixtures {
    final class Spy {
        var opened: [String] = []
        var todoEdits: [String] = []
        var failed: [String] = []
    }

    static let write = Activity(text: "Write", category: "Coding", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 10, 30))

    nonisolated static func standup(repeating: Bool = false) -> CalendarEventInfo {
        CalendarEventInfo(
            id: "s", title: "Standup", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 9, 30), calendarID: "work",
            isRepeating: repeating
        )
    }

    static func harness(at now: Date = day(2026, 3, 4, 12), events: [CalendarEventInfo] = [standup()], todos: [Todo] = []) -> EngineHarness {
        let h = EngineHarness(at: now, activities: InMemoryActivityStore(activities: [write])) {
            $0.prefs.tracker.isOn = true
            $0.prefs.todos.isOn = !todos.isEmpty
        }
        h.calendarWriter.eventsValue = events
        h.todos.listsValue = [makeTodoList("inbox", "Inbox")]
        h.todos.todosValue = todos
        _ = h.engine.calendarPageBase(range(h))
        return h
    }

    static func range(_ h: EngineHarness) -> CalendarPageRange {
        .containing(day(2026, 3, 4, 12), kind: .day, calendar: h.engine.rangeCalendar)
    }

    static func block(_ h: EngineHarness, _ title: String) throws -> CalendarBlock {
        try #require(h.engine.calendarPageBase(range(h)).blocks.first { $0.title == title })
    }

    static func todo(_ id: String = "a") -> CalendarBlock {
        let start = day(2026, 3, 4, 15)
        return CalendarBlock(
            id: "t-" + id, title: "Call Rina", interval: DateInterval(start: start, end: start),
            style: .todo(colorHex: 0xE58CF5), source: .todo(id), isAllDay: false, activityIDs: []
        )
    }

    static let awayRow = Activity(kind: .away, text: "Away", start: day(2026, 3, 4, 13), end: day(2026, 3, 4, 14))

    static func away() -> CalendarBlock {
        let a = awayRow
        return CalendarBlock(
            id: a.id.raw.uuidString, title: "Away", interval: a.interval, style: .away, source: .activity(a, running: false),
            isAllDay: false, activityIDs: [a.id]
        )
    }

    static func laid(_ block: CalendarBlock) -> CalendarLaidBlock {
        let half: CalendarHalf = if case .activity = block.source { .actual } else { .plan }
        return CalendarLaidBlock(block: block, span: block.interval, half: half)
    }

    static func laid(_ h: EngineHarness, _ title: String) throws -> CalendarLaidBlock {
        try laid(block(h, title))
    }

    static func target(_ laid: CalendarLaidBlock, prefersLeft: Bool = false) -> CalendarHoverTarget {
        CalendarHoverTarget(
            day: DayKey(day(2026, 3, 4, 12), calendar: Calendar.current), laid: laid, among: [laid],
            rect: CGRect(x: 100, y: 40, width: 80, height: 30), radius: 5, prefersLeft: prefersLeft
        )
    }

    static func runner(_ h: EngineHarness, _ spy: Spy) -> CalendarHoverRun {
        var grid = CalendarGridActions()
        grid.block = { _, block, _ in spy.opened.append(block.id) }
        grid.failed = { spy.failed.append($0) }
        return CalendarHoverRun(engine: h.engine, grid: grid) { spy.todoEdits.append($0.id) }
    }
}
