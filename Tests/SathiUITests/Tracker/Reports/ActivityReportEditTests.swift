import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity report edits")
struct ActivityReportEditTests {
    typealias Fix = ActivityViewSupport

    private static let work = Fix.item("Fix login bug", "Coding", 4, (9, 0), (10, 30))
    private static let away = Activity(kind: .away, text: "Away", start: Fix.at(4, 12), end: Fix.at(4, 13), awayPlace: .walk)
    private static let block = Activity(kind: .timeBlock, text: "Deep work", start: Fix.at(4, 14), end: Fix.at(4, 15))

    private func row(_ a: Activity, running: Bool = false, deleted: @escaping (ActivityID) -> Void = { _ in }) -> ActivityTimelineRow {
        ActivityTimelineRow(
            activity: a, running: running, categories: ActivityCategory.defaults, calendar: Fix.calendar,
            onDelete: { deleted(a.id) }
        )
    }

    private func labelled(_ v: some View, _ label: String) throws -> Bool {
        (try? v.inspect().find(viewWithAccessibilityLabel: label)) != nil
    }

    @Test(arguments: [(work, false, true), (away, false, true), (block, false, false), (work, true, false)])
    func editShowsOnlyOnEditableRows(_ a: Activity, _ running: Bool, _ shows: Bool) {
        #expect(ActivityTimelineRow.canEdit(a, running: running) == shows)
    }

    @Test func anAwayRowHasAPencil() throws {
        #expect(try labelled(row(Self.away), "Edit Away · Walk"))
    }

    @Test func theRunningRowHasNoPencil() throws {
        #expect(try !labelled(row(Self.work, running: true), "Edit Fix login bug"))
    }

    @Test func aTimeBlockRowHasDeleteButNoPencil() throws {
        var deleted: [ActivityID] = []
        let sut = row(Self.block) { deleted.append($0) }
        #expect(try !labelled(sut, "Edit Deep work"))
        try Find.button(sut.inspect(), label: "Delete Deep work").tap()
        #expect(deleted == [Self.block.id])
    }

    @Test(arguments: [(15, 46.0), (60, 52.0), (180, 68.0), (420, 88.0), (600, 88.0)])
    func theRowHeightGrowsWithTheLengthUpToTheMax(_ minutes: Int, _ height: Double) {
        let a = Activity(text: "x", start: Fix.at(4, 9), end: Fix.at(4, 9).addingTimeInterval(TimeInterval(minutes * 60)))
        #expect(ActivityTimelineRow.height(a) == CGFloat(height))
    }

    @Test func anAwayRowUsesTheSameHeightRule() {
        let end = Fix.at(4, 9).addingTimeInterval(2 * 3600 + 58 * 60)
        let away = Activity(kind: .away, text: "Away", start: Fix.at(4, 9), end: end)
        let work = Activity(text: "x", start: Fix.at(4, 9), end: end)
        #expect(ActivityTimelineRow.height(away) == ActivityTimelineRow.height(work))
        #expect(abs(ActivityTimelineRow.height(away) - 67.73) < 0.01)
    }

    @Test func aRowShowsItsCategoryLengthAndCalendar() throws {
        var a = Self.work
        a.calendarID = "work"
        a.eventID = "ev1"
        let sut = try ActivityTimelineRow(activity: a, categories: ActivityCategory.defaults, calendar: Fix.calendar, calendarName: "Work").inspect()
        #expect(throws: Never.self) { try sut.find(text: "Fix login bug") }
        #expect(throws: Never.self) { try sut.find(text: "Coding") }
        #expect(throws: Never.self) { try sut.find(text: "1h 30m") }
        #expect(throws: Never.self) { try sut.find(text: "Work") }
    }

    @Test func aRowWithACalendarButNoEventShowsTheNotInCalendarHint() throws {
        var a = Self.work
        a.calendarID = "work"
        let sut = try ActivityTimelineRow(activity: a, categories: ActivityCategory.defaults, calendar: Fix.calendar, calendarName: "Work").inspect()
        #expect(throws: Never.self) { try sut.find(text: "Not in calendar") }
        #expect(Find.lacks(sut, text: "Work"))
    }

    @Test func aRowWithoutAnEventShowsNoCalendar() throws {
        let sut = try ActivityTimelineRow(activity: Self.work, categories: ActivityCategory.defaults, calendar: Fix.calendar, calendarName: "Work")
            .inspect()
        #expect(Find.lacks(sut, text: "Work"))
    }

    @Test func anAwayDraftSendsItsPlace() {
        let d = ActivityEditDraft(Self.away, calendar: Fix.calendar)
        #expect(d.isAway)
        let e = d.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar)
        #expect(e.awayPlace == .walk)
        #expect(e.start == Fix.at(4, 12))
        #expect(e.end == Fix.at(4, 13))
    }

    @Test func anAwaySectionShowsThePlaceChipsAndNoTextCategoryOrCalendar() throws {
        let sut = ActivityEditSection(
            draft: ActivityEditDraft(Self.away, calendar: Fix.calendar), title: "Edit activity", accent: Night.chipText,
            categories: ActivityCategory.defaults, calendars: Fix.calendars, dayStart: Fix.key(4).start(in: Fix.calendar),
            calendar: Fix.calendar, save: { _ in .saved(ActivityID()) }, delete: { true }, close: {}
        )
        let v = try sut.inspect()
        for place in AwayPlace.choices {
            #expect(throws: Never.self) { try v.find(text: Copywriter.trackerAwayPlace(place)) }
        }
        #expect(Find.lacks(v, text: Copywriter.trackerAwayPlace(.breakTime)))
        #expect(Find.lacks(v, text: "CATEGORY"))
        #expect(Find.lacks(v, text: "CALENDAR"))
        #expect(throws: (any Error).self) { try v.find(LazyTextField.self) }
    }

    @Test func newRefusalsHaveTheirCopy() {
        #expect(ActivityEditDraft.message(.crossesMidnight) == "An activity cannot cross midnight.")
        #expect(ActivityEditDraft.message(.inFuture) == Copywriter.trackerEditInFuture)
    }
}
