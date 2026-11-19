import Foundation

extension Engine {
    func todaySoFar(_ n: Date) -> TodaySoFar {
        guard trackerPrefs.isOn else { return .off }
        var day = activityDay(DayKey(n, calendar: calendar))
        if let r = runningActivity, let shown = day.running {
            day.running = r.activity(until: max(r.start, min(n, shown.end)))
        }
        let stats = ActivityDayStats(day)
        return TodaySoFar(
            isOn: true, hours: day.hours, segments: stats.segments, logged: stats.realWork,
            categories: Array(stats.categories.prefix(Limits.todayCategoryRows)),
            away: stats.awayTotals,
            change: todaySoFarChange(stats.realWork, now: n)
        )
    }

    private func todaySoFarChange(_ logged: TimeInterval, now n: Date) -> RangeChange {
        let cut = StatsRange.containing(n, kind: .day, calendar: calendar).comparable(now: n, calendar: calendar)
        var day = activityDay(DayKey(cut.start, calendar: calendar))
        day.hours = DateInterval(start: day.hours.start, end: max(day.hours.start, min(day.hours.end, cut.end)))
        let before = ActivityDayStats(day).realWork
        return RangeChange(current: logged, previous: before, hasData: before > 0)
    }
}
