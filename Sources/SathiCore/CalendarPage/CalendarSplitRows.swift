import Foundation

enum CalendarSplitRows {
    struct Item {
        var laid: CalendarLaidBlock
        let day: Int
        let from: Int
        let to: Int
    }

    private struct Column: Hashable {
        let day: Int
        let half: CalendarHalf
    }

    static func place(
        _ items: [Item], rows: [CalendarGridRow], metrics m: CalendarLayoutMetrics
    ) -> (rows: [CalendarGridRow], items: [Item]) {
        var rows = rows
        var items = items
        var columns: [Column: [Int]] = [:]
        for i in order(items) {
            let x = items[i]
            guard let r = row(holding: x.from, in: rows), !rows[r].isFold else { continue }
            let column = Column(day: x.day, half: x.laid.half)
            let placed = (columns[column] ?? []).map { items[$0] }
            let above = placed.filter { pushes($0.laid, x.laid) }
            let floor = above.map { bottom(of: $0, rows: rows, metrics: m) + m.gap }.max() ?? -Double.infinity
            let parent = placed.filter { isParent($0.laid, of: x.laid) }.map(\.laid.top).max() ?? -Double.infinity
            let top = max(y(x.from, rows, m), floor, parent)
            items[i].laid.top = top
            grow(&rows, at: r, by: top + m.titleRoom - rows[r].bottom)
            columns[column, default: []].append(i)
        }
        for i in items.indices {
            items[i].laid.bottom = bottom(of: items[i], rows: rows, metrics: m)
        }
        return (rows, items)
    }

    static func y(_ minute: Int, _ rows: [CalendarGridRow], _ m: CalendarLayoutMetrics) -> Double {
        CalendarGridLayout.y(minute, rows: rows, pointsPerMinute: m.pointsPerMinute)
    }

    static func row(holding minute: Int, in rows: [CalendarGridRow]) -> Int? {
        if let r = rows.firstIndex(where: { $0.holds(minute) }) { return r }
        guard let last = rows.last, minute >= last.endMinute else { return nil }
        return rows.count - 1
    }

    static func sharesWidth(_ a: CalendarLaidBlock, _ b: CalendarLaidBlock) -> Bool {
        a.lane * b.lanes < (b.lane + 1) * a.lanes && b.lane * a.lanes < (a.lane + 1) * b.lanes
    }

    private static func order(_ items: [Item]) -> [Int] {
        items.indices.sorted { a, b in
            let (x, z) = (items[a], items[b])
            return x.from != z.from ? x.from < z.from : CalendarSplitLanes.precedes(x.laid.span, z.laid.span)
        }
    }

    private static func pushes(_ above: CalendarLaidBlock, _ x: CalendarLaidBlock) -> Bool {
        !CalendarSplitLanes.overlaps(above.span, x.span) && sharesWidth(above, x)
    }

    private static func isParent(_ p: CalendarLaidBlock, of x: CalendarLaidBlock) -> Bool {
        x.depth > 0 && p.depth == x.depth - 1 && CalendarSplitLanes.overlaps(p.span, x.span)
    }

    private static func bottom(of item: Item, rows: [CalendarGridRow], metrics m: CalendarLayoutMetrics) -> Double {
        max(item.laid.top + m.least(for: item.laid.block), y(item.to, rows, m))
    }

    private static func grow(_ rows: inout [CalendarGridRow], at r: Int, by extra: Double) {
        guard extra > 0 else { return }
        rows[r].height += extra
        for i in rows.indices where i > r {
            rows[i].top += extra
        }
    }
}
