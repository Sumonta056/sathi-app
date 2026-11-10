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

    private func row(_ a: Activity, running: Bool = false, deleted: @escaping (ActivityID) -> Void = { _ in }) -> ActivityLogRowView {
        ActivityLogRowView(
            row: .activity(a, running: running), categories: ActivityCategory.defaults, calendar: Fix.calendar,
            onEdit: {}, onDelete: deleted, onFill: { _ in }, onSaveToCalendar: { _ in }
        )
    }

    private func buttons(_ v: some View, _ title: String) throws -> Int {
        try v.inspect().findAll(ViewType.Button.self) { try $0.labelView().find(text: title) != nil }.count
    }

    @Test(arguments: [(work, false, true), (away, false, true), (block, false, false), (work, true, false)])
    func editShowsOnlyOnEditableRows(_ a: Activity, _ running: Bool, _ shows: Bool) {
        #expect(ActivityLogRowView.canEdit(a, running: running) == shows)
    }

    @Test func anAwayRowHasEdit() throws {
        #expect(try buttons(row(Self.away), "Edit") == 1)
    }

    @Test func theRunningRowHasNoEdit() throws {
        #expect(try buttons(row(Self.work, running: true), "Edit") == 0)
    }

    @Test func aTimeBlockRowHasDeleteButNoEdit() throws {
        var deleted: [ActivityID] = []
        let sut = row(Self.block) { deleted.append($0) }
        #expect(try buttons(sut, "Edit") == 0)
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: "Delete") != nil }.tap()
        #expect(deleted == [Self.block.id])
    }

    @Test func anAwayDraftSendsItsPlace() {
        let d = ActivityEditDraft(Self.away, calendar: Fix.calendar)
        #expect(d.isAway)
        let e = d.edit(dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar)
        #expect(e.awayPlace == .walk)
        #expect(e.start == Fix.at(4, 12))
        #expect(e.end == Fix.at(4, 13))
    }

    @Test func anAwayFormShowsThePlaceChipsAndNoTextOrCategory() throws {
        let sut = ActivityEditForm(
            draft: ActivityEditDraft(Self.away, calendar: Fix.calendar), categories: ActivityCategory.defaults,
            dayStart: Fix.key(4).start(in: Fix.calendar), calendar: Fix.calendar,
            save: { _ in .saved(ActivityID()) }, delete: {}, close: {}
        )
        let v = try sut.inspect()
        for place in AwayPlace.allCases {
            #expect(throws: Never.self) { try v.find(text: Copywriter.trackerAwayPlace(place)) }
        }
        #expect(throws: (any Error).self) { try v.find(text: Copywriter.trackerNoCategory) }
        #expect(throws: (any Error).self) { try v.find(LazyTextField.self) }
    }

    @Test func newRefusalsHaveTheirCopy() {
        #expect(ActivityEditDraft.message(.crossesMidnight) == "An activity cannot cross midnight.")
        #expect(ActivityEditDraft.message(.inFuture) == Copywriter.trackerEditInFuture)
    }
}
