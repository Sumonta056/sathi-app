import Foundation

package struct ActivityMonthRow: Equatable, Identifiable, Sendable {
    package var day: DayKey
    package var hours: DateInterval
    package var realWork: TimeInterval
    package var away: TimeInterval
    package var segments: [ActivitySegment]
    package var topTexts: [String]

    package var id: DayKey { day }
}

package struct ActivityMonthStats: Equatable, Sendable {
    package var rows: [ActivityMonthRow]
    package var realWork: TimeInterval
    package var away: TimeInterval
    package var categories: [ActivityCategoryTotal]

    package var daysTracked: Int { rows.count }
    package var averageDay: TimeInterval { rows.isEmpty ? 0 : realWork / Double(rows.count) }
    package var bestDay: ActivityMonthRow? { rows.max { ($0.realWork, $1.day) < ($1.realWork, $0.day) } }

    package init(_ days: [ActivityDay]) {
        var rows: [ActivityMonthRow] = []
        var work: [ActivitySegment] = []
        var away: TimeInterval = 0
        for day in days.sorted(by: { $0.day < $1.day }) {
            let stats = ActivityDayStats(day)
            guard stats.realWork > 0 else { continue }
            let texts = ActivityTextTotals.grouped(stats.segments).prefix(Limits.monthlyTopTexts).map(\.text)
            rows.append(ActivityMonthRow(
                day: day.day, hours: day.hours, realWork: stats.realWork, away: stats.away,
                segments: stats.segments, topTexts: Array(texts)
            ))
            work += stats.segments.filter { $0.kind == .work }
            away += stats.away
        }
        self.rows = rows
        self.away = away
        realWork = rows.reduce(0) { $0 + $1.realWork }
        categories = ActivityDayStats.categoryTotals(work, realWork: realWork)
    }
}
