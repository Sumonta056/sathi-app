import SathiCore
import SwiftUI

extension Engine {
    func enabledBinding(_ id: HabitID) -> Binding<Bool> {
        Binding(get: { self.data.prefs.isEnabled(id) }, set: { self.setEnabled(id, $0) })
    }

    private func setEnabled(_ id: HabitID, _ on: Bool) {
        switch id {
        case .water: data.prefs.water.enabled = on
        case .reading: data.prefs.reading.enabled = on
        case .meditation: data.prefs.meditation.enabled = on
        case .gym: data.prefs.gym.enabled = on
        }
    }
}

extension Engine {
    func gymWorkoutName(at index: Int) -> Binding<String> {
        Binding(get: { self.gymRow(index)?.name ?? "" }, set: { name in
            self.editGymRow(index) { $0.name = String(name.prefix(Limits.gymNameMaxLength)) }
        })
    }

    func gymWorkoutMinutes(at index: Int) -> Binding<Int> {
        Binding(get: { self.data.prefs.gym.workout(at: index).minutes }, set: { minutes in
            self.editGymRow(index) { $0.minutes = minutes }
        })
    }

    func commitGymWorkoutNames() {
        let cleaned = GymPrefs.cleaned(data.prefs.gym.workouts)
        if cleaned != data.prefs.gym.workouts { data.prefs.gym.workouts = cleaned }
    }

    private func gymRow(_ index: Int) -> GymWorkout? {
        let rows = data.prefs.gym.workouts
        return rows.indices.contains(index) ? rows[index] : nil
    }

    private func editGymRow(_ index: Int, _ change: (inout GymWorkout) -> Void) {
        guard data.prefs.gym.workouts.indices.contains(index) else { return }
        change(&data.prefs.gym.workouts[index])
    }
}

extension Engine {
    func weekdays(_ id: HabitID) -> Binding<Set<Weekday>> {
        Binding(get: { self.data.prefs.days(id).weekdays }, set: { days in
            var d = self.data.prefs.days(id)
            d.weekdays = days
            self.data.prefs.setDays(id, d)
        })
    }
}
