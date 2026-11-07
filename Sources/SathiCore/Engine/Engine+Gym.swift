import Foundation

extension Engine {
    package var gymWorkoutIndex: Int {
        let today = calendar.startOfDay(for: clock.now)
        let done = data.events.count { $0.habit == .gym && $0.kind == .done && calendar.startOfDay(for: $0.date) == today }
        return (done + gymIdea) % GymIdeas.cleaned(data.prefs.gym.ideas).count
    }

    package var gymIdeaText: String {
        data.prefs.gym.idea(at: session(.gym)?.workout ?? gymWorkoutIndex)
    }

    package func nextGymIdea() {
        guard case .bubble = activities[.gym] else { return }
        gymIdea += 1
    }

    func resetsIdea(_ id: HabitID) -> Bool {
        switch id {
        case .water, .reading, .meditation: return false
        case .gym: return true
        }
    }
}

extension Engine {
    package var gymProgress: GymProgress {
        GymProgress(prefs: data.prefs.gym, doneMinutes: rules(.gym).total(on: clock.now, data: data))
    }
}
