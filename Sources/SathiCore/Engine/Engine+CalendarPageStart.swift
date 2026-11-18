import Foundation

extension Engine {
    @discardableResult
    package func startActivity(fromEvent id: String) -> Bool {
        guard let e = calendarPageEventsByID[id],
              CalendarEventStart.allows(e, now: clock.now, trackerOn: data.prefs.tracker.isOn) else { return false }
        if trackerCalendarRuntime.pendingAsk?.id == id { trackerCalendarRuntime.pendingAsk = nil }
        logEvent(e, at: clock.now.wholeSecond)
        requestTick()
        return true
    }
}
