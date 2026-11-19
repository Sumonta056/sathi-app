import Foundation

struct YesterdayWorkCache {
    var day: DayKey
    var stores: Int
    var hours: DateInterval
    var running: Date?
    var work: [DateInterval]
}

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
            categories: stats.categories,
            away: stats.awayTotals,
            change: todaySoFarChange(stats.realWork, now: n)
        )
    }

    private func todaySoFarChange(_ logged: TimeInterval, now n: Date) -> RangeChange {
        let cut = StatsRange.containing(n, kind: .day, calendar: calendar).comparable(now: n, calendar: calendar)
        let before = yesterdayWork(DayKey(cut.start, calendar: calendar)).reduce(0) { sum, span in
            sum + max(0, min(span.end, cut.end).timeIntervalSince(span.start))
        }
        return RangeChange(current: logged, previous: before, hasData: logged > 0 || before > 0)
    }

    private func yesterdayWork(_ key: DayKey) -> [DateInterval] {
        let hours = trackerHours.hours(on: key.start(in: calendar))
        let running = data.live.tracker.running?.start
        if let c = yesterdayWorkCache, c.day == key, c.stores == storeRevision, c.hours == hours, c.running == running {
            return c.work
        }
        let work = ActivityDayStats(activityDay(key)).segments.filter { $0.kind == .work }.map(\.interval)
        yesterdayWorkCache = YesterdayWorkCache(day: key, stores: storeRevision, hours: hours, running: running, work: work)
        return work
    }
}
