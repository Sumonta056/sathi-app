import AppKit
import SathiCore

enum ActivityPasteboard {
    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct ActivityDayActions {
    var edit: (ActivityID, ActivityEdit) -> ActivityEditResult = { _, _ in .notFound }
    var add: (ActivityEdit) -> ActivityEditResult = { _ in .notFound }
    var delete: (ActivityID) -> Void = { _ in }
    var saveToCalendar: (ActivityID) -> Void = { _ in }
    var copy: (String) -> Void = ActivityPasteboard.copy
}

struct ActivityRangeActions {
    var openDay: (DayKey) -> Void = { _ in }
    var copy: (String) -> Void = ActivityPasteboard.copy
}
