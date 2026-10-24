import Foundation

package struct Stats: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    package func total(_ id: HabitID, on day: Date, in events: [HistoryEvent]) -> Double {
        events.reduce(0) { sum, e in
            e.habit == id && e.kind == .done && calendar.isDate(e.date, inSameDayAs: day) ? sum + e.amount : sum
        }
    }

    package func streak(_ id: HabitID, data: Persisted, now: Date) -> Int {
        let totals = dailyTotals(id, data: data)
        let goal = id.rules(data.prefs, calendar: calendar).dailyGoal
        func met(_ day: Date) -> Bool { (totals[day] ?? 0) >= goal }

        var day = calendar.startOfDay(for: now)
        var count = met(day) ? 1 : 0
        for _ in 0 ..< Limits.streakLookbackDays {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
            if met(day) { count += 1 } else { break }
        }
        return count
    }

    private func dailyTotals(_ id: HabitID, data: Persisted) -> [Date: Double] {
        let reset = data.live.streakReset[id.rawValue] ?? .distantPast
        var totals: [Date: Double] = [:]
        for e in data.events where e.habit == id && e.kind == .done && e.date > reset {
            totals[calendar.startOfDay(for: e.date), default: 0] += e.amount
        }
        return totals
    }
}
