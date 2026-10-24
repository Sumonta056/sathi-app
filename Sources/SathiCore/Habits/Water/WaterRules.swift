import Foundation

package struct WaterRules: HabitRules {
    package let id = HabitID.water
    private let prefs: Prefs
    private let clock: DayClock

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        clock = DayClock(calendar: calendar)
    }

    package var dailyGoal: Double { prefs.dailyGoalGlasses }

    package func nextDue(now: Date, lastDone: Date?, doneToday _: Double, skipToday _: Bool) -> Date {
        let candidate = (lastDone ?? now).addingTimeInterval(TimeInterval(prefs.waterIntervalMinutes) * Timing.minute)
        let m = clock.minutesOfDay(candidate)
        if m < prefs.waterStartMinutes {
            return clock.at(prefs.waterStartMinutes, on: candidate)
        }
        if m >= prefs.waterEndMinutes {
            return clock.at(prefs.waterStartMinutes, on: candidate.addingTimeInterval(Timing.day))
        }
        return candidate
    }

    package func isActiveTime(_ date: Date) -> Bool {
        let m = clock.minutesOfDay(date)
        return m >= prefs.waterStartMinutes && m < prefs.waterEndMinutes
    }

    package func nextActiveStart(after date: Date) -> Date {
        let startToday = clock.at(prefs.waterStartMinutes, on: date)
        return startToday > date ? startToday : clock.at(prefs.waterStartMinutes, on: date.addingTimeInterval(Timing.day))
    }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).glasses(on: day, in: data.drinks)
    }
}
