import Foundation

extension Engine {
    @discardableResult
    package func startActivity(fromEvent id: String) -> Bool {
        guard data.prefs.tracker.isOn, let e = calendarPageEventsByID[id] else { return false }
        if trackerCalendarRuntime.pendingAsk?.id == id { trackerCalendarRuntime.pendingAsk = nil }
        logEvent(e, at: clock.now.wholeSecond)
        requestTick()
        return true
    }
}
