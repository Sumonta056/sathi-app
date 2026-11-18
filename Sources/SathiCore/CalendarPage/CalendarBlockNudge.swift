import Foundation

enum CalendarBlockNudge {
    static func apply(_ placed: [CalendarPlacedBlock], minimumMinutes: Double, within column: DateInterval? = nil) -> [CalendarPlacedBlock] {
        let fit = Fit(least: max(0, minimumMinutes) * Timing.minute, end: column?.end)
        var result = placed
        let order = result.indices.filter { !result[$0].isBackdrop }.sorted {
            result[$0].span.start != result[$1].span.start ? result[$0].span.start < result[$1].span.start : $0 < $1
        }
        for (k, i) in order.enumerated() {
            let before = order.prefix(k).map { result[$0] }
            let real = result[i].span.start
            let floor = before.filter { pushes($0, result[i]) }.map(\.displaySpan.end).max()
            var start = fit.start(max(real, floor ?? real), real: real)
            fill(&result[i], start: start, fit: fit)
            while let clear = clearance(result[i], before, least: fit.least) {
                let next = fit.start(clear, real: real)
                guard next > start else { break }
                start = next
                fill(&result[i], start: start, fit: fit)
            }
        }
        return result
    }

    private static func clearance(_ block: CalendarPlacedBlock, _ before: [CalendarPlacedBlock], least: TimeInterval) -> Date? {
        before.filter { sharesWidth($0, block) }
            .flatMap { covered($0, by: block, least: least) }
            .filter { $0.start < block.displaySpan.end && block.displaySpan.start < $0.end }
            .map(\.end).max()
    }

    private static func covered(_ other: CalendarPlacedBlock, by block: CalendarPlacedBlock, least: TimeInterval) -> [DateInterval] {
        let raisedOver = block.depth > other.depth && block.span.start < other.span.end && other.span.start < block.span.end
        guard raisedOver else { return [other.displaySpan] }
        return [DateInterval(start: other.displaySpan.start, duration: least)] + other.children.map(\.displaySpan)
    }

    private struct Fit {
        let least: TimeInterval
        let end: Date?

        func start(_ wanted: Date, real: Date) -> Date {
            guard let end else { return wanted }
            return min(wanted, max(real, end.addingTimeInterval(-least)))
        }

        func span(_ start: Date, _ wanted: Date) -> DateInterval {
            guard let end else { return DateInterval(start: start, end: wanted) }
            return DateInterval(start: start, end: max(start, min(wanted, end)))
        }
    }

    private static func pushes(_ above: CalendarPlacedBlock, _ below: CalendarPlacedBlock) -> Bool {
        above.depth == below.depth && above.span.end <= below.span.start && sharesWidth(above, below)
    }

    private static func sharesWidth(_ a: CalendarPlacedBlock, _ b: CalendarPlacedBlock) -> Bool {
        a.lane * b.lanes < (b.lane + 1) * a.lanes && b.lane * a.lanes < (a.lane + 1) * b.lanes
    }

    private static func fill(_ host: inout CalendarPlacedBlock, start: Date, fit: Fit) {
        let shift = start.timeIntervalSince(host.span.start)
        var cursor = start.addingTimeInterval(host.children.isEmpty ? 0 : fit.least)
        for c in host.children.indices {
            let child = host.children[c].span
            let from = fit.start(max(child.start.addingTimeInterval(shift), cursor), real: child.start)
            let shown = fit.span(from, from.addingTimeInterval(max(child.duration, fit.least)))
            host.children[c].displaySpan = shown
            cursor = shown.end
        }
        let own = start.addingTimeInterval(max(host.span.duration, fit.least))
        host.displaySpan = fit.span(start, max(own, cursor))
    }
}
