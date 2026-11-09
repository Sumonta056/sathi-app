import Foundation

extension Engine {
    var trackerDeadlines: [Date] { [] }
    var trackerHoldsBuddyPopups: Bool { false }

    func tickTracker() {}
    func restoreTracker() {}
    func stopTracker() {}
    func trackerPrefsChanged(from old: TrackerPrefs) {}
    func trackerBreakChanged(from old: Date?) {}
    func trackerSessionStarted(_ id: HabitID) {}
    func trackerSessionEnded(_ id: HabitID) {}
    func trackerBlockStarted() {}
    func trackerBlockSaved(_ block: TimeBlock, end: Date) {}
}
