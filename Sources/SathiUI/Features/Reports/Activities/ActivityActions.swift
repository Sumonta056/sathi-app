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
    var mergeCheck: (Set<ActivityID>) -> ManualMergeCheck = { _ in .blocked(.tooFew) }
    var merge: (Set<ActivityID>) -> ManualMergeResult = { _ in .blocked(.tooFew) }
    var undoMerge: () -> ManualMergeUndoResult = { .gone }
    var clearMergeUndo: () -> Void = {}
}

struct ActivityRangeActions {
    var openDay: (DayKey) -> Void = { _ in }
}
