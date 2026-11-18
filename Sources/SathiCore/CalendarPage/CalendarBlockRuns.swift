import Foundation

enum CalendarBlockRuns {
    typealias Item = CalendarBlockLayout.Item

    private static let runGap = TimeInterval(Limits.calendarGroupRunGapMinutes) * Timing.minute
    private static let attachGap = TimeInterval(Limits.calendarGroupAttachGapMinutes) * Timing.minute

    static func grouped(_ items: [Item], least: TimeInterval, column: String? = nil) -> [Item] {
        guard least > 0 else { return items.sorted { CalendarBlockLayout.precedes($0.span, $1.span) } }
        let acts = items.filter { joins($0.block) }.sorted { CalendarBlockLayout.precedes($0.span, $1.span) }
        let rest = items.filter { !joins($0.block) }
        return (rest + merge(acts, least: least, column: column)).sorted { CalendarBlockLayout.precedes($0.span, $1.span) }
    }

    private static func merge(_ acts: [Item], least: TimeInterval, column: String?) -> [Item] {
        var runs = shortRuns(acts, least: least)
        var taken = [Int?](repeating: nil, count: acts.count)
        for (r, run) in runs.enumerated() {
            for k in run {
                taken[k] = r
            }
        }
        for r in runs.indices {
            guard let pick = neighbour(of: runs[r], in: acts, taken: taken, least: least) else { continue }
            taken[pick] = r
            runs[r] = min(runs[r].lowerBound, pick) ... max(runs[r].upperBound, pick)
        }
        return acts.indices.compactMap { k in
            guard let r = taken[k] else { return acts[k] }
            guard k == runs[r].lowerBound else { return nil }
            return item(Array(acts[runs[r]]), column: column)
        }
    }

    private static func shortRuns(_ acts: [Item], least: TimeInterval) -> [ClosedRange<Int>] {
        var runs: [ClosedRange<Int>] = []
        var i = 0
        while i < acts.count {
            guard isShort(acts[i], least) else {
                i += 1
                continue
            }
            var j = i
            while j + 1 < acts.count, isShort(acts[j + 1], least), close(acts[j], acts[j + 1], runGap) {
                j += 1
            }
            runs.append(i ... j)
            i = j + 1
        }
        return runs
    }

    private static func neighbour(of run: ClosedRange<Int>, in acts: [Item], taken: [Int?], least: TimeInterval) -> Int? {
        let (i, j) = (run.lowerBound, run.upperBound)
        guard acts[j].span.end.timeIntervalSince(acts[i].span.start) < least, j + 1 < acts.count,
              acts[j + 1].span.start < acts[i].span.start.addingTimeInterval(least) else { return nil }
        if taken[j + 1] == nil, close(acts[j], acts[j + 1], attachGap) { return j + 1 }
        if i > 0, taken[i - 1] == nil, close(acts[i - 1], acts[i], attachGap) { return i - 1 }
        return nil
    }

    private static func item(_ members: [Item], column: String?) -> Item {
        guard members.count > 1 else { return members[0] }
        let end = members.map(\.span.end).max() ?? members[0].span.end
        return (CalendarBlockGroup.block(members.map(\.block), column: column), DateInterval(start: members[0].span.start, end: end))
    }

    private static func close(_ a: Item, _ b: Item, _ most: TimeInterval) -> Bool {
        (0 ... most).contains(b.span.start.timeIntervalSince(a.span.end))
    }

    private static func isShort(_ item: Item, _ least: TimeInterval) -> Bool {
        item.span.duration < least
    }

    private static func joins(_ b: CalendarBlock) -> Bool {
        guard b.style != .away, b.group == nil, case let .activity(_, running) = b.source else { return false }
        return !running
    }
}
