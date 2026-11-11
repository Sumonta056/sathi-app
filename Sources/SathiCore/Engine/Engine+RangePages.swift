import Foundation

package struct ReportsPageData: Equatable {
    package let totals: [BuddyRangeTotal]
    package let bars: [GoalDayBar]
    package let stats: ActivityRangeStats
}

package struct ActivitiesPageData: Equatable {
    package let days: [ActivityDay]
    package let day: ActivityDay?
    package let stats: ActivityRangeStats?
}

extension Engine {
    package func reportsPage(_ range: StatsRange) -> ReportsPageData {
        let buddy = buddyRange(range)
        return ReportsPageData(totals: buddy.totals, bars: buddy.bars, stats: activityRange(range))
    }

    package func activitiesPage(_ range: StatsRange) -> ActivitiesPageData {
        let days = activityDays(in: range)
        guard range.kind != .day else {
            return ActivitiesPageData(days: days, day: activityDay(DayKey(range.interval.start, calendar: calendar)), stats: nil)
        }
        return ActivitiesPageData(days: days, day: nil, stats: activityRange(range, days: days))
    }
}
