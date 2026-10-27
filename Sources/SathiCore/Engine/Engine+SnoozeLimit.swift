import Foundation

extension Engine {
    package func snoozesLeft(_ id: HabitID) -> Int? {
        data.prefs.general.snoozeLimit.map { max(0, $0 - state(id).snoozes) }
    }

    package func canSnooze(_ id: HabitID) -> Bool {
        snoozesLeft(id).map { $0 > 0 } ?? true
    }

    func freshIgnoreDeadline(_ id: HabitID) -> Date {
        guard canSnooze(id) else { return .distantFuture }
        return clock.now.addingTimeInterval(TimeInterval(data.prefs.general.ignoreMinutes) * Timing.minute)
    }

    func lockWaitingHabit() {
        let ids = HabitID.allCases
        guard !ids.contains(where: { phase($0) == .lock }) else { return }
        let waiting = ids.first { id in
            guard case .bubble = activities[id], !canSnooze(id) else { return false }
            return EscalationPolicy.presentation(for: strictness(id), snoozes: state(id).snoozes) == .lock
        }
        guard let id = waiting else { return }
        presenter.closeBubble(id)
        showLock(id)
    }

    func refreshIgnoreDeadlines() {
        for id in HabitID.allCases {
            guard case let .bubble(level, copy, deadline) = activities[id],
                  canSnooze(id) == (deadline == .distantFuture) else { continue }
            activities[id] = .bubble(level, copy: copy, ignoreDeadline: freshIgnoreDeadline(id))
        }
        requestTick()
    }
}
