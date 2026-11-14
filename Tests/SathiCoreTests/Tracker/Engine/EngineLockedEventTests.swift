import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine locked calendar events")
struct EngineLockedEventTests {
    private func work(_ text: String, _ s: Date, _ e: Date, event: String?) -> Activity {
        Activity(text: text, category: "Work", start: s, end: e, calendarID: "work", eventID: event)
    }

    private func harness(_ rows: [Activity]) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(13), activities: rows)
        h.calendarWriter.mirrorsWrites = true
        h.calendarWriter.eventsValue = rows.compactMap { r in
            r.eventID.map { CalendarEventInfo(id: $0, title: r.text, start: r.start, end: r.end, calendarID: "work") }
        }
        return h
    }

    @Test func deletingAnActivityWithALockedEventRemovesTheRowAndLeavesTheEvent() {
        let a = work("Design review", wed(10), wed(11), event: "e1")
        let h = harness([a])
        h.calendarWriter.lockedEventIDs = ["e1"]
        #expect(!h.engine.data.prefs.calendarPage.isOn)
        #expect(h.engine.deleteActivity(a.id))
        #expect(h.saved.isEmpty)
        #expect(h.calendarWriter.eventsValue.map(\.id) == ["e1"])
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.calendarWriter.updated.isEmpty)
    }

    @Test func deletingAnActivityWithAnUnlockedEventDeletesBoth() {
        let a = work("Design review", wed(10), wed(11), event: "e1")
        let h = harness([a])
        #expect(h.engine.deleteActivity(a.id))
        #expect(h.saved.isEmpty)
        #expect(h.calendarWriter.deleted == ["e1"])
        #expect(h.calendarWriter.eventsValue.isEmpty)
    }

    @Test func aFailedEventDeleteKeepsTheActivity() {
        let a = work("Design review", wed(10), wed(11), event: "e1")
        let h = harness([a])
        h.calendarWriter.nextDeleteResult = false
        #expect(!h.engine.deleteActivity(a.id))
        #expect(h.saved == [a])
    }

    @Test(arguments: ["e1", "e2"])
    func mergeWithALockedEventChangesNothing(locked: String) {
        let a = work("Code", wed(10), wed(10, 30), event: "e1"), b = work("Mail", wed(11), wed(11, 30), event: "e2")
        let h = harness([a, b])
        h.calendarWriter.lockedEventIDs = [locked]
        #expect(h.engine.mergeActivities([a.id, b.id]) == .calendarFailed)
        #expect(h.saved == [a, b])
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.engine.mergeUndo == nil)
    }

    @Test func undoNeverMakesALockedKeptEventAgain() {
        let a = work("Code", wed(10), wed(10, 30), event: "e1"), b = work("Mail", wed(11), wed(11, 30), event: "e2")
        let h = harness([a, b])
        #expect(h.engine.mergeActivities([a.id, b.id]) == .merged(a.id))
        h.calendarWriter.lockedEventIDs = ["e1"]
        h.calendarWriter.nextSaveResult = .saved(eventID: "new2")
        #expect(h.engine.undoMerge() == .restoredCalendarFailed)
        #expect(h.calendarWriter.saved.map(\.title) == ["Mail"])
        #expect(h.calendarWriter.eventsValue.filter { $0.id == "e1" }.count == 1)
        #expect(h.saved.map(\.id) == [a.id, b.id])
        #expect(h.saved[0].eventID == "e1")
    }
}
