import Foundation

package enum CalendarSplitLayout {
    package static func layout(
        _ blocks: [CalendarBlock], days: [DayKey], calendar: Calendar, rowMinutes: Int, metrics: CalendarLayoutMetrics
    ) -> CalendarGridLayout {
        let columns = days.map { CalendarDayMinutes(day: $0, calendar: calendar) }
        let cut = columns.map { column in blocks.filter { !$0.isAllDay }.compactMap { laid($0, in: column.interval) } }
        let busy = columns.indices.flatMap { d in
            cut[d].filter { $0.block.style != .away }.map { columns[d].minutes($0.span) }
        }
        let base = CalendarNightFold.rows(busy: busy, rowMinutes: rowMinutes, metrics: metrics)
        var items: [CalendarSplitRows.Item] = []
        for d in columns.indices {
            let open = cut[d].filter { !$0.isTodo && item($0, day: d, column: columns[d], rows: base) != nil }
            let shown = CalendarSplitLanes.arrange(open.filter { $0.half == .actual })
                + CalendarSplitLanes.arrange(open.filter { $0.half == .plan })
            items += shown.compactMap { item($0, day: d, column: columns[d], rows: base) }
        }
        let placed = CalendarSplitRows.place(items, rows: base, metrics: metrics)
        let rows = placed.rows
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

    private static func laid(_ block: CalendarBlock, in column: DateInterval) -> CalendarLaidBlock? {
        let r = CalendarRounding.rounded(block.interval)
        let span = DateInterval(start: max(r.start, column.start), end: max(max(r.start, column.start), min(r.end, column.end)))
        let keeps = span.duration > 0 || (r.duration == 0 && column.start <= r.start && r.start < column.end)
        guard keeps else { return nil }
        if case .activity = block.source { return CalendarLaidBlock(block: block, span: span, half: .actual) }
        return CalendarLaidBlock(block: block, span: span, half: .plan)
    }

    private static func item(
        _ b: CalendarLaidBlock, day: Int, column: CalendarDayMinutes, rows: [CalendarGridRow]
    ) -> CalendarSplitRows.Item? {
        let m = column.minutes(b.span)
        let start = opening(m.lowerBound, rows: rows)
        guard start < m.upperBound || (m.isEmpty && start == m.lowerBound) else { return nil }
        return CalendarSplitRows.Item(laid: b, day: day, from: start, to: m.upperBound)
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
        b.bottom = b.isTodo ? b.top : max(b.top + m.least(for: b.block), CalendarSplitRows.y(span.upperBound, rows, m))
        return b
    }
}
