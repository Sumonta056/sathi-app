import Foundation

extension Engine {
    package func isOffToday(_ id: HabitID) -> Bool {
        !data.prefs.days(id).isOn(clock.now, calendar: calendar)
    }

    package func upcomingDaysOff(_ id: HabitID) -> [DayKey] {
        data.prefs.days(id).upcoming(from: clock.now, calendar: calendar)
    }

    package var timeZone: TimeZone { calendar.timeZone }

    package var dayOffRange: ClosedRange<Date> {
        HabitDays.dayOffRange(now: clock.now, calendar: calendar)
    }

    package func addDayOff(_ id: HabitID, _ date: Date) {
        let d = data.prefs.days(id)
        let next = d.addingDayOff(date, now: clock.now, calendar: calendar)
        if next != d { data.prefs.setDays(id, next) }
    }

    package func removeDayOff(_ id: HabitID, _ key: DayKey) {
        var d = data.prefs.days(id)
        guard d.daysOff.remove(key) != nil else { return }
        data.prefs.setDays(id, d)
    }

    func turnedOffToday(from old: Prefs) -> [HabitID] {
        let n = clock.now
        return HabitID.allCases.filter { old.days($0).isOn(n, calendar: calendar) && isOffToday($0) }
    }

    func closeReminders(_ ids: [HabitID]) {
        for id in ids where showsReminder(id) {
            close(id)
        }
    }

    private func showsReminder(_ id: HabitID) -> Bool {
        switch activities[id] {
        case .bubble, .lock: return true
        case .session, nil: return false
        }
    }
}
