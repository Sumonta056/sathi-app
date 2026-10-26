import Foundation

extension Engine {
    package var gymWorkoutIndex: Int {
        let done = Int(rules(.gym).total(on: clock.now, data: data))
        return (done + gymIdea) % Limits.gymWorkoutCount
    }

    package var gymWorkout: GymWorkout {
        if let index = session(.gym)?.workout { return data.prefs.gym.workout(at: index) }
        return data.prefs.gym.workout(at: gymWorkoutIndex)
    }

    package func nextGymIdea() {
        guard case .bubble = activities[.gym] else { return }
        gymIdea += 1
    }

    package func notNow(_ id: HabitID) {
        guard case .bubble = activities[id] else { return }
        let n = clock.now
        record(.snooze(id, at: n))
        presenter.closeBubble(id)
        activities[id] = nil
        let due = freshDue(id, lastDone: n)
        habits[id] = HabitState(nextDue: due)
        if usesCorner(id) { presenter.showSnoozed(id, until: due) }
        requestTick()
    }

    func ignoreGoesToNextInterval(_ id: HabitID) -> Bool {
        switch id {
        case .water, .reading, .meditation: return false
        case .gym: return true
        }
    }

    func resetsIdea(_ id: HabitID) -> Bool {
        switch id {
        case .water, .reading, .meditation: return false
        case .gym: return true
        }
    }
}
