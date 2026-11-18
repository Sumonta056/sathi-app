import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar event popover")
struct CalendarEventPopoverTests {
    private let standup = CalendarEventInfo(id: "s", title: "Standup", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10), calendarID: "work")

    private func harness(_ events: [CalendarEventInfo] = []) -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 12))
        h.calendarWriter.eventsValue = events
        _ = h.engine.calendarPageBase(.containing(day(2026, 3, 4, 12), kind: .day, calendar: h.engine.rangeCalendar))
        return h
    }

    private func newForm(_ h: EngineHarness, title: String = "") -> CalendarEventForm {
        var f = h.engine.calendarPageNewEvent(at: day(2026, 3, 4, 9, 10))
        f.title = title
        return f
    }

    private func popover(
        _ h: EngineHarness, _ form: CalendarEventForm, onClose: @escaping () -> Void = {}
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(CalendarEventPopover(form: form, onClose: onClose), h).inspect()
    }

    @Test func newEventShowsItsFields() throws {
        let h = harness()
        let sut = try popover(h, newForm(h))
        for line in ["New event", "TITLE", "to", "Sathi saves this event to your macOS calendar.", "Wed 4 Mar"] {
            #expect(throws: Never.self) { try sut.find(text: line) }
        }
        #expect(throws: Never.self) { try sut.find(ViewType.TextField.self) }
        #expect(sut.findAll(TimeMenu.self).count == 2)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "calendar.event.choice.work") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "calendar.event.choice.home") }
        #expect(throws: Never.self) { try sut.find(button: "Cancel") }
    }

    @Test func saveIsOffOnABlankTitle() throws {
        let h = harness()
        #expect(try popover(h, newForm(h, title: "   ")).find(button: "Save").isDisabled())
        #expect(try !popover(h, newForm(h, title: "Plan")).find(button: "Save").isDisabled())
    }

    @Test func aNewEventHasNoDelete() throws {
        let h = harness()
        #expect(try Find.lacks(popover(h, newForm(h, title: "Plan")), text: "Delete"))
    }

    @Test func anEditedEventHasDelete() throws {
        let h = harness([standup])
        let sut = try popover(h, h.engine.calendarPageForm(for: standup))
        #expect(throws: Never.self) { try sut.find(text: "Edit event") }
        #expect(throws: Never.self) { try sut.find(button: "Delete") }
    }

    @Test func aReadOnlyEventShowsOpenInCalendarOnly() throws {
        var repeating = standup
        repeating.isRepeating = true
        let h = harness([repeating])
        let sut = try popover(h, h.engine.calendarPageForm(for: repeating))
        #expect(throws: Never.self) { try sut.find(text: "Standup") }
        #expect(throws: Never.self) { try sut.find(button: "Open in Calendar") }
        #expect(Find.lacks(sut, text: "Save"))
        #expect(Find.lacks(sut, text: "Delete"))
        #expect((try? sut.find(ViewType.TextField.self)) == nil)
        #expect(sut.findAll(TimeMenu.self).isEmpty)
    }

    @Test func openInCalendarOpensTheEventAndCloses() throws {
        var repeating = standup
        repeating.isRepeating = true
        let h = harness([repeating])
        var closed = false
        try popover(h, h.engine.calendarPageForm(for: repeating)) { closed = true }.find(button: "Open in Calendar").tap()
        #expect(h.links.opened.map(\.absoluteString) == ["ical://ekevent/s"])
        #expect(closed)
    }

    @Test func saveWritesTheEventAndCloses() throws {
        let h = harness()
        var closed = false
        try popover(h, newForm(h, title: "Plan")) { closed = true }.find(button: "Save").tap()
        #expect(h.calendarWriter.saved.map(\.title) == ["Plan"])
        #expect(h.calendarWriter.saved.first?.start == day(2026, 3, 4, 9))
        #expect(closed)
    }

    @Test func aFailedSaveKeepsThePopoverOpen() throws {
        let h = harness()
        h.calendarWriter.nextSaveResult = .failed
        var closed = false
        try popover(h, newForm(h, title: "Plan")) { closed = true }.find(button: "Save").tap()
        #expect(!closed)
    }

    @Test func deleteRemovesTheEventAndCloses() throws {
        let h = harness([standup])
        var closed = false
        try popover(h, h.engine.calendarPageForm(for: standup)) { closed = true }.find(button: "Delete").tap()
        #expect(h.calendarWriter.deleted == ["s"])
        #expect(closed)
    }

    @Test func onlyASavedWriteCloses() {
        #expect(CalendarEventPopover.closes(after: .saved("x")))
        #expect(!CalendarEventPopover.closes(after: .failed))
        #expect(!CalendarEventPopover.closes(after: .invalid))
        #expect(!CalendarEventPopover.closes(after: .refused))
    }

    @Test func aRefusedSaveShowsItsOwnLine() {
        #expect(CalendarEventPopover.failureLine(after: .refused) == Copywriter.calendarEventChanged)
        #expect(Copywriter.calendarEventChanged == "This event changed in Calendar and Sathi can't edit it now. Open it in Calendar.")
    }

    @Test func aFailedWriteShowsTheWriteFailureLine() {
        #expect(CalendarEventPopover.failureLine(after: .failed) == Copywriter.calendarEventSaveFailed)
        #expect(CalendarEventPopover.failureLine(after: .invalid) == Copywriter.calendarEventSaveFailed)
        #expect(CalendarEventPopover.failureLine(after: .saved("x")) == nil)
    }

    @Test func aRefusedSaveKeepsThePopoverOpenAndWritesNothing() throws {
        let h = harness([standup])
        let form = h.engine.calendarPageForm(for: standup)
        h.calendarWriter.eventsValue = []
        var closed = false
        try popover(h, form) { closed = true }.find(button: "Save").tap()
        #expect(!closed)
        #expect(h.calendarWriter.timesUpdated.isEmpty)
    }

    @Test func theDateChipFollowsTheSixAMDay() throws {
        let h = harness()
        let late = h.engine.calendarPageNewEvent(at: day(2026, 3, 5, 1, 30))
        #expect(throws: Never.self) { try popover(h, late).find(text: "Wed 4 Mar") }
    }

    @Test func aRenderReadsNoCalendars() throws {
        var repeating = standup
        repeating.isRepeating = true
        let h = harness([standup, repeating])
        _ = h.engine.calendarPageWritableCalendars
        let readable = h.calendarWriter.readableCalls
        let calendars = h.calendarWriter.calendarsCalls
        for _ in 0 ..< 2 {
            #expect(throws: Never.self) { try popover(h, newForm(h)).find(text: "Gmail Work") }
            #expect(throws: Never.self) { try popover(h, h.engine.calendarPageForm(for: repeating)).find(text: "Gmail Work") }
        }
        #expect(h.calendarWriter.readableCalls == readable)
        #expect(h.calendarWriter.calendarsCalls == calendars)
    }
}
