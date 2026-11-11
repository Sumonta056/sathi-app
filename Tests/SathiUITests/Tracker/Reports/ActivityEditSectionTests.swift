import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity edit section")
struct ActivityEditSectionTests {
    typealias Fix = ActivityViewSupport

    private func section(
        _ activity: Activity = Fix.items[0], result: ActivityEditResult = .saved(ActivityID()),
        saved: @escaping (ActivityEdit) -> Void = { _ in }, closed: @escaping () -> Void = {}, deleted: (() -> Bool)? = nil
    ) -> ActivityEditSection {
        ActivityEditSection(
            draft: ActivityEditDraft(activity, calendar: Fix.calendar, writable: Fix.calendars.map(\.id)), title: "Edit activity",
            accent: Night.tracker,
            categories: ActivityCategory.defaults, calendars: Fix.calendars, dayStart: Fix.key(4).start(in: Fix.calendar),
            calendar: Fix.calendar, save: { saved($0); return result }, delete: deleted, close: closed
        )
    }

    private func press(_ sut: ActivityEditSection, _ title: String) throws {
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: title) != nil }.tap()
    }

    private func boxes(_ sut: ActivityEditSection, _ prefix: String) throws -> [PromptBox] {
        try sut.inspect().findAll(PromptBox.self).map { try $0.actualView() }.filter { $0.id.hasPrefix(prefix) }
    }

    @Test func saveSendsTheEditedTimes() throws {
        var edit: ActivityEdit?
        try press(section(saved: { edit = $0 }), "Save")
        #expect(edit?.start == Fix.at(4, 9))
        #expect(edit?.end == Fix.at(4, 10, 30))
        #expect(edit?.text == "Fix login bug")
    }

    @Test func aSavedEditClosesTheSection() throws {
        var closed = 0
        try press(section(closed: { closed += 1 }), "Save")
        #expect(closed == 1)
    }

    @Test func anOverlapKeepsTheSectionOpen() throws {
        var closed = 0
        try press(section(result: .overlap, closed: { closed += 1 }), "Save")
        #expect(closed == 0)
    }

    @Test func cancelClosesWithoutSaving() throws {
        var saves = 0
        var closed = 0
        try press(section(saved: { _ in saves += 1 }, closed: { closed += 1 }), "Cancel")
        #expect(saves == 0)
        #expect(closed == 1)
    }

    @Test func deleteShowsOnlyWhenGiven() throws {
        #expect(try Find.lacks(section().inspect(), text: "Delete"))
        var deleted = 0
        try press(section(deleted: { deleted += 1; return true }), "Delete")
        #expect(deleted == 1)
    }

    @Test func aFailedDeleteKeepsTheSectionOpen() throws {
        var closed = 0
        try press(section(closed: { closed += 1 }, deleted: { false }), "Delete")
        #expect(closed == 0)
    }

    @Test func aLengthChipKeepsTheSecondsOfTheStart() {
        let a = Activity(text: "Review", start: Fix.at(4, 10, 37, 40), end: Fix.at(4, 11, 0))
        var d = ActivityEditDraft(a, calendar: Fix.calendar)
        d.setLength(15)
        let e = d.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar)
        #expect(e.start == Fix.at(4, 10, 37, 40))
        #expect(e.end == Fix.at(4, 10, 52, 40))
    }

    @Test func aLengthChipAfterAStartChangeUsesTheNewStart() {
        var d = ActivityEditDraft(Fix.items[0], calendar: Fix.calendar)
        d.startMinutes = 9 * 60 + 30
        d.setLength(30)
        #expect(d.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar).end == Fix.at(4, 10))
    }

    @Test func everyCategoryIsAChipPlusNone() throws {
        let labels = try boxes(section(), "activity.category.").map(\.label)
        #expect(labels == ActivityCategory.defaults.map(\.name) + ["None"])
        #expect(try boxes(section(), "activity.category.").filter(\.on).map(\.label) == ["Coding"])
    }

    @Test func theCalendarChipsAreDoNotAddAndEveryWritableCalendar() throws {
        #expect(try boxes(section(), "activity.calendar.").map(\.label) == ["Do not add", "Work", "Personal"])
        #expect(try boxes(section(), "activity.calendar.").filter(\.on).map(\.label) == ["Do not add"])
    }

    @Test func theCurrentCalendarIsPicked() throws {
        var a = Fix.items[0]
        a.calendarID = "home"
        a.eventID = "ev1"
        #expect(try boxes(section(a), "activity.calendar.").filter(\.on).map(\.label) == ["Personal"])
    }

    @Test func theDraftSendsTheCalendarChoice() {
        var a = Fix.items[0]
        a.calendarID = "work"
        var d = ActivityEditDraft(a, calendar: Fix.calendar)
        let dayStart = Fix.key(4).start(in: Fix.calendar)
        #expect(d.edit(dayStart: dayStart, calendar: Fix.calendar).calendar == .calendar("work"))
        d.calendarID = nil
        #expect(d.edit(dayStart: dayStart, calendar: Fix.calendar).calendar == .none)
        d.calendarID = "home"
        #expect(d.edit(dayStart: dayStart, calendar: Fix.calendar).calendar == .calendar("home"))
    }

    @Test func anActivityFromACalendarEventHasNoCalendarChipsAndKeepsItsCalendar() throws {
        let a = Activity(kind: .event, text: "Standup", start: Fix.at(4, 11), end: Fix.at(4, 11, 30), calendarID: "work", sourceEventID: "m1")
        #expect(try boxes(section(a), "activity.calendar.").isEmpty)
        #expect(ActivityEditDraft(a, calendar: Fix.calendar).calendarChoice == .keep)
    }
}
