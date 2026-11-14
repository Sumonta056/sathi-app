import Foundation

extension Engine {
    package func calendarPageOpened() {
        if !calendarPageOpen {
            calendarPageOpen = true
            calendarChanges.start { [weak self] in self?.calendarStoreChanged() }
        }
        refreshCalendarAccess()
        storesChanged()
    }

    package func calendarPageClosed() {
        guard calendarPageOpen else { return }
        calendarPageOpen = false
        calendarChanges.stop()
    }

    func calendarStoreChanged() {
        guard calendarPageOpen else { return }
        refreshCalendarChoices()
        markTrackerEventsStale()
        storesChanged()
        requestTick()
    }

    func markTrackerEventsStale() {
        trackerCalendarRuntime.readAt = nil
    }
}
