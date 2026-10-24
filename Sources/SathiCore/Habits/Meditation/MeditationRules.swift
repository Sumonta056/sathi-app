import Foundation

package struct MeditationRules: HabitRules {
    package let id = HabitID.meditation
    private let prefs: Prefs
    private let clock: DayClock

    package init(prefs: Prefs, calendar: Calendar = .current) {
        self.prefs = prefs
        clock = DayClock(calendar: calendar)
    }

    package var dailyGoal: Double { Double(prefs.meditation.sessionMinutes * prefs.meditation.slots.count) }

    package func nextDue(now: Date, lastDone: Date?, doneToday _: Double, skipToday: Bool) -> Date {
        let cal = clock.calendar
        let today = cal.startOfDay(for: now)
        if skipToday {
            let tomorrow = cal.date(byAdding: .day, value: 1, to: today) ?? now.addingTimeInterval(Timing.day)
            return nextSlot(after: tomorrow.addingTimeInterval(-Timing.second)) ?? .distantFuture
        }
        let base = lastDone.flatMap { cal.isDate($0, inSameDayAs: now) ? $0 : nil } ?? today.addingTimeInterval(-Timing.second)
        return nextSlot(after: base) ?? .distantFuture
    }

    package func nextSlot(after date: Date) -> Date? {
        let minutes = prefs.meditation.sortedSlots.map(\.minutes)
        guard !minutes.isEmpty else { return nil }
        let today = clock.calendar.startOfDay(for: date)
        let tomorrow = clock.calendar.date(byAdding: .day, value: 1, to: today) ?? date.addingTimeInterval(Timing.day)
        for day in [today, tomorrow] {
            for m in minutes {
                let slot = clock.at(m, on: day)
                if slot > date { return slot }
            }
        }
        return nil
    }

    package func isActiveTime(_: Date) -> Bool { true }

    package func nextActiveStart(after date: Date) -> Date { date }

    package func total(on day: Date, data: Persisted) -> Double {
        Stats(calendar: clock.calendar).total(id, on: day, in: data.events)
    }
}
