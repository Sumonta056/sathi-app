import Foundation

extension Engine {
    package func isOffToday(_ id: HabitID) -> Bool {
        !data.prefs.days(id).isOn(clock.now, calendar: calendar)
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
