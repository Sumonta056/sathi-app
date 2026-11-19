import Foundation

package enum CalendarSplitLayout {
    package static func layout(
        _ blocks: [CalendarBlock], days: [DayKey], calendar: Calendar, rowMinutes: Int, metrics: CalendarLayoutMetrics,
        now: Date? = nil
    ) -> CalendarGridLayout {
        let columns = days.map { CalendarDayMinutes(day: $0, calendar: calendar) }
        let cut = columns.map { column in blocks.filter { !$0.isAllDay }.compactMap { laid($0, in: column.interval) } }
        let busy = columns.indices.flatMap { d in
            cut[d].filter { $0.block.style != .away }.map { columns[d].minutes($0.span) }
        } + nowRow(now, columns: columns)
        let base = CalendarNightFold.rows(busy: busy, rowMinutes: rowMinutes, metrics: metrics)
        var items: [CalendarSplitRows.Item] = []
        for d in columns.indices {
            let open = cut[d].filter { !$0.isTodo && !parts($0, day: d, column: columns[d], rows: base).isEmpty }
            let shown = CalendarSplitLanes.arrange(open.filter { $0.half == .actual })
                + CalendarSplitLanes.arrange(open.filter { $0.half == .plan })
            items += shown.flatMap { parts($0, day: d, column: columns[d], rows: base) }
        }
        let placed = CalendarSplitRows.place(items, rows: base, metrics: metrics)
        let rows = CalendarNightFold.trimmed(placed.rows)
        var result: [DayKey: [CalendarLaidBlock]] = [:]
        for (d, key) in days.enumerated() {
            let column = columns[d]
            let shown = placed.items.filter { $0.day == d }.map { item in
                var b = item.laid
                b.hidden = b.hidden.map { position($0, column: column, rows: rows, metrics: metrics) }
                return b
            }
            let todos = cut[d].filter(\.isTodo).map { position($0, column: column, rows: rows, metrics: metrics) }
            result[key] = CalendarDoneDuring.link(shown + todos)
        }
        let bottoms = result.values.joined().map(\.bottom)
        return CalendarGridLayout(
            rows: rows, days: result, height: max(rows.last?.bottom ?? 0, bottoms.max() ?? 0),
            pointsPerMinute: metrics.pointsPerMinute
        )
    }

    private static func nowRow(_ now: Date?, columns: [CalendarDayMinutes]) -> [Range<Int>] {
        guard let now, let column = columns.first(where: { $0.interval.contains(now) && now < $0.interval.end }) else { return [] }
        let m = column.minute(now)
        return [m ..< m]
    }

    private static func laid(_ block: CalendarBlock, in column: DateInterval) -> CalendarLaidBlock? {
        let r = CalendarRounding.rounded(block.interval)
        let span = DateInterval(start: max(r.start, column.start), end: max(max(r.start, column.start), min(r.end, column.end)))
        let keeps = span.duration > 0 || (r.duration == 0 && column.start <= r.start && r.start < column.end)
        guard keeps else { return nil }
        if case .activity = block.source { return CalendarLaidBlock(block: block, span: span, half: .actual, rounded: r) }
        return CalendarLaidBlock(block: block, span: span, half: .plan, rounded: r)
    }

    private static func parts(
        _ b: CalendarLaidBlock, day: Int, column: CalendarDayMinutes, rows: [CalendarGridRow]
    ) -> [CalendarSplitRows.Item] {
        let m = column.minutes(b.span)
        let start = opening(m.lowerBound, rows: rows)
        if m.isEmpty {
            return start == m.lowerBound ? [CalendarSplitRows.Item(laid: b, day: day, from: start, to: start)] : []
        }
        return CalendarFoldParts.open(start ..< max(start, m.upperBound), rows: rows).enumerated().map { index, part in
            var laid = b
            laid.part = index
            return CalendarSplitRows.Item(laid: laid, day: day, from: part.lowerBound, to: part.upperBound)
        }
    }

    private static func opening(_ minute: Int, rows: [CalendarGridRow]) -> Int {
        guard let r = rows.first(where: { $0.holds(minute) }), r.isFold else { return minute }
        return r.endMinute
    }

    private static func position(
        _ b: CalendarLaidBlock, column: CalendarDayMinutes, rows: [CalendarGridRow], metrics m: CalendarLayoutMetrics
    ) -> CalendarLaidBlock {
        var b = b
        let span = column.minutes(b.span)
        b.top = CalendarSplitRows.y(opening(span.lowerBound, rows: rows), rows, m)
        b.bottom = b.isTodo ? b.top : max(b.top + m.least(for: b.block, minutes: span.count), CalendarSplitRows.y(span.upperBound, rows, m))
        return b
    }
}
