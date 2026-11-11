import Foundation

extension Engine {
    package func activityDayOverview(_ range: StatsRange) -> ActivityDayOverview {
        let day = activityDay(DayKey(range.interval.start, calendar: calendar))
        return ActivityDayOverview(
            day, loggedChange: activityRange(range).realWorkChange,
            now: clock.now, isTrackerDay: trackerHours.isTrackerDay(range.interval.start)
        )
    }
}

extension Engine {
    package var activityCalendarTitles: [String: String] {
        let all = trackerCalendarRuntime.calendars + calendarChoices()
        return Dictionary(all.map { ($0.id, $0.title) }, uniquingKeysWith: { _, writable in writable })
    }
}
