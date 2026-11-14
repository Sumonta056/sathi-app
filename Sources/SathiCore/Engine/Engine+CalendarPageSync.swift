import Foundation

extension Engine {
    var trackerWantsCalendarChanges: Bool { isRunning && trackerPrefs.isOn && readsCalendarEvents }

    package func calendarPageOpened() {
        if !calendarPageOpen {
            calendarPageOpen = true
            syncCalendarChangeListener()
        }
        refreshCalendarAccess()
        storesChanged()
    }

    package func calendarPageClosed() {
        guard calendarPageOpen else { return }
        calendarPageOpen = false
        syncCalendarChangeListener()
    }

    func syncCalendarChangeListener() {
        let wants = calendarPageOpen || trackerWantsCalendarChanges
        guard wants != calendarChangesListening else { return }
        calendarChangesListening = wants
        if wants {
            calendarChanges.start { [weak self] in self?.calendarStoreChanged() }
        } else {
            calendarChanges.stop()
        }
    }

    func calendarStoreChanged() {
        markTrackerEventsStale()
        if calendarPageOpen {
            refreshCalendarChoices()
            storesChanged()
        }
        requestTick()
    }

    func markTrackerEventsStale() {
        trackerCalendarRuntime.readAt = nil
    }
}
