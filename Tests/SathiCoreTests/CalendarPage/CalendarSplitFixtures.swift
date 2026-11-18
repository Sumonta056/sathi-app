import Foundation
@testable import SathiCore
import SathiTestSupport

enum Split {
    static let zone = FixedZone("Asia/Dhaka")
    static var calendar: Calendar { zone.calendar }
    static let monday = 16
    static var page: DayKey { key(monday) }

    static let week = metrics(minHeight: 34, awayMinHeight: 34, gap: 2, folds: true)
    static let weekFlat = metrics(minHeight: 34, awayMinHeight: 34, gap: 2, folds: false)
    static let weekNarrow = metrics(minHeight: 22, awayMinHeight: 22, gap: 2, folds: true)
    static let day = metrics(minHeight: 46, awayMinHeight: 40, gap: 4, folds: false)

    static func metrics(
        pointsPerMinute: Double = 1, minHeight: Double, awayMinHeight: Double, gap: Double, folds: Bool
    ) -> CalendarLayoutMetrics {
        CalendarLayoutMetrics(
            pointsPerMinute: pointsPerMinute, minHeight: minHeight, awayMinHeight: awayMinHeight,
            gap: gap, titleRoom: 22, foldHeight: 22, foldsNights: folds
        )
    }

    static func key(_ date: Int) -> DayKey {
        DayKey(zone.date(2026, 11, date, 12), calendar: calendar)
    }

    static func at(_ clock: String, on date: Int = monday) -> Date {
        let parts = clock.split(separator: ":").compactMap { Int($0) }
        let nextDay = parts[0] < Limits.calendarPageDayStartHour
        let base = zone.date(2026, 11, nextDay ? date + 1 : date, parts[0], parts[1])
        return base.addingTimeInterval(TimeInterval(parts.count > 2 ? parts[2] : 0))
    }

    static func span(_ from: String, _ to: String, on date: Int = monday) -> DateInterval {
        DateInterval(start: at(from, on: date), end: at(to, on: date))
    }

    static func event(_ id: String, _ from: String, _ to: String, on date: Int = monday) -> CalendarBlock {
        let i = span(from, to, on: date)
        let info = CalendarEventInfo(id: id, title: id, start: i.start, end: i.end, calendarID: "work")
        return CalendarBlock(
            id: id, title: id, interval: i, style: .event(colorHex: 0), source: .event(info), isAllDay: false, activityIDs: []
        )
    }

    static func activity(_ id: String, _ from: String, _ to: String, on date: Int = monday, kind: ActivityKind = .work) -> CalendarBlock {
        let i = span(from, to, on: date)
        let a = Activity(kind: kind, text: id, category: "Focus", start: i.start, end: i.end)
        return CalendarBlock(
            id: id, title: id, interval: i, style: kind == .away ? .away : .activity(category: "Focus"),
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        )
    }

    static func away(_ id: String, _ from: String, _ to: String, on date: Int = monday) -> CalendarBlock {
        activity(id, from, to, on: date, kind: .away)
    }

    static func todo(_ id: String, _ due: String, on date: Int = monday, allDay: Bool = false) -> CalendarBlock {
        let d = allDay ? zone.date(2026, 11, date) : at(due, on: date)
        return CalendarBlock(
            id: id, title: id, interval: DateInterval(start: d, end: d), style: .todo(colorHex: 0),
            source: .todo(id), isAllDay: allDay, activityIDs: []
        )
    }

    static func layout(
        _ blocks: [CalendarBlock], days: [DayKey] = [page], rowMinutes: Int = 60, metrics: CalendarLayoutMetrics = day
    ) -> CalendarGridLayout {
        CalendarSplitLayout.layout(blocks, days: days, calendar: calendar, rowMinutes: rowMinutes, metrics: metrics)
    }

    static func laid(_ grid: CalendarGridLayout, _ id: String, on key: DayKey = page) -> CalendarLaidBlock? {
        grid.days[key]?.first { $0.block.id == id }
    }

    static func minute(_ date: Date, on key: DayKey) -> Int {
        let start = CalendarPageDay.interval(of: key, calendar: calendar).start
        return Int((date.timeIntervalSince(start) / Timing.minute).rounded())
    }

    static func row(_ grid: CalendarGridLayout, holding minute: Int) -> CalendarGridRow? {
        grid.rows.first { $0.startMinute <= minute && minute < $0.endMinute }
    }

    static func y(_ grid: CalendarGridLayout, _ minute: Int, ppm: Double = 1) -> Double? {
        guard let r = row(grid, holding: minute) else {
            return grid.rows.last.map { $0.top + $0.height }
        }
        return r.isFold ? nil : r.top + Double(minute - r.startMinute) * ppm
    }

    static func y(_ grid: CalendarGridLayout, _ clock: String, on key: DayKey = page, ppm: Double = 1) -> Double? {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let date = g.dateComponents([.day], from: key.start(in: g)).day ?? monday
        return y(grid, minute(at(clock, on: date), on: key), ppm: ppm)
    }
}

extension CalendarGridLayout {
    func rowAt(_ index: Int) -> CalendarGridRow? {
        rows.indices.contains(index) ? rows[index] : nil
    }
}
