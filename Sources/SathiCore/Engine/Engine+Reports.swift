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

    @discardableResult
    package func export(_ format: ExportFormat, to exporter: FileExporter) -> Bool {
        let events = history.allEvents()
        let n = clock.now.wholeSecond
        let payload: Data = switch format {
        case .csv: Data(CSVExporter.csv(events, timeZone: calendar.timeZone).utf8)
        case .json: JSONExporter.backup(prefs: data.prefs, live: data.live, events: events, exportedAt: n)
        }
        return exporter.save(payload, suggestedName: ExportNames.fileName(format, on: n, calendar: calendar), format: format)
    }

    func streakInputsChanged(from old: Persisted) -> Bool {
        old.events != data.events || old.live.streakReset != data.live.streakReset || goals(old.prefs) != goals(data.prefs)
    }

    func clearStreakCache() {
        streakCache.removeAll()
        longestCache.removeAll()
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
