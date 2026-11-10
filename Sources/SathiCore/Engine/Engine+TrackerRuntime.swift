import Foundation

struct TrackerRuntime: Equatable {
    var shownPrompt: PromptKind?
    var endOfDayShowing = false
    var endOfDayDay: DayKey?
    var endOfDayDue: DayKey?
    var presenceStarted = false
    var registeredShortcut: KeyShortcut?
    var reportDay: DayKey?
    var promptByUser = false
    var sessionTimedOut = false
    var whatNowAt: Date?
    var screenLocked = false
    var asleep = false
    var away = TrackerAwayDetails()

    var lastAway: AwaySpan? {
        get { away.lastAway }
        set { away.lastAway = newValue }
    }

    var awayItems: [ActivityID] {
        get { away.awayItems }
        set { away.awayItems = newValue }
    }

    var endedByAway: RunningActivity? {
        get { away.endedByAway }
        set { away.endedByAway = newValue }
    }

    var loggedWhileAway: [Activity] {
        get { away.loggedWhileAway }
        set { away.loggedWhileAway = newValue }
    }
}

extension Engine {
    func syncAwayDetails() {
        guard data.live.tracker.away != trackerRuntime.away else { return }
        data.live.tracker.away = trackerRuntime.away
    }
}
