import Foundation

extension Engine {
    var quickDeadlines: [Date] {
        quickReminders.compactMap { item in
            switch quickActivities[item.id] {
            case let .popup(_, deadline): return deadline == .distantFuture ? nil : deadline
            case .lock: return nil
            case nil: return item.fireDate
            }
        }
    }

    func tickQuick() {
        for item in quickReminders {
            if case let .popup(_, deadline) = quickActivities[item.id], now >= deadline { snoozeQuick(item.id) }
        }
        for item in quickReminders where quickActivities[item.id] == nil && now >= item.fireDate {
            presentQuick(item)
        }
    }

    private func presentQuick(_ item: QuickReminder) {
        switch EscalationPolicy.presentation(for: data.prefs.quick.strictness, snoozes: item.snoozes) {
        case let .bubble(level): showQuickPopup(item, level)
        case .lock: showQuickPopup(item, .persist)
        }
    }

    private func showQuickPopup(_ item: QuickReminder, _ level: Level) {
        quickActivities[item.id] = .popup(level, ignoreDeadline: freshQuickDeadline(item.id))
        presenter.showQuick(item.id, level)
        play(.ping)
    }

    private func freshQuickDeadline(_ id: UUID) -> Date {
        guard canSnoozeQuick(id) else { return .distantFuture }
        return clock.now.addingTimeInterval(TimeInterval(data.prefs.general.ignoreMinutes) * Timing.minute)
    }
}
