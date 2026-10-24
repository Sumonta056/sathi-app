import Foundation

package struct ReadingRules: HabitRules {
    package let id = HabitID.reading
    private let prefs: Prefs
    private let clock: DayClock

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        clock = DayClock(calendar: calendar)
    }

    package var dailyGoal: Double { Double(prefs.readingSessionMinutes) }

    package func nextDue(now: Date, lastDone _: Date?, doneToday: Double, skipToday: Bool) -> Date {
        if skipToday || doneToday >= dailyGoal {
            return clock.at(prefs.readingTimeMinutes, on: now.addingTimeInterval(Timing.day))
        }
        return clock.at(prefs.readingTimeMinutes, on: now)
    }

    package func isActiveTime(_: Date) -> Bool { true }

    package func nextActiveStart(after date: Date) -> Date { date }

    package func total(on day: Date, data: Persisted) -> Double {
        Double(Stats(calendar: clock.calendar).readMinutes(on: day, in: data.reads))
    }
}
