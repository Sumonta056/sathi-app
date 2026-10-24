import Foundation

package struct WaterRules: HabitRules {
    package let id = HabitID.water
    private let prefs: Prefs
    private let clock: DayClock

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        clock = DayClock(calendar: calendar)
    }

    package var dailyGoal: Double { prefs.water.dailyGoalGlasses }

    package func nextDue(now: Date, lastDone: Date?, doneToday _: Double, skipToday _: Bool) -> Date {
        let candidate = (lastDone ?? now).addingTimeInterval(TimeInterval(prefs.water.intervalMinutes) * Timing.minute)
        let m = clock.minutesOfDay(candidate)
        if m < prefs.water.startMinutes {
            return clock.at(prefs.water.startMinutes, on: candidate)
        }
        if m >= prefs.water.endMinutes {
            return clock.at(prefs.water.startMinutes, on: candidate.addingTimeInterval(Timing.day))
        }
        return candidate
    }

    package func isActiveTime(_ date: Date) -> Bool {
        let m = clock.minutesOfDay(date)
        return m >= prefs.water.startMinutes && m < prefs.water.endMinutes
    }

    package func nextActiveStart(after date: Date) -> Date {
        let startToday = clock.at(prefs.water.startMinutes, on: date)
        return startToday > date ? startToday : clock.at(prefs.water.startMinutes, on: date.addingTimeInterval(Timing.day))
    }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }
}
