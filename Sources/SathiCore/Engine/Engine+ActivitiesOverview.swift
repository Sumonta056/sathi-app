import Foundation

extension Engine {
    package func activityDayOverview(_ range: StatsRange) -> ActivityDayOverview {
        let day = activityDay(DayKey(range.interval.start, calendar: calendar))
        return ActivityDayOverview(day, loggedChange: activityRange(range).realWorkChange)
    }
}
