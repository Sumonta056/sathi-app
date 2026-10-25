import Foundation

extension Engine {
    package func streak(_ id: HabitID) -> Int {
        refreshStreakDay()
        if let cached = streakCache[id] { return cached }
        let value = streaks.current(id, goal: rules(id).dailyGoal, reset: streakReset(id), now: clock.now, load: loadStreakMonth)
        streakCache[id] = value
        return value
    }

    package func longestStreak(_ id: HabitID) -> Int {
        refreshStreakDay()
        if let cached = longestCache[id] { return cached }
        let value = streaks.longest(id, goal: rules(id).dailyGoal, reset: streakReset(id), now: clock.now, load: loadStreakMonth)
        longestCache[id] = value
        return value
    }

    package func report(_ range: ReportRange) -> Report {
        let n = clock.now
        let builder = ReportBuilder(calendar: calendar)
        let span = builder.interval(range, containing: n)
        let events = history.events(from: span.start, to: span.end)
        return builder.build(range, now: n, events: events, prefs: data.prefs)
    }

    package func reportScreen(_ range: ReportRange, selected: HabitID) -> ReportScreen {
        let key = ReportScreenCache.Key(range: range, selected: selected, day: calendar.startOfDay(for: clock.now))
        if let cache = reportCache, cache.key == key { return cache.screen }
        let enabled = enabledHabits(data.prefs)
        let habit = ReportScreenBuilder.resolve(selected, enabled: enabled)
        let screen = ReportScreenBuilder(calendar: calendar).build(ReportScreenInput(
            range: range,
            selected: selected,
            report: report(range),
            month: report(.month),
            enabled: enabled,
            streak: streak(habit),
            longest: longestStreak(habit),
            now: clock.now
        ))
        reportCache = ReportScreenCache(key: key, screen: screen)
        return screen
    }

    func enabledHabits(_ prefs: Prefs) -> Set<HabitID> {
        Set(HabitID.allCases.filter { prefs.isEnabled($0) })
    }

    func streakInputsChanged(from old: Persisted) -> Bool {
        old.events != data.events || old.live.streakReset != data.live.streakReset || goals(old.prefs) != goals(data.prefs)
    }

    func clearStreakCache() {
        streakCache.removeAll()
        longestCache.removeAll()
        reportCache = nil
    }

    private var streaks: StreakCalculator { StreakCalculator(calendar: calendar) }

    private func goals(_ prefs: Prefs) -> [Double] {
        HabitID.allCases.map { $0.rules(prefs, calendar: calendar).dailyGoal }
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
            return history.events(from: month.start, to: month.end)
        }
        return data.events.filter { month.start <= $0.date && $0.date < month.end }
    }
}

struct ReportScreenCache {
    struct Key: Equatable {
        var range: ReportRange
        var selected: HabitID
        var day: Date
    }

    var key: Key
    var screen: ReportScreen
}
