import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine merges old rows that both have calendar events")
struct EngineOldEventRowsMergeTests {
    private func mon(_ h: Int, _ m: Int = 0) -> Date { day(2026, 3, 2, h, m) }

    private func nuxt(_ s: Date, _ e: Date, event: String?, calendar: String? = "work") -> Activity {
        Activity(text: "NUXT Version R&D", category: "Coding", start: s, end: e, calendarID: calendar, eventID: event)
    }

    private func harness(_ rows: [Activity], configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness(at: wed(10), activities: InMemoryActivityStore(activities: rows), configure: configure)
    }

    private func sorted(_ h: EngineHarness) -> [Activity] { h.activities.all.sorted { $0.start < $1.start } }

    private var threeSplitRows: [Activity] {
        [
            nuxt(mon(10, 38), mon(10, 55), event: "ev-1"),
            nuxt(mon(10, 55), mon(11, 44), event: "ev-2"),
            nuxt(mon(11, 44), mon(12, 16), event: "ev-3")
        ]
    }

    @Test func threeTouchingRowsWithEventsBecomeOneRowAndOneEvent() {
        let rows = threeSplitRows
        let h = harness(rows)
        h.engine.start()
        let saved = sorted(h)
        #expect(saved.count == 1)
        #expect(saved.first?.id == rows[0].id)
        #expect(saved.first?.start == mon(10, 38))
        #expect(saved.first?.end == mon(12, 16))
        #expect(saved.first?.eventID == "ev-1")
        #expect(Set(h.calendarWriter.deleted) == ["ev-2", "ev-3"])
        #expect(h.calendarWriter.updated.last?.0 == "ev-1")
        #expect(h.calendarWriter.updated.last?.1.start == mon(10, 38))
        #expect(h.calendarWriter.updated.last?.1.end == mon(12, 16))
        #expect(h.engine.data.prefs.tracker.mergedEventRows)
    }

    @Test func theKeptEventIsMovedBeforeTheLaterEventIsDeleted() {
        let h = harness(Array(threeSplitRows.prefix(2)))
        h.engine.start()
        #expect(h.calendarWriter.updated.map(\.0) == ["ev-1"])
        #expect(h.calendarWriter.updated.first?.1.end == mon(11, 44))
        #expect(h.calendarWriter.deleted == ["ev-2"])
    }

    @Test func aFailedMoveKeepsBothRowsAndDeletesNothing() {
        let rows = Array(threeSplitRows.prefix(2))
        let h = harness(rows)
        h.calendarWriter.nextUpdateResult = .failed
        h.engine.start()
        #expect(sorted(h) == rows)
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(!h.engine.data.prefs.tracker.mergedEventRows)
    }

    @Test func aFailedDeleteMovesTheKeptEventBackAndKeepsBothRows() {
        let rows = Array(threeSplitRows.prefix(2))
        let h = harness(rows)
        h.calendarWriter.deleteResults["ev-2"] = false
        h.engine.start()
        #expect(sorted(h) == rows)
        #expect(h.calendarWriter.updated.last?.0 == "ev-1")
        #expect(h.calendarWriter.updated.last?.1.end == mon(10, 55))
        #expect(!h.engine.data.prefs.tracker.mergedEventRows)
    }

    @Test func aRowWithoutACalendarCannotMoveItsEventSoTheRowsStayApart() {
        let rows = [nuxt(mon(10), mon(10, 30), event: "ev-1", calendar: nil), nuxt(mon(10, 30), mon(11), event: "ev-2")]
        let h = harness(rows)
        h.engine.start()
        #expect(sorted(h) == rows)
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.engine.data.prefs.tracker.mergedEventRows)
    }

    @Test func aMissingEventOrCalendarKeepsTheRowsApartAndStillEndsThePass() {
        let rows = Array(threeSplitRows.prefix(2))
        let h = harness(rows)
        h.calendarWriter.nextUpdateResult = .calendarMissing
        h.engine.start()
        #expect(sorted(h) == rows)
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.engine.data.prefs.tracker.mergedEventRows)
    }

    @Test func aNewEventIDFromTheMoveIsKept() {
        let h = harness(Array(threeSplitRows.prefix(2)))
        h.calendarWriter.nextUpdateResult = .saved(eventID: "ev-1b")
        h.engine.start()
        #expect(sorted(h).map(\.eventID) == ["ev-1b"])
    }

    @Test func aNewEventIDFromTheMoveBackIsSaved() {
        let rows = Array(threeSplitRows.prefix(2))
        let h = harness(rows)
        h.calendarWriter.nextUpdateResult = .saved(eventID: "ev-1b")
        h.calendarWriter.deleteResults["ev-2"] = false
        h.engine.start()
        #expect(sorted(h).map(\.eventID) == ["ev-1b", "ev-2"])
    }

    @Test func theMoveBackUsesTheEventsRealEndAfterARowWithoutAnEventJoined() {
        let rows = [
            nuxt(mon(10), mon(10, 30), event: "ev-1"),
            nuxt(mon(10, 30), mon(11), event: nil),
            nuxt(mon(11), mon(11, 30), event: "ev-3")
        ]
        let h = harness(rows)
        h.calendarWriter.deleteResults["ev-3"] = false
        h.engine.start()
        let saved = sorted(h)
        #expect(saved.map(\.end) == [mon(11), mon(11, 30)])
        #expect(h.calendarWriter.updated.last?.0 == "ev-1")
        #expect(h.calendarWriter.updated.last?.1.end == mon(10, 30))
    }

    @Test func aFailedFirstPairStillLetsTheNextPairMerge() {
        let rows = threeSplitRows
        let h = harness(rows)
        h.calendarWriter.deleteResults["ev-2"] = false
        h.engine.start()
        let saved = sorted(h)
        #expect(saved.map(\.eventID) == ["ev-1", "ev-2"])
        #expect(saved.map(\.end) == [mon(10, 55), mon(12, 16)])
        #expect(h.calendarWriter.deleted == ["ev-2", "ev-3"])
    }

    @Test func anEventRowAfterARowWithoutAnEventTakesOverWithNoCalendarChange() {
        let rows = [nuxt(mon(10), mon(10, 30), event: nil), nuxt(mon(10, 30), mon(11), event: "ev-2")]
        let h = harness(rows)
        h.engine.start()
        let saved = sorted(h)
        #expect(saved.count == 1)
        #expect(saved.first?.eventID == "ev-2")
        #expect(h.calendarWriter.deleted.isEmpty)
    }

    @Test func theNewFlagStopsThePass() {
        let rows = Array(threeSplitRows.prefix(2))
        let h = harness(rows) { $0.prefs.tracker.mergedEventRows = true }
        h.engine.start()
        #expect(sorted(h) == rows)
        #expect(h.calendarWriter.updated.isEmpty)
    }

    @Test func eventRowsDoNotMergeAcrossMidnight() {
        let rows = [
            nuxt(day(2026, 3, 2, 23, 30), day(2026, 3, 3), event: "ev-1"),
            nuxt(day(2026, 3, 3), day(2026, 3, 3, 0, 30), event: "ev-2")
        ]
        let h = harness(rows)
        h.engine.start()
        #expect(sorted(h) == rows)
        #expect(h.calendarWriter.deleted.isEmpty)
    }

    @Test func aDayWithARowInTheAwayUndoIsLeftAlone() {
        let rows = Array(threeSplitRows.prefix(2))
        let h = harness(rows) { $0.live.tracker.away.awayItems = [rows[0].id] }
        h.engine.start()
        #expect(sorted(h) == rows)
        #expect(h.calendarWriter.deleted.isEmpty)
    }
}
