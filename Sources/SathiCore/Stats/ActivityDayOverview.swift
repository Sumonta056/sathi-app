import Foundation

package struct ActivityDayOverview: Equatable, Sendable {
    package var categories: [ActivityCategoryTotal]
    package var logged: TimeInterval
    package var loggedChange: RangeChange
    package var focus: TimeInterval
    package var away: TimeInterval
    package var awayCount: Int
    package var topPlace: String?
    package var count: Int
    package var gaps: Int

    package var topCategory: String? { categories.first?.name }

    package var focusPercent: Int? {
        logged > 0 ? Int((focus / logged * Double(Limits.fullPercent)).rounded()) : nil
    }

    package init(_ day: ActivityDay, loggedChange: RangeChange) {
        let stats = ActivityDayStats(day)
        let segments = stats.segments
        let aways = segments.filter { $0.kind == .away }
        categories = stats.categories
        logged = stats.realWork
        self.loggedChange = loggedChange
        focus = segments
            .filter { $0.kind == .work && Self.focusKinds.contains($0.activity?.kind ?? .work) }
            .reduce(0) { $0 + $1.length }
        away = stats.away
        awayCount = aways.count
        topPlace = Self.topPlace(aways)
        count = stats.count
        gaps = segments.filter { $0.kind == .notLogged && $0.length >= Timing.activityMinimum }.count
    }

    private static let focusKinds: Set<ActivityKind> = [.work, .timeBlock]

    private static func topPlace(_ aways: [ActivitySegment]) -> String? {
        var sums: [String: TimeInterval] = [:]
        var order: [String] = []
        for s in aways {
            guard let a = s.activity, let name = a.awayPlaceName ?? a.awayPlace.map(Copywriter.trackerAwayPlace) else { continue }
            if sums[name] == nil { order.append(name) }
            sums[name, default: 0] += s.length
        }
        return order.max { (sums[$0] ?? 0, $1) < (sums[$1] ?? 0, $0) }
    }
}
