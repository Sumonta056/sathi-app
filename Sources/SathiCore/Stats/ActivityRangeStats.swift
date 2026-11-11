import Foundation

package enum ActivityRangeRowKind: Equatable, Sendable {
    case category
    case events
    case away
}

package struct ActivityRangeTotal: Equatable, Identifiable, Sendable {
    package var name: String
    package var kind: ActivityRangeRowKind
    package var isNamed: Bool
    package var seconds: TimeInterval
    package var percent: Int
    package var change: RangeChange

    package var id: String { kind == .category ? name : "\(kind)" }
}

package struct ActivityRangeStats: Equatable, Sendable {
    package var rows: [ActivityMonthRow]
    package var realWork: TimeInterval
    package var away: TimeInterval
    package var averageDay: TimeInterval
    package var bestDay: ActivityMonthRow?
    package var realWorkChange: RangeChange
    package var averageDayChange: RangeChange
    package var bestDayChange: RangeChange
    package var awayChange: RangeChange
    package var categories: [ActivityRangeTotal]

    package init(_ days: [ActivityDay], compare: [ActivityDay]) {
        let current = ActivityMonthStats(days)
        let before = ActivityMonthStats(compare)
        let hasData = !before.rows.isEmpty
        let best = current.bestDay?.realWork ?? 0
        rows = current.rows
        realWork = current.realWork
        away = current.away
        averageDay = current.averageDay
        bestDay = current.bestDay
        realWorkChange = RangeChange(current: current.realWork, previous: before.realWork, hasData: hasData)
        averageDayChange = RangeChange(current: current.averageDay, previous: before.averageDay, hasData: hasData)
        bestDayChange = RangeChange(current: best, previous: before.bestDay?.realWork ?? 0, hasData: hasData)
        awayChange = RangeChange(current: current.away, previous: before.away, hasData: hasData)
        categories = Self.totals(current, before: before, hasData: hasData)
    }

    private static func totals(_ now: ActivityMonthStats, before: ActivityMonthStats, hasData: Bool) -> [ActivityRangeTotal] {
        let current = Split(now)
        let previous = Split(before)
        func change(_ a: TimeInterval, _ b: TimeInterval) -> RangeChange {
            RangeChange(current: a, previous: b, hasData: hasData)
        }
        var rows = current.categories.map { total in
            ActivityRangeTotal(
                name: total.name, kind: .category, isNamed: total.isNamed, seconds: total.seconds, percent: total.percent,
                change: change(total.seconds, previous.categories.first { $0.name == total.name }?.seconds ?? 0)
            )
        }
        if current.events > 0 {
            rows.append(ActivityRangeTotal(
                name: Copywriter.trackerCalendarEvents, kind: .events, isNamed: true, seconds: current.events,
                percent: percent(current.events, of: now.realWork), change: change(current.events, previous.events)
            ))
        }
        if now.away > 0 {
            rows.append(ActivityRangeTotal(
                name: Copywriter.trackerAway, kind: .away, isNamed: true, seconds: now.away,
                percent: 0, change: change(now.away, before.away)
            ))
        }
        return rows.enumerated()
            .sorted { $0.element.seconds != $1.element.seconds ? $0.element.seconds > $1.element.seconds : $0.offset < $1.offset }
            .map(\.element)
    }

    private static func percent(_ part: TimeInterval, of whole: TimeInterval) -> Int {
        whole > 0 ? Int((part / whole * Double(Limits.fullPercent)).rounded()) : 0
    }

    private struct Split {
        var categories: [ActivityCategoryTotal]
        var events: TimeInterval

        init(_ stats: ActivityMonthStats) {
            let work = stats.rows.flatMap(\.segments).filter { $0.kind == .work }
            let events = work.filter { $0.activity?.kind == .event }
            self.events = events.reduce(0) { $0 + $1.length }
            categories = ActivityDayStats.categoryTotals(work.filter { $0.activity?.kind != .event }, realWork: stats.realWork)
        }
    }
}
