import Foundation

package struct ActivityCategoryTotal: Equatable, Identifiable, Sendable {
    package var name: String
    package var isNamed: Bool
    package var seconds: TimeInterval
    package var percent: Int

    package var id: String { name }

    package init(name: String, isNamed: Bool, seconds: TimeInterval, percent: Int) {
        self.name = name
        self.isNamed = isNamed
        self.seconds = seconds
        self.percent = percent
    }
}

package struct ActivityDayStats: Equatable, Sendable {
    package var segments: [ActivitySegment]
    package var realWork: TimeInterval
    package var away: TimeInterval
    package var notLogged: TimeInterval
    package var count: Int
    package var inCalendar: Int
    package var categories: [ActivityCategoryTotal]
    package var awayTotals: [ActivityCategoryTotal]

    package var tracked: TimeInterval { realWork + away + notLogged }
    package var topCategory: ActivityCategoryTotal? { categories.first }

    package init(_ day: ActivityDay) {
        let segs = ActivityTimeline.segments(day)
        func total(_ kind: ActivitySegmentKind) -> TimeInterval {
            segs.filter { $0.kind == kind }.reduce(0) { $0 + $1.length }
        }
        let work = segs.filter { $0.kind == .work }
        var people = day.activities.filter { $0.kind != .away }
        if let running = day.running, running.kind != .away, !people.contains(where: { $0.id == running.id }) { people.append(running) }
        segments = segs
        realWork = total(.work)
        away = total(.away)
        notLogged = total(.notLogged)
        count = Set(people.map(\.id)).count
        inCalendar = Set(people.filter { $0.eventID != nil || $0.sourceEventID != nil }.map(\.id)).count
        categories = Self.categoryTotals(work, realWork: total(.work))
        awayTotals = Self.awayTotals(segs.filter { $0.kind == .away })
    }

    package static func awayTotals(_ aways: [ActivitySegment]) -> [ActivityCategoryTotal] {
        var sums: [String: TimeInterval] = [:]
        for s in aways {
            sums[s.activity?.awayPlaceLabel ?? Copywriter.trackerAway, default: 0] += s.length
        }
        return sums
            .map { ActivityCategoryTotal(name: $0.key, isNamed: true, seconds: $0.value, percent: 0) }
            .sorted { ($1.seconds, $0.name) < ($0.seconds, $1.name) }
    }

    package static func categoryTotals(_ work: [ActivitySegment], realWork: TimeInterval) -> [ActivityCategoryTotal] {
        var sums: [String?: TimeInterval] = [:]
        for s in work {
            sums[s.activity?.category, default: 0] += s.length
        }
        let rows = sums.map { key, seconds in
            ActivityCategoryTotal(
                name: key ?? Copywriter.trackerNoCategory,
                isNamed: key != nil,
                seconds: seconds,
                percent: realWork > 0 ? Int((seconds / realWork * Double(Limits.fullPercent)).rounded()) : 0
            )
        }
        return rows.sorted { ($1.seconds, $0.name) < ($0.seconds, $1.name) }
    }
}
