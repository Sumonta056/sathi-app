import Foundation

extension Engine {
    @discardableResult
    package func startActivity(fromEvent id: String) -> Bool {
        guard let e = calendarPageEventsByID[id],
              CalendarEventStart.allows(e, now: clock.now, trackerOn: data.prefs.tracker.isOn) else { return false }
        dropEventAsk(id)
        logEvent(e, at: clock.now.wholeSecond)
        requestTick()
        return true
    }
}
