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
        Binding(get: { self.data.prefs.gym.workout(at: index).name }, set: { name in
            self.editGymWorkout(at: index) { $0.name = name }
        })
    }

    func gymWorkoutMinutes(at index: Int) -> Binding<Int> {
        Binding(get: { self.data.prefs.gym.workout(at: index).minutes }, set: { minutes in
            self.editGymWorkout(at: index) { $0.minutes = minutes }
        })
    }

    private func editGymWorkout(at index: Int, _ change: (inout GymWorkout) -> Void) {
        var workouts = GymPrefs.cleaned(data.prefs.gym.workouts)
        guard workouts.indices.contains(index) else { return }
        change(&workouts[index])
        data.prefs.gym.workouts = GymPrefs.cleaned(workouts)
    }
}
