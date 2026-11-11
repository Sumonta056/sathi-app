import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker calendar safe moves")
struct EngineTrackerCalendarSafetyTests {
    private func stored(
        _ h: EngineHarness,
        kind: ActivityKind = .work,
        calendarID: String? = "work",
        eventID: String? = "ev9",
        source: String? = nil
    ) -> Activity {
        let a = Activity(
            kind: kind, text: "Spec", category: "Coding", start: wed(9), end: wed(9, 30),
            calendarID: calendarID, eventID: eventID, sourceEventID: source
        )
        h.activities.save(ActivityMonth(key: MonthKey(wed(9), calendar: .current), items: [a]))
        return a
    }

    private func edit(_ choice: ActivityCalendarChoice) -> ActivityEdit {
        ActivityEdit(text: "Spec v2", category: "Coding", start: wed(9), end: wed(9, 40), calendar: choice)
    }

    @Test func aMoveWritesTheNewEventBeforeItDeletesTheOldOne() {
        let h = EngineHarness.tracker(at: wed(12))
        h.calendarWriter.nextSaveResult = .failed
        let a = stored(h)
        #expect(h.engine.editActivity(a.id, edit(.calendar("home"))) == .saved(a.id))
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.saved.first?.calendarID == "work")
        #expect(h.saved.first?.eventID == "ev9")
        #expect(h.saved.first?.text == "Spec v2")
    }

    @Test func aMoveWhoseOldEventCannotBeDeletedRemovesTheNewEventAndKeepsTheOld() {
        let h = EngineHarness.tracker(at: wed(12))
        h.calendarWriter.nextDeleteResult = false
        let a = stored(h)
        h.engine.editActivity(a.id, edit(.calendar("home")))
        #expect(h.calendarWriter.saved.map(\.calendarID) == ["home"])
        #expect(h.calendarWriter.deleted == ["ev9", "e1"])
        #expect(h.saved.first?.calendarID == "work")
        #expect(h.saved.first?.eventID == "ev9")
    }

    @Test func aFailedWriteForAnActivityWithoutAnEventKeepsThePickForARetry() {
        let h = EngineHarness.tracker(at: wed(12))
        h.calendarWriter.nextSaveResult = .failed
        let a = stored(h, calendarID: nil, eventID: nil)
        h.engine.editActivity(a.id, edit(.calendar("home")))
        #expect(h.saved.first?.calendarID == "home")
        #expect(h.saved.first?.eventID == nil)
    }

    @Test func doNotAddKeepsTheEventWhenTheDeleteFails() {
        let h = EngineHarness.tracker(at: wed(12))
        h.calendarWriter.nextDeleteResult = false
        let a = stored(h)
        #expect(h.engine.editActivity(a.id, edit(.none)) == .saved(a.id))
        #expect(h.saved.first?.calendarID == "work")
        #expect(h.saved.first?.eventID == "ev9")
        #expect(h.saved.first?.text == "Spec v2")
    }

    @Test func deleteKeepsTheActivityWhenItsEventCannotBeDeleted() {
        let h = EngineHarness.tracker(at: wed(12))
        h.calendarWriter.nextDeleteResult = false
        let a = stored(h)
        #expect(h.engine.deleteActivity(a.id) == false)
        #expect(h.saved.map(\.id) == [a.id])
        h.calendarWriter.nextDeleteResult = true
        #expect(h.engine.deleteActivity(a.id))
        #expect(h.saved.isEmpty)
    }
}
