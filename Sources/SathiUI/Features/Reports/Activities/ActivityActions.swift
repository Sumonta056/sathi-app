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

@MainActor
extension ActivityDayActions {
    static func engine(_ engine: Engine) -> ActivityDayActions {
        var a = ActivityDayActions()
        a.edit = { engine.editActivity($0, $1) }
        a.add = { engine.addPastActivity($0) }
        a.delete = { engine.deleteActivity($0) }
        return a
    }
}

struct ActivityRangeActions {
    var openDay: (DayKey) -> Void = { _ in }
}
