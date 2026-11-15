import Foundation

extension Engine {
    var trackerWantsCalendarChanges: Bool { isRunning && trackerPrefs.isOn && readsCalendarEvents }

    package func calendarPageOpened() {
        if !calendarPageOpen {
            calendarPageOpen = true
            syncCalendarChangeListener()
        }
        refreshCalendarAccess()
        refreshTodos()
        storesChanged()
    }

    package func calendarPageClosed() {
        guard calendarPageOpen else { return }
        calendarPageOpen = false
        calendarPageRead = nil
        calendarPageEventsByID = [:]
        activityStore.releaseUnused()
        syncCalendarChangeListener()
    }

    func syncCalendarChangeListener() {
        let wants = calendarPageOpen || trackerWantsCalendarChanges || todosWantChanges
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
        todosStoreChanged()
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
