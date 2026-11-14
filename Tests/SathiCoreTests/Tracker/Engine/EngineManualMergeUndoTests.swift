import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine manual merge undo")
struct EngineManualMergeUndoTests {
    private func work(_ text: String, _ s: Date, _ e: Date, category: String = "Work", event: String? = nil) -> Activity {
        Activity(text: text, category: category, start: s, end: e, calendarID: event == nil ? nil : "work", eventID: event)
    }

    private func away(_ s: Date, _ e: Date) -> Activity {
        Activity(kind: .away, text: "Away", start: s, end: e)
    }

    private func merged(_ rows: [Activity], at now: Date = wed(13)) -> EngineHarness {
        let h = EngineHarness.tracker(at: now, activities: rows)
        let work = rows.filter { $0.kind == .work }.map(\.id)
        #expect(h.engine.mergeActivities(Set(work)) == .merged(work[0]))
        return h
    }

    @Test func undoRestoresEveryRowIncludingTheRemovedAway() {
        let a = work("Code", wed(10), wed(10, 30)), gap = away(wed(10, 30), wed(10, 40))
        let b = work("Mail", wed(10, 40), wed(11), category: "Admin"), c = work("Docs", wed(11, 10), wed(11, 30))
        let h = merged([a, gap, b, c])
        #expect(h.engine.mergeUndo != nil)
        #expect(h.engine.undoMerge() == .restored)
        #expect(h.saved == [a, gap, b, c])
        #expect(h.engine.mergeUndo == nil)
    }

    @Test func undoWritesTheRowsInOneMonthWrite() {
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = merged([a, b])
        let before = h.activities.saves
        h.engine.undoMerge()
        #expect(h.activities.saves == before + 1)
    }

    @Test func undoMovesTheKeptEventBackAndMakesTheDeletedOneAgain() {
        let a = work("Code", wed(10), wed(10, 30), event: "e1"), b = work("Mail", wed(11), wed(11, 30), event: "e2")
        let h = merged([a, b])
        h.calendarWriter.nextSaveResult = .saved(eventID: "new2")
        #expect(h.engine.undoMerge() == .restored)
        #expect(h.calendarWriter.updated.last?.0 == "e1")
        #expect(h.calendarWriter.updated.last?.1.title == "Code")
        #expect(h.calendarWriter.updated.last?.1.start == wed(10))
        #expect(h.calendarWriter.updated.last?.1.end == wed(10, 30))
        #expect(h.calendarWriter.saved.count == 1)
        #expect(h.calendarWriter.saved[0].title == "Mail")
        #expect(h.calendarWriter.saved[0].start == wed(11))
        #expect(h.calendarWriter.saved[0].end == wed(11, 30))
        #expect(h.calendarWriter.saved[0].calendarID == "work")
        var newB = b
        newB.eventID = "new2"
        #expect(h.saved == [a, newB])
    }

    @Test func aFailedSaveOnUndoStillBringsTheRowsBack() {
        let a = work("Code", wed(10), wed(10, 30), event: "e1"), b = work("Mail", wed(11), wed(11, 30), event: "e2")
        let h = merged([a, b])
        h.calendarWriter.nextSaveResult = .failed
        #expect(h.engine.undoMerge() == .restoredCalendarFailed)
        var noEvent = b
        noEvent.eventID = nil
        #expect(h.saved == [a, noEvent])
        #expect(h.saved[1].calendarID == "work")
    }

    @Test func aFailedMoveBackOnUndoStillBringsTheRowsBack() {
        let a = work("Code", wed(10), wed(10, 30), event: "e1"), b = work("Mail", wed(11), wed(11, 30))
        let h = merged([a, b])
        h.calendarWriter.nextUpdateResult = .failed
        #expect(h.engine.undoMerge() == .restoredCalendarFailed)
        #expect(h.saved == [a, b])
    }

    @Test func undoIsGoneAfterThirtySeconds() {
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = merged([a, b])
        #expect(h.engine.nextTickDelay() <= Timing.mergeUndoShow)
        h.advance(minutes: Timing.mergeUndoShow / 60)
        #expect(h.engine.mergeUndo == nil)
        #expect(h.engine.undoMerge() == .gone)
        #expect(h.saved.count == 1)
    }

    @Test func undoStillWorksJustBeforeThirtySeconds() {
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = merged([a, b])
        h.advance(minutes: (Timing.mergeUndoShow - 1) / 60)
        #expect(h.engine.undoMerge() == .restored)
        #expect(h.saved == [a, b])
    }

    @Test func anEditClearsUndo() {
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = merged([a, b])
        let edit = ActivityEdit(text: "Code", category: "Work", start: wed(10), end: wed(11, 45))
        h.engine.editActivity(a.id, edit)
        #expect(h.engine.mergeUndo == nil)
        #expect(h.engine.undoMerge() == .gone)
    }

    @Test func anAddClearsUndo() {
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = merged([a, b])
        h.engine.addPastActivity(ActivityEdit(text: "Lunch", category: "Break", start: wed(12), end: wed(12, 30)))
        #expect(h.engine.mergeUndo == nil)
    }

    @Test func aDeleteClearsUndo() {
        let a = work("Code", wed(10), wed(10, 30)), b = work("Mail", wed(11), wed(11, 30))
        let h = merged([a, b])
        h.engine.deleteActivity(a.id)
        #expect(h.engine.mergeUndo == nil)
    }

    @Test func aMergedRowThatChangedAfterTheMergeIsGone() {
        let a = work("Code", wed(12), wed(12, 20)), b = work("Code", wed(12, 30), wed(12, 59))
        let h = EngineHarness.tracker(at: wed(13, 10), activities: [a, b]) {
            $0.live.tracker.running = RunningActivity(
                text: "Code", category: "Work", start: wed(12, 59), expectedLength: .minutes(30), askAt: wed(13, 29)
            )
        }
        #expect(h.engine.mergeActivities([a.id, b.id]) == .merged(a.id))
        h.engine.startActivity(ActivityDraft(text: "Mail", category: "Admin"))
        #expect(h.saved.first?.end == wed(13, 10))
        #expect(h.engine.undoMerge() == .gone)
        #expect(h.saved.count == 1)
        #expect(h.engine.mergeUndo == nil)
    }
}
