import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker away merge undo is cleared")
struct EngineTrackerAwayMergeClearTests {
    private func lockedWithUndo(_ events: [CalendarEventInfo] = []) -> (EngineHarness, Activity) {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents(events)
        h.start("Spec", minutes: 60)
        h.clock.advance(minutes: 20)
        h.engine.presenceChanged(.locked)
        let before = Activity(text: "Before", start: wed(9), end: wed(9, 30))
        h.engine.trackerRuntime.endedMergedInto = before
        return (h, before)
    }

    @Test func clearingTheAwayRuntimeAlsoClearsTheMergedRow() {
        let (h, _) = lockedWithUndo()
        h.engine.clearAwayRuntime()
        #expect(h.engine.trackerRuntime.endedByAway == nil)
        #expect(h.engine.trackerRuntime.endedMergedInto == nil)
    }

    @Test func anEventLoggedWhileAwayForTheEndedRowClearsTheMergedRow() {
        let e = meeting(from: wed(10, 30), to: wed(11))
        let (h, _) = lockedWithUndo([e])
        h.engine.trackerRuntime.endedByAway?.sourceEventID = "m1"
        h.advance(minutes: 20)
        h.engine.presenceChanged(.unlocked)
        #expect(h.engine.trackerRuntime.endedByAway == nil)
        #expect(h.engine.trackerRuntime.endedMergedInto == nil)
    }
}
