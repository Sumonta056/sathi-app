import Foundation

package struct ActivitiesPageData: Equatable {
    package let days: [ActivityDay]
    package let day: ActivityDay?
    package let stats: ActivityRangeStats?
}

extension Engine {
    package func activitiesPage(_ range: StatsRange) -> ActivitiesPageData {
        let days = activityDays(in: range)
        guard range.kind != .day else {
            return ActivitiesPageData(days: days, day: activityDay(DayKey(range.interval.start, calendar: calendar)), stats: nil)
        }
        return ActivitiesPageData(days: days, day: nil, stats: activityRange(range, days: days))
    }
}
