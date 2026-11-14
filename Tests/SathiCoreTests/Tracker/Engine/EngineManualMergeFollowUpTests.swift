import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine manual merge follow up")
struct EngineManualMergeFollowUpTests {
    private func work(_ text: String, _ s: Date, _ e: Date, event: String? = nil) -> Activity {
        Activity(text: text, category: "Work", start: s, end: e, calendarID: event == nil ? nil : "work", eventID: event)
    }

    @Test func anAutomaticMergeIntoTheMergedRowClearsUndoAtOnce() {
        let a = work("Code", wed(12), wed(12, 20)), b = work("Code", wed(12, 30), wed(12, 59))
        let h = EngineHarness.tracker(at: wed(13, 10), activities: [a, b]) {
            $0.live.tracker.running = RunningActivity(
                text: "Code", category: "Work", start: wed(12, 59), expectedLength: .minutes(30), askAt: wed(13, 29)
            )
        }
        #expect(h.engine.mergeActivities([a.id, b.id]) == .merged(a.id))
        #expect(h.engine.mergeUndo != nil)
        h.engine.startActivity(ActivityDraft(text: "Mail", category: "Admin"))
        #expect(h.engine.mergeUndo == nil)
    }

    @Test func aSecondUndoIsGoneAndWritesNothing() {
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = EngineHarness.tracker(at: wed(13), activities: [a, b])
        h.engine.mergeActivities([a.id, b.id])
        #expect(h.engine.undoMerge() == .restored)
        let saves = h.activities.saves
        #expect(h.engine.undoMerge() == .gone)
        #expect(h.activities.saves == saves)
        #expect(h.saved == [a, b])
    }

    @Test func theGoneCheckReadsOnlyTheMonthOfTheMergedRow() {
        let old = work("Old", wed(10).addingTimeInterval(-40 * 86400), wed(11).addingTimeInterval(-40 * 86400))
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = EngineHarness.tracker(at: wed(13), activities: [old, a, b])
        h.engine.mergeActivities([a.id, b.id])
        let before = h.activities.reads.count
        h.engine.undoMerge()
        let key = MonthKey(a.start, calendar: h.engine.calendar)
        #expect(h.activities.reads.dropFirst(before).allSatisfy { $0 == key })
    }

    @Test func theKeptEventIsUpdatedBeforeTheOthersAreDeleted() {
        let a = work("Code", wed(10), wed(10, 30), event: "e1"), b = work("Mail", wed(11), wed(11, 30), event: "e2")
        let c = work("Docs", wed(11, 30), wed(12), event: "e3")
        let h = EngineHarness.tracker(at: wed(13), activities: [a, b, c])
        #expect(h.engine.mergeActivities([a.id, b.id, c.id]) == .merged(a.id))
        #expect(h.calendarWriter.writeOrder == ["update e1", "delete e2", "delete e3"])
    }
}
