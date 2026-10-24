import Foundation

package struct Stats: Sendable {
    package var calendar: Calendar

    package init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    package func glasses(on day: Date, in drinks: [DrinkEntry]) -> Double {
        drinks.reduce(0) { calendar.isDate($1.date, inSameDayAs: day) ? $0 + $1.glasses : $0 }
    }

    package func readMinutes(on day: Date, in reads: [ReadEntry]) -> Int {
        reads.reduce(0) { calendar.isDate($1.date, inSameDayAs: day) ? $0 + $1.minutes : $0 }
    }

    package func streak(_ id: HabitID, data: Persisted, now: Date) -> Int {
        let totals = dailyTotals(id, data: data)
        let goal = id == .water ? data.prefs.dailyGoalGlasses : Double(data.prefs.readingSessionMinutes)
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
        let reset = data.streakReset[id.rawValue] ?? .distantPast
        var totals: [Date: Double] = [:]
        switch id {
        case .water:
            for entry in data.drinks where entry.date > reset {
                totals[calendar.startOfDay(for: entry.date), default: 0] += entry.glasses
            }
        case .reading:
            for entry in data.reads where entry.date > reset {
                totals[calendar.startOfDay(for: entry.date), default: 0] += Double(entry.minutes)
            }
        }
        return totals
    }
}
