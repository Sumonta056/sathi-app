import Foundation

package struct Scheduler: Sendable {
    package var prefs: Prefs
    package var calendar: Calendar

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        self.calendar = calendar
    }

    package func at(_ minutes: Int, on day: Date) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: calendar.startOfDay(for: day)) ?? day
    }

    package func minutesOfDay(_ date: Date) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    package func inWaterHours(_ date: Date) -> Bool {
        let m = minutesOfDay(date)
        return m >= prefs.waterStartMinutes && m < prefs.waterEndMinutes
    }

    package func nextWaterDue(after base: Date) -> Date {
        let candidate = base.addingTimeInterval(TimeInterval(prefs.waterIntervalMinutes) * Timing.minute)
        let m = minutesOfDay(candidate)
        if m < prefs.waterStartMinutes {
            return at(prefs.waterStartMinutes, on: candidate)
        }
        if m >= prefs.waterEndMinutes {
            return at(prefs.waterStartMinutes, on: candidate.addingTimeInterval(Timing.day))
        }
        return candidate
    }

    package func nextReadingDue(now: Date, readToday: Int, skipToday: Bool) -> Date {
        if skipToday || readToday >= prefs.readingSessionMinutes {
            return at(prefs.readingTimeMinutes, on: now.addingTimeInterval(Timing.day))
        }
        return at(prefs.readingTimeMinutes, on: now)
    }

    package func nextWaterStart(after now: Date) -> Date {
        let startToday = at(prefs.waterStartMinutes, on: now)
        return startToday > now ? startToday : at(prefs.waterStartMinutes, on: now.addingTimeInterval(Timing.day))
    }
}
