import Foundation
@testable import SathiCore

enum SplitCheck {
    static let tolerance = 0.01

    private struct Scope {
        let grid: CalendarGridLayout
        let key: DayKey
        let metrics: CalendarLayoutMetrics
        let ppm: Double
    }

    static func problems(_ grid: CalendarGridLayout, metrics: CalendarLayoutMetrics, ppm: Double = 1) -> [String] {
        var found = rowProblems(grid, metrics: metrics)
        for (key, blocks) in grid.days.sorted(by: { $0.key < $1.key }) {
            let shown = blocks.filter { !isTodo($0.block) }
            let scope = Scope(grid: grid, key: key, metrics: metrics, ppm: ppm)
            found += shown.flatMap { blockProblems($0, in: shown, scope) }
            for half in [CalendarHalf.actual, .plan] {
                found += pairProblems(shown.filter { $0.half == half }, key: key)
            }
        }
        return found
    }

    static func realOverlap(_ a: CalendarLaidBlock, _ b: CalendarLaidBlock) -> Bool {
        a.span.start < b.span.end && b.span.start < a.span.end
    }

    static func sharesWidth(_ a: CalendarLaidBlock, _ b: CalendarLaidBlock) -> Bool {
        a.lane * b.lanes < (b.lane + 1) * a.lanes && b.lane * a.lanes < (a.lane + 1) * b.lanes
    }

    static func isTodo(_ b: CalendarBlock) -> Bool {
        if case .todo = b.source { return true }
        return false
    }

    private static func rowProblems(_ grid: CalendarGridLayout, metrics: CalendarLayoutMetrics) -> [String] {
        var found = grid.rows.isEmpty ? ["grid has no rows"] : []
        var top = 0.0
        for r in grid.rows {
            if abs(r.top - top) > tolerance { found.append("row \(r.startMinute) top \(r.top) expected \(top)") }
            let base = Double(r.endMinute - r.startMinute) * metrics.pointsPerMinute
            if r.isFold, abs(r.height - metrics.foldHeight) > tolerance { found.append("fold \(r.startMinute) height \(r.height)") }
            if !r.isFold, r.height < base - tolerance { found.append("row \(r.startMinute) shrank to \(r.height)") }
            top = r.top + r.height
        }
        if grid.height < top - tolerance { found.append("grid height \(grid.height) under rows \(top)") }
        return found
    }

    private static func blockProblems(_ b: CalendarLaidBlock, in all: [CalendarLaidBlock], _ scope: Scope) -> [String] {
        let (grid, key, metrics, ppm) = (scope.grid, scope.key, scope.metrics, scope.ppm)
        let name = "\(key.raw) \(b.block.title) \(Split.minute(b.span.start, on: key))"
        guard let shown = shownMinutes(b, key: key, grid: grid),
              let row = Split.row(grid, holding: shown.lowerBound), !row.isFold,
              let ys = Split.y(grid, shown.lowerBound, ppm: ppm) else { return [] }
        var found: [String] = []
        let least = b.block.style == .away ? metrics.awayMinHeight : metrics.minHeight
        let endRow = Split.row(grid, holding: shown.upperBound)
        let endsAtStrip = !shown.isEmpty && (endRow?.isFold == true || shown.upperBound >= (grid.rows.last?.endMinute ?? 0))
        if b.top < ys - tolerance { found.append("\(name) moved up: \(b.top) < \(ys)") }
        if !endsAtStrip, b.bottom < b.top + least - tolerance { found.append("\(name) under minimum height") }
        if let ye = Split.y(grid, shown.upperBound, ppm: ppm), b.bottom < ye - tolerance {
            found.append("\(name) ends above its real end")
        }
        if b.top + metrics.titleRoom > row.top + row.height + tolerance { found.append("\(name) title leaves its start row") }
        if b.top > ys + tolerance {
            let pusher = all.contains {
                $0.half == b.half && $0.id != b.id && sharesWidth($0, b) && !realOverlap($0, b)
                    && abs($0.bottom + metrics.gap - b.top) < tolerance
            }
            if !pusher { found.append("\(name) pushed to \(b.top) without a block one gap above") }
        }
        return found
    }

    private static func shownMinutes(_ b: CalendarLaidBlock, key: DayKey, grid: CalendarGridLayout) -> Range<Int>? {
        let real = Split.minute(b.span.start, on: key) ..< max(Split.minute(b.span.start, on: key), Split.minute(b.span.end, on: key))
        if real.isEmpty { return real }
        let parts = CalendarFoldParts.open(real, rows: grid.rows)
        return parts.indices.contains(b.part) ? parts[b.part] : nil
    }

    private static func pairProblems(_ blocks: [CalendarLaidBlock], key: DayKey) -> [String] {
        var found: [String] = []
        for (i, a) in blocks.enumerated() {
            for b in blocks[(i + 1)...] where sharesWidth(a, b) && a.top < b.bottom - tolerance && b.top < a.bottom - tolerance {
                if !(realOverlap(a, b) && a.depth != b.depth) {
                    found.append("\(key.raw) \(a.block.title) and \(b.block.title) overlap on screen")
                }
            }
        }
        return found
    }
}
