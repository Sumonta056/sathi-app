import Foundation

struct TrackerRuntime: Equatable {
    var shownPrompt: PromptKind?
    var endOfDayShowing = false
    var presenceStarted = false
    var registeredShortcut: KeyShortcut?
    var reportDay: DayKey?
    var promptByUser = false
    var sessionTimedOut = false
    var whatNowAt: Date?
    var screenLocked = false
    var asleep = false
    var lastAway: AwaySpan?
    var awayItems: [ActivityID] = []
    var endedByAway: RunningActivity?
    var loggedWhileAway: [Activity] = []
}
