import Foundation

package struct TrackerNoteActions {
    package var undo: @MainActor () -> Void = {}
    package var notAttending: @MainActor () -> Void = {}
    package var pickCategory: @MainActor (String) -> Void = { _ in }
    package var switchToEvent: @MainActor () -> Void = {}

    package init() {}
}

package struct TrackerNoteState {
    package var note: TrackerNote
    package var calendarTitle: String?
    package var category: String?
    package var categories: [ActivityCategory] = []
    package var endedText: String?
    package var calendar: Calendar = .current
    package var actions = TrackerNoteActions()

    package init(note: TrackerNote, calendarTitle: String?, category: String?) {
        self.note = note
        self.calendarTitle = calendarTitle
        self.category = category
    }
}
