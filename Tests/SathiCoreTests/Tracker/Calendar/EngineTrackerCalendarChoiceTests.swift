import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker calendar choice on edit")
struct EngineTrackerCalendarChoiceTests {
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

    @Test func theChoiceKeepsTheCalendarByDefault() {
        #expect(ActivityEdit(text: "x", category: nil, start: wed(9), end: wed(10)).calendar == .keep)
    }

    @Test func doNotAddDeletesTheEventAndClearsTheCalendar() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h)
        #expect(h.engine.editActivity(a.id, edit(.none)) == .saved(a.id))
        #expect(h.calendarWriter.deleted == ["ev9"])
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.saved.first?.calendarID == nil)
        #expect(h.saved.first?.eventID == nil)
        #expect(h.saved.first?.text == "Spec v2")
    }

    @Test func doNotAddOnAnActivityWithoutAnEventDeletesNothing() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h, calendarID: nil, eventID: nil)
        h.engine.editActivity(a.id, edit(.none))
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.saved.first?.calendarID == nil)
    }

    @Test func anotherCalendarDeletesTheOldEventAndWritesANewOne() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h)
        h.engine.editActivity(a.id, edit(.calendar("home")))
        #expect(h.calendarWriter.deleted == ["ev9"])
        #expect(h.calendarWriter.updated.isEmpty)
        #expect(h.calendarWriter.saved == [CalendarEventDraft(calendarID: "home", title: "Spec v2", start: wed(9), end: wed(9, 40))])
        #expect(h.saved.first?.calendarID == "home")
        #expect(h.saved.first?.eventID == "e1")
    }

    @Test func aCalendarForAnActivityWithoutOneWritesAnEvent() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h, calendarID: nil, eventID: nil)
        h.engine.editActivity(a.id, edit(.calendar("work")))
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.calendarWriter.saved.map(\.calendarID) == ["work"])
        #expect(h.saved.first?.calendarID == "work")
        #expect(h.saved.first?.eventID == "e1")
    }

    @Test func theSameCalendarUpdatesTheEvent() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h)
        h.engine.editActivity(a.id, edit(.calendar("work")))
        #expect(h.calendarWriter.updated.map(\.0) == ["ev9"])
        #expect(h.calendarWriter.updated.first?.1 == CalendarEventDraft(calendarID: "work", title: "Spec v2", start: wed(9), end: wed(9, 40)))
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.saved.first?.eventID == "ev9")
    }

    @Test func theSameCalendarWithoutAnEventWritesOne() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h, eventID: nil)
        h.engine.editActivity(a.id, edit(.calendar("work")))
        #expect(h.calendarWriter.saved.map(\.calendarID) == ["work"])
        #expect(h.saved.first?.eventID == "e1")
    }

    @Test func aFailedWriteInTheNewCalendarKeepsTheActivityWithoutAnEvent() {
        let h = EngineHarness.tracker(at: wed(12))
        h.calendarWriter.nextSaveResult = .failed
        let a = stored(h)
        #expect(h.engine.editActivity(a.id, edit(.calendar("home"))) == .saved(a.id))
        #expect(h.calendarWriter.deleted == ["ev9"])
        #expect(h.saved.first?.calendarID == "home")
        #expect(h.saved.first?.eventID == nil)
    }

    @Test func anActivityFromACalendarEventIgnoresTheChoice() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h, calendarID: "work", eventID: nil, source: "m1")
        h.engine.editActivity(a.id, edit(.none))
        h.engine.editActivity(a.id, edit(.calendar("home")))
        #expect(h.calendarWriter.deleted.isEmpty)
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.saved.first?.calendarID == "work")
        #expect(h.saved.first?.sourceEventID == "m1")
    }

    @Test func aBuddyActivityIgnoresTheChoice() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h, kind: .buddy, calendarID: nil, eventID: nil)
        h.engine.editActivity(a.id, edit(.calendar("home")))
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.saved.first?.calendarID == nil)
    }

    @Test func anAddedPastActivityWithACalendarWritesOneEvent() {
        let h = EngineHarness.tracker(at: wed(12))
        let e = ActivityEdit(text: "Review", category: "Review", start: wed(8), end: wed(8, 30), calendar: .calendar("home"))
        guard case let .saved(id) = h.engine.addPastActivity(e) else { Issue.record("not saved"); return }
        #expect(h.calendarWriter.saved == [CalendarEventDraft(calendarID: "home", title: "Review", start: wed(8), end: wed(8, 30))])
        #expect(h.saved.first { $0.id == id }?.calendarID == "home")
        #expect(h.saved.first { $0.id == id }?.eventID == "e1")
    }

    @Test(arguments: [ActivityCalendarChoice.none, .keep])
    func anAddedPastActivityWithoutACalendarWritesNothing(_ choice: ActivityCalendarChoice) {
        let h = EngineHarness.tracker(at: wed(12))
        h.engine.addPastActivity(ActivityEdit(text: "Review", category: nil, start: wed(8), end: wed(8, 30), calendar: choice))
        #expect(h.calendarWriter.saved.isEmpty)
        #expect(h.saved.first?.calendarID == nil)
    }

    @Test func aRefusedEditTouchesNoCalendar() {
        let h = EngineHarness.tracker(at: wed(12))
        let a = stored(h)
        let e = ActivityEdit(text: "Spec v2", category: nil, start: wed(9), end: wed(9, 0, s: 30), calendar: .none)
        #expect(h.engine.editActivity(a.id, e) == .tooShort)
        #expect(h.calendarWriter.deleted.isEmpty)
    }
}
