import Foundation

package struct ReadingRules: HabitRules {
    package let id = HabitID.reading
    private let prefs: Prefs
    private let clock: DayClock

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        clock = DayClock(calendar: calendar)
    }

    package var dailyGoal: Double { Double(prefs.reading.sessionMinutes) }

    package func nextDue(now: Date, lastDone _: Date?, doneToday: Double, skipToday: Bool) -> Date {
        if skipToday || doneToday >= dailyGoal {
            let tomorrow = clock.calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(Timing.day)
            return clock.at(prefs.reading.timeMinutes, on: tomorrow)
        }
        return clock.at(prefs.reading.timeMinutes, on: now)
    }

    package func isActiveTime(_: Date) -> Bool { true }

    package func nextActiveStart(after date: Date) -> Date { date }

    package func nextSlot(after date: Date) -> Date? {
        let today = clock.at(prefs.reading.timeMinutes, on: date)
        if today > date { return today }
        let tomorrow = clock.calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(Timing.day)
        return clock.at(prefs.reading.timeMinutes, on: tomorrow)
    }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }
}
