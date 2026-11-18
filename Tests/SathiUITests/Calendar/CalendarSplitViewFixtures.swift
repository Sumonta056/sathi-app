import Foundation
@testable import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI

enum CalendarSplitViewFixtures {
    final class Spy {
        var opened: [String] = []
        var slots: [Date] = []
    }

    static let z = FixedZone.berlin
    static var cal: Calendar { z.calendar }
    static let monday = DayKey(FixedZone.berlin.date(2026, 11, 16, 12), calendar: FixedZone.berlin.calendar)

    static func at(_ h: Int, _ m: Int = 0) -> Date {
        z.date(2026, 11, 16, h, m)
    }

    static func activity(_ title: String, _ from: Date, _ to: Date, kind: ActivityKind = .work) -> CalendarBlock {
        let a = Activity(kind: kind, text: title, category: kind == .away ? nil : "Coding", start: from, end: to)
        return CalendarBlock(
            id: a.id.raw.uuidString, title: title, interval: DateInterval(start: from, end: to),
            style: kind == .away ? .away : .activity(category: "Coding"),
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
    }

    static func event(_ title: String, _ from: Date, _ to: Date, id: String = "e1") -> CalendarBlock {
        let info = CalendarEventInfo(id: id, title: title, start: from, end: to, calendarID: "work")
        return CalendarBlock(
            id: id, title: title, interval: DateInterval(start: from, end: to), style: .event(colorHex: 0x4F8CF7),
            source: .event(info), isAllDay: false, activityIDs: []
        )
    }

    static func todo(_ title: String, _ due: Date) -> CalendarBlock {
        CalendarBlock(
            id: "t-a", title: title, interval: DateInterval(start: due, end: due), style: .todo(colorHex: 0xE58CF5),
            source: .todo("a"), isAllDay: false, activityIDs: []
        )
    }

    static func laid(
        _ block: CalendarBlock, top: Double, bottom: Double, lane: Int = 0, lanes: Int = 1, depth: Int = 0
    ) -> CalendarLaidBlock {
        let half: CalendarHalf = if case .activity = block.source { .actual } else { .plan }
        var l = CalendarLaidBlock(block: block, span: block.interval, half: half)
        l.top = top
        l.bottom = bottom
        l.lane = lane
        l.lanes = lanes
        l.depth = depth
        return l
    }

    struct Row {
        let start: Int
        let end: Int
        let height: Double
        var fold = false
    }

    static func rows(_ spans: [Row]) -> [CalendarGridRow] {
        var top = 0.0
        return spans.map { r in
            defer { top += r.height }
            return CalendarGridRow(startMinute: r.start, endMinute: r.end, top: top, height: r.height, isFold: r.fold)
        }
    }

    static func hourRows(_ count: Int = 24) -> [CalendarGridRow] {
        rows((0 ..< count).map { Row(start: $0 * 60, end: $0 * 60 + 60, height: 60) })
    }

    static func grid(_ days: [DayKey: [CalendarLaidBlock]], rows: [CalendarGridRow] = hourRows()) -> CalendarGridLayout {
        CalendarGridLayout(rows: rows, days: days, height: rows.last?.bottom ?? 0, pointsPerMinute: 1)
    }

    static func data(_ range: CalendarPageRange, grid: CalendarGridLayout?) -> CalendarPageData {
        var d = CalendarPageData(range: range, allDay: [], blocks: [], stats: CalendarPageStats(), monthCells: [], texts: [:])
        d.grid = grid
        return d
    }

    static func dayRange() -> CalendarPageRange {
        .containing(at(12), kind: .day, calendar: cal)
    }

    static func weekRange(_ days: Int = 3) -> CalendarPageRange {
        .containing(at(12), kind: .week, calendar: cal, weekDays: days)
    }

    static func actions(_ spy: Spy) -> CalendarGridActions {
        var a = CalendarGridActions()
        a.block = { _, block, _ in spy.opened.append(block.id) }
        a.slot = { _, date, _ in spy.slots.append(date) }
        return a
    }
}
