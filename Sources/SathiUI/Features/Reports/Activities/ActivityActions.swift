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

@MainActor
extension ActivityDayActions {
    static func engine(_ engine: Engine) -> ActivityDayActions {
        var a = ActivityDayActions()
        a.edit = { engine.editActivity($0, $1) }
        a.add = { engine.addPastActivity($0) }
        a.delete = { engine.deleteActivity($0) }
        return a
    }

    static func merging(_ engine: Engine) -> ActivityDayActions {
        var a = ActivityDayActions.engine(engine)
        a.mergeCheck = { engine.mergeCheck($0) }
        a.merge = { engine.mergeActivities($0) }
        a.undoMerge = { engine.undoMerge() }
        a.clearMergeUndo = { engine.clearMergeUndo() }
        return a
    }
}

struct ActivityRangeActions {
    var openDay: (DayKey) -> Void = { _ in }
}
