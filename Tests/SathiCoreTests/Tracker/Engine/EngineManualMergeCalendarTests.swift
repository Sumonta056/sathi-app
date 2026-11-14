import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine manual merge calendar")
struct EngineManualMergeCalendarTests {
    private func work(_ text: String, _ s: Date, _ e: Date, event: String? = nil, calendar: String? = "work") -> Activity {
        Activity(text: text, category: "Work", start: s, end: e, calendarID: calendar, eventID: event)
    }

    private func three(events: [String?]) -> (EngineHarness, [Activity]) {
        let a = work("Code", wed(10), wed(10, 30), event: events[0])
        let b = work("Mail", wed(11), wed(11, 30), event: events[1])
        let c = work("Docs", wed(12), wed(12, 30), event: events[2])
        return (EngineHarness.tracker(at: wed(13), activities: [a, b, c]), [a, b, c])
    }

    private func ids(_ rows: [Activity]) -> Set<ActivityID> { Set(rows.map(\.id)) }

    @Test func threeRowsWithOneDeleteFailureRollBack() {
        let (h, rows) = three(events: ["e1", "e2", "e3"])
        h.calendarWriter.deleteResults["e3"] = false
        h.calendarWriter.nextSaveResult = .saved(eventID: "new2")
        #expect(h.engine.mergeActivities(ids(rows)) == .calendarFailed)
        #expect(h.calendarWriter.deleted == ["e2", "e3"])
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.saved[0].title == "Mail")
        #expect(h.calendarWriter.saved[0].start == wed(11))
        #expect(h.calendarWriter.updated.last?.0 == "e1")
        #expect(h.calendarWriter.updated.last?.1.title == "Code")
        #expect(h.calendarWriter.updated.last?.1.end == wed(10, 30))
        #expect(h.saved.map(\.id) == rows.map(\.id))
        #expect(h.saved[1].eventID == "new2")
        #expect(h.saved[0] == rows[0])
        #expect(h.saved[2] == rows[2])
        #expect(h.saved[1].text == "Mail")
    }

    @Test func onlyTheSecondRowHasAnEventAndItIsKept() {
        let (h, rows) = three(events: [nil, "e2", nil])
        #expect(h.engine.mergeActivities(ids(rows)) == .merged(rows[0].id))
        #expect(h.calendarWriter.updated.count == 1)
        #expect(h.calendarWriter.updated[0].0 == "e2")
        #expect(h.calendarWriter.updated[0].1.start == wed(10))
        #expect(h.calendarWriter.updated[0].1.end == wed(12, 30))
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.saved.count == 1)
        #expect(h.saved[0].eventID == "e2")
        #expect(h.saved[0].calendarID == "work")
    }

    @Test func firstEventIsStretchedAndTheSecondDeleted() {
        let (h, rows) = three(events: ["e1", "e2", nil])
        #expect(h.engine.mergeActivities(ids(rows)) == .merged(rows[0].id))
        #expect(h.calendarWriter.updated.count == 1)
        #expect(h.calendarWriter.updated[0].0 == "e1")
        #expect(h.calendarWriter.updated[0].1.end == wed(12, 30))
        #expect(h.calendarWriter.deleted == ["e2"])
        #expect(h.saved.count == 1)
        #expect(h.saved[0].eventID == "e1")
    }

    @Test func aDeletedEventThatCannotBeMadeAgainLeavesItsRowWithoutAnEvent() {
        let (h, rows) = three(events: ["e1", "e2", "e3"])
        h.calendarWriter.deleteResults["e3"] = false
        h.calendarWriter.nextSaveResult = .failed
        #expect(h.engine.mergeActivities(ids(rows)) == .calendarPartlyChanged)
        #expect(h.saved.count == 3)
        #expect(h.saved[1].eventID == nil)
        #expect(h.saved[1].calendarID == "work")
        #expect(h.saved[0] == rows[0])
        #expect(h.saved[2] == rows[2])
    }

    @Test func aKeptEventThatCannotMoveBackStaysAsIs() {
        let (h, rows) = three(events: ["e1", "e2", "e3"])
        h.calendarWriter.deleteResults["e3"] = false
        h.calendarWriter.updateResultQueue = [.saved(eventID: "e1"), .failed]
        #expect(h.engine.mergeActivities(ids(rows)) == .calendarPartlyChanged)
        #expect(h.saved.count == 3)
        #expect(h.saved[0] == rows[0])
    }

    @Test func aKeptRowWithoutACalendarIsNotMerged() {
        let a = work("Code", wed(10), wed(10, 30), event: "e1", calendar: nil), b = work("Mail", wed(11), wed(11, 30))
        let h = EngineHarness.tracker(at: wed(13), activities: [a, b])
        #expect(h.engine.mergeActivities([a.id, b.id]) == .calendarFailed)
        #expect(h.saved == [a, b])
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.deleted.isEmpty)
    }
}
