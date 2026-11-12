import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity edit calendar chips")
struct ActivityEditCalendarTests {
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

    @Test func anUnlistedCalendarShowsAsTheCurrentPickAndKeepsTheEvent() throws {
        var a = Fix.items[0]
        a.calendarID = "shared"
        a.eventID = "ev1"
        let sut = section(a)
        let boxes = try boxes(sut, "activity.calendar.")
        #expect(boxes.map(\.label) == ["Do not add", "Current calendar", "Work", "Personal"])
        #expect(boxes.filter(\.on).map(\.label) == ["Current calendar"])
        #expect(ActivityEditDraft(a, calendar: Fix.calendar, writable: ["work", "home"]).calendarChoice == .keep)
    }

    @Test func anUnlistedCalendarUsesItsKnownName() throws {
        var a = Fix.items[0]
        a.calendarID = "shared"
        let sut = ActivityEditSection(
            draft: ActivityEditDraft(a, calendar: Fix.calendar, writable: ["work", "home"]), title: "Edit activity",
            accent: Night.tracker, categories: ActivityCategory.defaults, calendars: Fix.calendars, calendarNames: ["shared": "Team"],
            dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar, save: { _ in .saved(a.id) }, delete: nil, close: {}
        )
        #expect(try boxes(sut, "activity.calendar.").filter(\.on).map(\.label) == ["Team"])
    }

    @Test func pickingAnotherCalendarLeavesTheUnlistedOne() {
        var a = Fix.items[0]
        a.calendarID = "shared"
        var d = ActivityEditDraft(a, calendar: Fix.calendar, writable: ["work", "home"])
        d.pickCalendar("home")
        #expect(d.calendarChoice == .calendar("home"))
        d.pickCalendar(nil)
        #expect(d.calendarChoice == .none)
        d.pickCalendar("shared")
        #expect(d.calendarChoice == .keep)
    }

    @Test func theFieldsAreInOrder() throws {
        let sut = try section().inspect()
        for label in ["NAME", "START", "END", "LENGTH", "CATEGORY", "CALENDAR", "sets the end"] {
            #expect(throws: Never.self) { try sut.find(text: label) }
        }
        #expect(throws: Never.self) { try sut.find(text: "1h 30m") }
    }

    @Test func theChipLabelDropsAZeroMinuteRemainder() {
        #expect([15, 30, 60, 120, 90].map(Copywriter.activitiesChipLength) == ["15m", "30m", "1h", "2h", "1h 30m"])
    }

    @Test func theLengthChipsAreFifteenThirtyOneAndTwoHours() throws {
        #expect(try boxes(section(), "activity.length.").map(\.label) == ["15m", "30m", "1h", "2h"])
    }

    @Test(arguments: [(15, (9, 15)), (30, (9, 30)), (60, (10, 0)), (120, (11, 0))])
    func aLengthChipSetsTheEndFromTheStart(_ minutes: Int, _ end: (Int, Int)) {
        var d = ActivityEditDraft(Fix.items[0], calendar: Fix.calendar)
        d.setLength(minutes)
        #expect(d.lengthSeconds == TimeInterval(minutes * 60))
        #expect(d.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar).end == Fix.at(4, end.0, end.1))
    }

    @Test func aLengthPastMidnightStopsAtMidnight() {
        var d = ActivityEditDraft(start: Fix.at(4, 23), end: Fix.at(4, 23, 30), calendar: Fix.calendar)
        d.setLength(120)
        #expect(d.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar).end == Fix.key(5).start(in: Fix.calendar))
    }

    @Test func aCalendarFailureShowsTheErrorLineAndKeepsTheSectionOpen() throws {
        var closed = 0
        let sut = section(result: .calendarFailed(Fix.items[0].id), closed: { closed += 1 })
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: "Save") != nil }.tap()
        #expect(closed == 0)
        #expect(ActivityEditDraft.message(.calendarFailed(ActivityID())) == Copywriter.activitiesCalendarFailed)
        #expect(ActivityEditDraft.message(.calendarUnchanged(ActivityID())) == Copywriter.activitiesCalendarUnchanged)
        #expect(Copywriter.activitiesCalendarUnchanged == "Saved, but the calendar did not change. Check calendar access.")
    }

    @Test func theSectionShowsTheCalendarErrorLine() throws {
        let sut = ActivityEditSection(
            draft: ActivityEditDraft(Fix.items[0], calendar: Fix.calendar), title: "Edit activity", accent: Night.tracker,
            categories: ActivityCategory.defaults, calendars: Fix.calendars, dayStart: Fix.key(4).start(in: Fix.calendar),
            calendar: Fix.calendar, save: { _ in .saved(ActivityID()) }, delete: nil, close: {},
            message: ActivityEditDraft.message(.calendarFailed(Fix.items[0].id))
        )
        #expect(throws: Never.self) {
            try sut.inspect().find(text: "Saved, but the old calendar event could not be removed. Check calendar access.")
        }
    }
}
