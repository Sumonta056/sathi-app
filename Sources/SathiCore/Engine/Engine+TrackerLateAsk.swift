import Foundation

extension Engine {
    var lateStillOnItAt: Date? {
        guard let p = data.live.tracker.prompt, p.kind == .stillOnIt,
              trackerCalendarRuntime.lateShownFor != p.shownAt else { return nil }
        return p.shownAt.addingTimeInterval(Timing.lateAnswer)
    }

    func showStillOnItLate(_ n: Date) {
        guard let at = lateStillOnItAt, n >= at, let p = data.live.tracker.prompt,
              trackerRuntime.shownPrompt == .stillOnIt else { return }
        trackerCalendarRuntime.lateShownFor = p.shownAt
        presenter.showTrackerPrompt(.stillOnIt)
    }

    func logAskedEvent(_ e: CalendarEventInfo) {
        let start = e.start.wholeSecond
        if let r = data.live.tracker.running, r.start > start { endRunningActivity(at: start) }
        logEvent(e, at: start)
        makeRoomForEvent(e)
        removeWorkInside(e)
    }

    private func removeWorkInside(_ e: CalendarEventInfo) {
        let start = e.start.wholeSecond
        let end = min(e.end, clock.now)
        for item in storedActivities(on: e.start) where item.kind == .work && item.start >= start && item.start < end {
            if let removed = removeStoredActivity(item.id) { calendarActivityDeleted(removed) }
        }
    }
}
