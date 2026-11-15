import Foundation

extension Engine {
    static func initialHabits(_ loaded: Persisted, now n: Date, calendar: Calendar) -> [HabitID: HabitState] {
        Dictionary(uniqueKeysWithValues: HabitID.allCases.map { id in
            let r = id.rules(loaded.prefs, calendar: calendar)
            let due = r.nextDue(
                now: n,
                lastDone: loaded.lastDone(id),
                doneToday: r.total(on: n, data: loaded),
                skipToday: Self.skipped(id, on: n, live: loaded.live, calendar: calendar)
            )
            return (id, HabitState(nextDue: due))
        })
    }
}
