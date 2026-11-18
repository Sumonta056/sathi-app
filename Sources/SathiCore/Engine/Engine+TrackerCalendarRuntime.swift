import Foundation

struct TrackerCalendarRuntime: Equatable {
    var events: [CalendarEventInfo] = []
    var readAt: Date?
    var note: TrackerNote?
    var noteUntil: Date?
    var readKey: [String] = []
    var calendars: [CalendarChoice] = []
    var checkedUntil: Date?
    var dismissed: Set<String> = []
    var undo: RunningActivity?
    var pendingAsk: CalendarEventInfo?
    var heldPrompt: PromptState?
    var heldByUser = false
}
