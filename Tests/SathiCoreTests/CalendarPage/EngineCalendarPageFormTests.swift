import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine calendar page form")
struct EngineCalendarPageFormTests {
    private func info(_ id: String = "e1", calendar: String = "work", repeating: Bool = false, guests: Bool = false) -> CalendarEventInfo {
        var e = CalendarEventInfo(id: id, title: "Plan", start: day(2026, 3, 4, 15), end: day(2026, 3, 4, 16), calendarID: calendar)
        e.isRepeating = repeating
        e.hasGuests = guests
        return e
    }

    @Test func defaultIsTheLastUsedCalendar() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { $0.prefs.calendarPage.lastCalendarID = "home" }
        h.calendarWriter.defaultID = "work"
        #expect(h.engine.calendarPageDefaultCalendarID == "home")
        #expect(h.engine.calendarPageNewEvent(at: day(2026, 3, 4, 14, 7)).calendarID == "home")
    }

    @Test func defaultFallsBackToTheMacDefault() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.calendarWriter.defaultID = "home"
        #expect(h.engine.calendarPageDefaultCalendarID == "home")
    }

    @Test func defaultFallsBackToTheFirstWritable() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        #expect(h.engine.calendarPageDefaultCalendarID == "work")
    }

    @Test func aLastCalendarThatIsNotWritableIsSkipped() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { $0.prefs.calendarPage.lastCalendarID = "gone" }
        h.calendarWriter.defaultID = "home"
        #expect(h.engine.calendarPageDefaultCalendarID == "home")
    }

    @Test func noWritableCalendarGivesNoDefault() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.calendarWriter.choices = []
        #expect(h.engine.calendarPageDefaultCalendarID == nil)
        #expect(h.engine.calendarPageWritableCalendars.isEmpty)
    }

    @Test func newEventFormStartsAtTheSlot() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        let f = h.engine.calendarPageNewEvent(at: day(2026, 3, 4, 14, 7))
        #expect(f.start == day(2026, 3, 4, 14))
        #expect(f.end == day(2026, 3, 4, 14, 30))
        #expect(f.calendarID == "work")
    }

    @Test func repeatingEventIsReadOnly() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        #expect(h.engine.calendarPageForm(for: info(repeating: true)).readOnly)
    }

    @Test func eventWithGuestsIsReadOnly() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        #expect(h.engine.calendarPageForm(for: info(guests: true)).readOnly)
    }

    @Test func eventInAReadOnlyCalendarIsReadOnly() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        h.calendarWriter.readable = h.calendarWriter.choices + [
            CalendarChoice(id: "holidays", title: "Holidays", account: "iCloud", colorHex: 0)
        ]
        #expect(h.engine.calendarPageForm(for: info(calendar: "holidays")).readOnly)
        #expect(!h.engine.calendarPageForm(for: info()).readOnly)
    }

    @Test func allDayEventIsReadOnly() {
        let h = EngineHarness(at: day(2026, 3, 4, 10))
        var e = info()
        e.isAllDay = true
        #expect(h.engine.calendarPageForm(for: e).readOnly)
    }
}
