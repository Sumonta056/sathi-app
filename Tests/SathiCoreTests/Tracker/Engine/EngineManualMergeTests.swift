import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine manual merge")
struct EngineManualMergeTests {
    private func work(_ text: String, _ s: Date, _ e: Date, event: String? = nil) -> Activity {
        Activity(text: text, category: "Work", start: s, end: e, calendarID: event == nil ? nil : "work", eventID: event)
    }

    private func away(_ s: Date, _ e: Date) -> Activity {
        Activity(kind: .away, text: "Away", start: s, end: e)
    }

    @Test func threeRowsAndAnAwayBecomeOneRow() {
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(10, 40), wed(11))
        let gap = away(wed(11), wed(11, 10)), c = work("Docs", wed(11, 10), wed(11, 30))
        let h = EngineHarness.tracker(at: wed(12), activities: [a, b, gap, c])
        let result = h.engine.mergeActivities([a.id, b.id, c.id])
        #expect(result == .merged(a.id))
        #expect(h.saved.count == 1)
        #expect(h.saved[0].id == a.id)
        #expect(h.saved[0].start == wed(10))
        #expect(h.saved[0].end == wed(11, 30))
    }

    @Test func noCalendarCallsWhenNoRowHasAnEvent() {
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = EngineHarness.tracker(at: wed(12), activities: [a, b])
        h.engine.mergeActivities([a.id, b.id])
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.deleted.isEmpty)
    }

    @Test func oneEventIsStretchedAndTheOthersDeleted() {
        let a = work("Code", wed(10), wed(10, 30), event: "e1"), b = work("Mail", wed(11), wed(11, 30), event: "e2")
        let h = EngineHarness.tracker(at: wed(12), activities: [a, b])
        #expect(h.engine.mergeActivities([a.id, b.id]) == .merged(a.id))
        #expect(h.calendarWriter.updated.count == 1)
        #expect(h.calendarWriter.updated[0].0 == "e1")
        #expect(h.calendarWriter.updated[0].1.title == "Code")
        #expect(h.calendarWriter.updated[0].1.start == wed(10))
        #expect(h.calendarWriter.updated[0].1.end == wed(11, 30))
        #expect(h.calendarWriter.deleted == ["e2"])
        #expect(h.saved[0].eventID == "e1")
    }

    @Test func aBlockedMergeLeavesTheStoreAlone() {
        let a = work("Code", wed(10), wed(10, 30)), mid = work("Mail", wed(10, 30), wed(11)), b = work("Docs", wed(11), wed(11, 30))
        let h = EngineHarness.tracker(at: wed(12), activities: [a, mid, b])
        let before = h.saved
        #expect(h.engine.mergeActivities([a.id, b.id]) == .blocked(.rowBetween))
        #expect(h.saved == before)
        #expect(h.engine.mergeCheck([a.id]) == .blocked(.tooFew))
    }

    @Test func theRunningActivityIsNotMergeable() {
        let a = work("Code", wed(9), wed(9, 30))
        let h = EngineHarness.tracker(at: wed(10), activities: [a])
        h.start("Mail", minutes: nil)
        h.advance(minutes: 10)
        let running = h.engine.activityDay(DayKey(wed(10), calendar: .current)).running
        let id = running?.id ?? ActivityID()
        #expect(h.engine.mergeActivities([a.id, id]) == .blocked(.notStored))
        #expect(h.saved.count == 1)
    }

    @Test func calendarFailureKeepsEveryRow() {
        let a = work("Code", wed(10), wed(10, 30), event: "e1"), b = work("Mail", wed(11), wed(11, 30), event: "e2")
        let h = EngineHarness.tracker(at: wed(12), activities: [a, b])
        h.calendarWriter.nextUpdateResult = .failed
        #expect(h.engine.mergeActivities([a.id, b.id]) == .calendarFailed)
        #expect(h.saved == [a, b])
        #expect(h.calendarWriter.deleted.isEmpty)
    }

    @Test func deleteFailureRestoresTheKeptEvent() {
        let a = work("Code", wed(10), wed(10, 30), event: "e1"), b = work("Mail", wed(11), wed(11, 30), event: "e2")
        let h = EngineHarness.tracker(at: wed(12), activities: [a, b])
        h.calendarWriter.deleteResults["e2"] = false
        #expect(h.engine.mergeActivities([a.id, b.id]) == .calendarFailed)
        #expect(h.saved == [a, b])
        #expect(h.calendarWriter.updated.last?.1.end == wed(10, 30))
    }

    @Test func aLaterAnswerStillAutoMergesIntoTheMergedRow() {
        let a = work("Code review", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = EngineHarness.tracker(at: wed(11, 30, s: 30), activities: [a, b])
        h.engine.mergeActivities([a.id, b.id])
        h.engine.startActivity(ActivityDraft(text: "Code review", category: "Work", length: .minutes(30)))
        h.advance(minutes: 10)
        h.engine.startActivity(ActivityDraft(text: "Mail", category: "Other", length: .minutes(30)))
        #expect(h.saved.count == 1)
        #expect(h.saved[0].end == wed(11, 40, s: 30))
    }
}
