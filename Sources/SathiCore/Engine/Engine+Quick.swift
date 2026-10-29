import Foundation

extension Engine {
    package var quickReminders: [QuickReminder] { data.live.quickReminders }

    package func quick(_ id: UUID) -> QuickReminder? {
        quickReminders.first { $0.id == id }
    }

    package func quickDate(_ t: QuickTime) -> Date {
        t.date(now: clock.now, calendar: calendar)
    }

    @discardableResult
    package func addQuick(text: String, when: QuickTime) -> QuickAddResult {
        let clean = QuickText.clean(text)
        guard !clean.isEmpty else { return .empty }
        guard quickReminders.count < Limits.quickMax else { return .full }
        let item = QuickReminder(text: clean, due: quickDate(when), createdAt: clock.now.wholeSecond)
        data.live.quickReminders = (quickReminders + [item]).kept()
        requestTick()
        return .added(item.id)
    }

    package func removeQuick(_ id: UUID) {
        closeQuickActivity(id)
        data.live.quickReminders.removeAll { $0.id == id }
        requestTick()
    }

    package func quickDone(_ id: UUID) {
        removeQuick(id)
    }

    package func snoozeQuick(_ id: UUID) {
        guard let item = quick(id), canSnoozeQuick(id) else { return }
        let until = clock.now.addingTimeInterval(TimeInterval(data.prefs.general.snoozeMinutes) * Timing.minute).wholeSecond
        var changed = item
        changed.snoozes += 1
        changed.snoozedUntil = until
        data.live.quickReminders = quickReminders.map { $0.id == id ? changed : $0 }.kept()
        closeQuickActivity(id)
        presenter.showQuickSnoozed(text: item.text, until: until)
        requestTick()
    }

    package func canSnoozeQuick(_ id: UUID) -> Bool {
        guard let item = quick(id) else { return false }
        return data.prefs.general.snoozeLimit.map { item.snoozes < $0 } ?? true
    }

    package func showsQuickClose(_ id: UUID) -> Bool {
        guard case .popup(.nudge, _) = quickActivities[id] else { return false }
        return data.prefs.quick.showsCloseButton && canSnoozeQuick(id)
    }

    func closeQuickActivity(_ id: UUID) {
        switch quickActivities[id] {
        case .popup: presenter.closeQuick(id)
        case .lock: presenter.closeLock()
        case nil: return
        }
        quickActivities[id] = nil
    }
}
