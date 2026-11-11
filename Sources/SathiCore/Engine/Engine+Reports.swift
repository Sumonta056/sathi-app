import Foundation

extension Engine {
    package func streak(_ id: HabitID) -> Int {
        refreshStreakDay()
        if let cached = streakCache[id] { return cached }
        let value = streaks.current(
            id, goal: rules(id).dailyGoal, reset: streakReset(id), now: clock.now, isOn: isOn(id), load: loadStreakMonth
        )
        streakCache[id] = value
        return value
    }

    package func longestStreak(_ id: HabitID) -> Int {
        refreshStreakDay()
        if let cached = longestCache[id] { return cached }
        let value = streaks.longest(
            id, goal: rules(id).dailyGoal, reset: streakReset(id), now: clock.now, isOn: isOn(id), load: loadStreakMonth
        )
        longestCache[id] = value
        return value
    }

    package func report(_ range: ReportRange) -> Report {
        let n = clock.now
        let builder = ReportBuilder(calendar: calendar)
        let span = builder.interval(range, containing: n)
        let events = storedEvents(from: span.start, to: span.end)
        return builder.build(range, now: n, events: events, prefs: data.prefs)
    }

    func enabledHabits(_ prefs: Prefs) -> Set<HabitID> {
        Set(HabitID.allCases.filter { prefs.isEnabled($0) })
    }

    func streakInputsChanged(from old: Persisted) -> Bool {
        old.events != data.events || old.live.streakReset != data.live.streakReset
            || goals(old.prefs) != goals(data.prefs) || schedules(old.prefs) != schedules(data.prefs)
    }

    func clearStreakCache() {
        streakCache.removeAll()
        longestCache.removeAll()
        allStreakCache = nil
    }

    private var streaks: StreakCalculator { StreakCalculator(calendar: calendar) }

    private func goals(_ prefs: Prefs) -> [Double] {
        HabitID.allCases.map { $0.rules(prefs, calendar: calendar).dailyGoal }
    }

    private func schedules(_ prefs: Prefs) -> [HabitDays] {
        HabitID.allCases.map(prefs.days)
    }

    private func isOn(_ id: HabitID) -> (Date) -> Bool {
        let days = data.prefs.days(id)
        let calendar = calendar
        return { days.isOn($0, calendar: calendar) }
    }

    private func refreshStreakDay() {
        let today = calendar.startOfDay(for: clock.now)
        guard streakCacheDay != today else { return }
        clearStreakCache()
        streakCacheDay = today
    }

    private func streakReset(_ id: HabitID) -> Date? { data.live.streakReset[id.rawValue] }

    private func loadStreakMonth(_ month: DateInterval) -> [HistoryEvent] {
        guard month.start >= Self.windowStart(now: clock.now, calendar: calendar) else {
            return storedEvents(from: month.start, to: month.end)
        }
        return data.events.filter { month.start <= $0.date && $0.date < month.end }
    }
}

struct AllStreakCache {
    var day: Date
    var stores: Int
    var value: Int
}
