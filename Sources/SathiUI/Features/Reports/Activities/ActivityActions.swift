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
    var delete: (ActivityID) -> Bool = { _ in true }
}

struct ActivityRangeActions {
    var openDay: (DayKey) -> Void = { _ in }
}
