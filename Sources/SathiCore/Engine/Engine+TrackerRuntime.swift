import Foundation

struct TrackerRuntime: Equatable {
    var shownPrompt: PromptKind?
    var endOfDayShowing = false
    var presenceStarted = false
    var registeredShortcut: KeyShortcut?
    var reportDay: DayKey?
}
