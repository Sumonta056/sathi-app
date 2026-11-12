import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine merges old stored rows once")
struct EngineOldRowsMergeTests {
    private func row(
        _ s: Date, _ e: Date, text: String = "Gaming", category: String? = "Break", event: String? = nil
    ) -> Activity {
        Activity(text: text, category: category, start: s, end: e, eventID: event)
    }

    private func mon(_ h: Int, _ m: Int = 0) -> Date { day(2026, 3, 2, h, m) }

    private func gaming(_ count: Int) -> [Activity] {
        (0 ..< count).map { i in row(mon(10, i * 10), mon(10, i * 10 + 10), event: i == 0 ? "ev-1" : nil) }
    }

    private func started(_ rows: [Activity], configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        let h = EngineHarness(at: wed(10), activities: InMemoryActivityStore(activities: rows), configure: configure)
        h.engine.start()
        return h
    }

    private func sorted(_ h: EngineHarness) -> [Activity] { h.activities.all.sorted { $0.start < $1.start } }

    private func secondsByDay(_ rows: [Activity]) -> [Date: TimeInterval] {
        rows.reduce(into: [:]) { $0[Calendar.current.startOfDay(for: $1.start), default: 0] += $1.length }
    }

    @Test func sixTouchingGamingRowsBecomeOne() {
        let rows = gaming(6)
        let h = started(rows)
        let saved = sorted(h)
        #expect(saved.count == 1)
        #expect(saved.first?.id == rows[0].id)
        #expect(saved.first?.start == mon(10))
        #expect(saved.first?.end == mon(11))
        #expect(saved.first?.eventID == "ev-1")
    }

    @Test func backupIsWrittenOnlyForChangedMonthsWithTheOriginalRows() throws {
        let feb = [
            row(day(2026, 2, 3, 9), day(2026, 2, 3, 10), text: "Mail", category: "Work"),
            row(day(2026, 2, 3, 10), day(2026, 2, 3, 11), text: "Plan", category: "Work")
        ]
        let march = gaming(3)
        let h = started(feb + march)
        let key = try #require(MonthKey(year: 2026, month: 3))
        #expect(Array(h.activities.backups.keys) == [key])
        #expect(h.activities.backups[key]?.items == march)
    }

    @Test func thePassSetsTheFlagAndSavesPrefs() {
        let h = started(gaming(2))
        #expect(h.engine.data.prefs.tracker.mergedOldRows)
        #expect(h.store.prefs.tracker.mergedOldRows)
    }

    @Test func thePassDoesNotRunWhenTheFlagIsSet() {
        let h = started(gaming(4)) { $0.prefs.tracker.mergedOldRows = true }
        #expect(h.activities.all.count == 4)
        #expect(h.activities.backups.isEmpty)
    }

    @Test func rowsThatDoNotMatchStay() {
        let rows = [
            row(mon(9), mon(9, 10)),
            row(mon(9, 10), mon(9, 20), text: "Coding", category: "Coding"),
            row(mon(9, 20), mon(9, 30)),
            row(mon(9, 32), mon(9, 40)),
            row(mon(9, 40), mon(9, 50), category: "Work"),
            row(mon(9, 50), mon(10), event: "a"),
            row(mon(10), mon(10, 10), event: "b")
        ]
        let h = started(rows)
        #expect(sorted(h) == rows)
        #expect(h.activities.backups.isEmpty)
    }

    @Test func totalSecondsPerDayAreKept() {
        let rows = gaming(6) + [
            row(mon(12), mon(12, 30), text: "Coding", category: "Coding"),
            row(mon(12, 30), mon(13), text: "Coding", category: "Coding"),
            row(day(2026, 3, 3, 9), day(2026, 3, 3, 9, 30)),
            row(day(2026, 3, 3, 9, 30), day(2026, 3, 3, 10))
        ]
        let h = started(rows)
        #expect(h.activities.all.count == 3)
        #expect(secondsByDay(h.activities.all) == secondsByDay(rows))
    }

    @Test func noMergeAcrossMidnight() {
        let rows = [row(day(2026, 3, 2, 23, 50), day(2026, 3, 3)), row(day(2026, 3, 3), day(2026, 3, 3, 0, 10))]
        let h = started(rows)
        #expect(sorted(h) == rows)
    }

    @Test func aFailedBackupLeavesTheMonthAndTheFlag() {
        let store = InMemoryActivityStore(activities: gaming(3))
        store.failBackup = true
        let h = EngineHarness(at: wed(10), activities: store)
        h.engine.start()
        #expect(h.activities.all.count == 3)
        #expect(!h.engine.data.prefs.tracker.mergedOldRows)
    }

    @Test func aDayWithRowsInTheAwayUndoIsLeftAlone() {
        let rows = gaming(3)
        let h = started(rows) { $0.live.tracker.away.awayItems = [rows[1].id] }
        #expect(sorted(h) == rows)
    }

    @Test func aLaterRowThatAloneHasAnEventGivesTheMergedRowItsEventAndCalendar() {
        var first = row(mon(10), mon(10, 10))
        first.calendarID = "X"
        var second = row(mon(10, 10), mon(10, 20), event: "ev-y")
        second.calendarID = "Y"
        let saved = sorted(started([first, second]))
        #expect(saved.count == 1)
        #expect(saved.first?.id == first.id)
        #expect(saved.first?.eventID == "ev-y")
        #expect(saved.first?.calendarID == "Y")
    }

    @Test func aThirtySecondGapIsPartOfTheMergedRow() {
        let first = row(mon(10), mon(10, 10))
        let second = row(mon(10, 10).addingTimeInterval(30), mon(10, 20))
        let saved = sorted(started([first, second]))
        #expect(saved.count == 1)
        #expect(saved.first?.start == mon(10))
        #expect(saved.first?.end == mon(10, 20))
    }

    @Test func aDayWithARowLoggedWhileAwayIsLeftAlone() {
        let rows = gaming(3)
        let h = started(rows) { $0.live.tracker.away.loggedWhileAway = [rows[2]] }
        #expect(sorted(h) == rows)
    }

    @Test func aDayWithTheRowAnAwayEndedMergedIntoIsLeftAlone() {
        let rows = gaming(3)
        let h = started(rows) { $0.live.tracker.away.endedMergedInto = rows[0] }
        #expect(sorted(h) == rows)
    }
}

@Suite("Tracker prefs merged old rows flag")
struct TrackerMergedOldRowsFlagTests {
    @Test func oldTrackerPrefsDecodeTheFlagAsFalse() throws {
        let p = try JSONDecoder().decode(TrackerPrefs.self, from: Data(#"{"isOn":true}"#.utf8))
        #expect(p.isOn)
        #expect(!p.mergedOldRows)
    }

    @Test func aWrongTypeFallsBackToFalseAndKeepsTheRest() throws {
        let p = try JSONDecoder().decode(TrackerPrefs.self, from: Data(#"{"isOn":true,"mergedOldRows":"yes"}"#.utf8))
        #expect(p.isOn)
        #expect(!p.mergedOldRows)
    }

    @Test func theFlagRoundTrips() throws {
        var t = TrackerPrefs()
        t.mergedOldRows = true
        let back = try JSONDecoder().decode(TrackerPrefs.self, from: JSONEncoder().encode(t))
        #expect(back.mergedOldRows)
    }
}
