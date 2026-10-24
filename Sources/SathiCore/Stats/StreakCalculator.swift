import Foundation

package struct StreakCalculator: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar = .current) {
        self.calendar = .gregorian(in: calendar.timeZone)
    }

    package func current(
        _ id: HabitID,
        goal: Double,
        reset: Date?,
        now: Date,
        load: (DateInterval) -> [HistoryEvent]
    ) -> Int {
        guard goal > 0 else { return 0 }
        var totals = MonthlyTotals(id: id, reset: reset, calendar: calendar)
        var day = calendar.startOfDay(for: now)
        var count = totals.total(on: day, load: load) >= goal ? 1 : 0
        for _ in 1 ..< Limits.streakLookbackDays {
            day = calendar.previousDay(before: day)
            guard totals.total(on: day, load: load) >= goal else { break }
            count += 1
        }
        return count
    }

    package func longest(
        _ id: HabitID,
        goal: Double,
        reset: Date?,
        now: Date,
        load: (DateInterval) -> [HistoryEvent]
    ) -> Int {
        guard goal > 0 else { return 0 }
        var totals = MonthlyTotals(id: id, reset: reset, calendar: calendar)
        var best = 0
        var run = 0
        var day = calendar.stepDays(1 - Limits.longestStreakLookbackDays, from: now)
        for _ in 0 ..< Limits.longestStreakLookbackDays {
            defer { day = calendar.nextDay(after: day) }
            run = totals.total(on: day, load: load) >= goal ? run + 1 : 0
            best = max(best, run)
        }
        return best
    }
}

private struct MonthlyTotals {
    let id: HabitID
    let reset: Date?
    let calendar: Calendar
    private var months: [Date: [Date: Double]] = [:]

    init(id: HabitID, reset: Date?, calendar: Calendar) {
        self.id = id
        self.reset = reset
        self.calendar = calendar
    }

    mutating func total(on day: Date, load: (DateInterval) -> [HistoryEvent]) -> Double {
        guard let month = calendar.dateInterval(of: .month, for: day) else { return 0 }
        if let cached = months[month.start] { return cached[day] ?? 0 }
        let totals = dailyTotals(load(month))
        months[month.start] = totals
        return totals[day] ?? 0
    }

    private func dailyTotals(_ events: [HistoryEvent]) -> [Date: Double] {
        let after = reset ?? .distantPast
        var totals: [Date: Double] = [:]
        for e in events where e.habit == id && e.kind == .done && e.date > after {
            totals[calendar.startOfDay(for: e.date), default: 0] += e.amount
        }
        return totals
    }
}
