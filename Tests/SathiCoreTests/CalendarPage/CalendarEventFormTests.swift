import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("CalendarEventForm")
struct CalendarEventFormTests {
    let zone = FixedZone.berlin

    private func form(title: String = "Design", start: Date, end: Date, readOnly: Bool = false) -> CalendarEventForm {
        CalendarEventForm(eventID: nil, title: title, start: start, end: end, calendarID: "work", readOnly: readOnly)
    }

    @Test func slotRoundsDownToFifteenMinutesAndLastsThirty() {
        let f = CalendarEventForm.newEvent(at: zone.date(2026, 3, 4, 14, 7), calendarID: "work", calendar: zone.calendar)
        #expect(f.start == zone.date(2026, 3, 4, 14, 0))
        #expect(f.end == zone.date(2026, 3, 4, 14, 30))
        #expect(f.eventID == nil)
        #expect(f.title.isEmpty)
        #expect(f.calendarID == "work")
        #expect(!f.readOnly)
    }

    @Test func slotDropsSeconds() {
        let slot = zone.date(2026, 3, 4, 14, 14).addingTimeInterval(42)
        let f = CalendarEventForm.newEvent(at: slot, calendarID: nil, calendar: zone.calendar)
        #expect(f.start == zone.date(2026, 3, 4, 14, 0))
    }

    @Test func lateSlotEndsOnTheNextDate() {
        let f = CalendarEventForm.newEvent(at: zone.date(2026, 3, 4, 23, 50), calendarID: "work", calendar: zone.calendar)
        #expect(f.start == zone.date(2026, 3, 4, 23, 45))
        #expect(f.end == zone.date(2026, 3, 5, 0, 15))
    }

    @Test func cleanJoinsLinesAndTrims() {
        #expect(CalendarEventText.clean("  a\nb ") == "a b")
    }

    @Test func cleanCutsLongTitles() {
        let long = String(repeating: "x", count: 80)
        #expect(CalendarEventText.clean(long) == String(repeating: "x", count: Limits.blockTitleMax))
        #expect(Limits.blockTitleMax == 60)
    }

    @Test func blankTitleIsNilAndCannotSave() {
        #expect(CalendarEventText.clean(" \n  ") == nil)
        let f = form(title: "  \n", start: zone.date(2026, 3, 4, 14), end: zone.date(2026, 3, 4, 15))
        #expect(!f.canSave)
    }

    @Test func validFormCanSave() {
        #expect(form(start: zone.date(2026, 3, 4, 14), end: zone.date(2026, 3, 4, 15)).canSave)
    }

    @Test func missingCalendarCannotSave() {
        var f = form(start: zone.date(2026, 3, 4, 14), end: zone.date(2026, 3, 4, 15))
        f.calendarID = nil
        #expect(!f.canSave)
    }

    @Test func equalTimesCannotSave() {
        let base = form(start: zone.date(2026, 3, 4, 14), end: zone.date(2026, 3, 4, 14, 30))
        let f = base.withTimes(startMinutes: 15 * 60, endMinutes: 15 * 60, calendar: zone.calendar)
        #expect(f.start == zone.date(2026, 3, 4, 15))
        #expect(!f.canSave)
    }

    @Test func endBeforeStartMovesToTheNextDate() {
        let base = form(start: zone.date(2026, 3, 4, 14), end: zone.date(2026, 3, 4, 14, 30))
        let f = base.withTimes(startMinutes: 23 * 60, endMinutes: 60, calendar: zone.calendar)
        #expect(f.start == zone.date(2026, 3, 4, 23))
        #expect(f.end == zone.date(2026, 3, 5, 1))
        #expect(f.canSave)
    }

    @Test func endAfterStartStaysOnTheStartDate() {
        let base = form(start: zone.date(2026, 3, 4, 23, 45), end: zone.date(2026, 3, 5, 0, 15))
        let f = base.withTimes(startMinutes: 9 * 60, endMinutes: 10 * 60 + 30, calendar: zone.calendar)
        #expect(f.start == zone.date(2026, 3, 4, 9))
        #expect(f.end == zone.date(2026, 3, 4, 10, 30))
    }

    @Test func readOnlyCannotSave() {
        #expect(!form(start: zone.date(2026, 3, 4, 14), end: zone.date(2026, 3, 4, 15), readOnly: true).canSave)
    }

    @Test func repeatingOrGuestsMakeAnEventReadOnly() {
        let start = zone.date(2026, 3, 4, 14)
        let plain = CalendarEventInfo(id: "e", title: "t", start: start, end: start, calendarID: "work")
        #expect(!plain.isReadOnlyInSathi)
        var repeating = plain
        repeating.isRepeating = true
        #expect(repeating.isReadOnlyInSathi)
        var guests = plain
        guests.hasGuests = true
        #expect(guests.isReadOnlyInSathi)
    }
}
