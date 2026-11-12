import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity edit form")
struct ActivityEditFormTests {
    typealias Fix = ActivityViewSupport

    private func form(result: ActivityEditResult, saved: @escaping (ActivityEdit) -> Void, closed: @escaping () -> Void) -> ActivityEditForm {
        let activity = Fix.items[0]
        return ActivityEditForm(
            draft: ActivityEditDraft(activity, calendar: Fix.calendar),
            categories: ActivityCategory.defaults,
            dayStart: Fix.key(4).start(in: Fix.calendar),
            calendar: Fix.calendar,
            save: { saved($0); return result },
            delete: nil,
            close: closed
        )
    }

    private func press(_ sut: ActivityEditForm, _ title: String) throws {
        try sut.inspect().find(ViewType.Button.self) { try $0.labelView().find(text: title) != nil }.tap()
    }

    @Test func saveSendsTheEditedTimes() throws {
        var edit: ActivityEdit?
        try press(form(result: .saved(ActivityID()), saved: { edit = $0 }, closed: {}), "Save")
        #expect(edit?.start == Fix.at(4, 9))
        #expect(edit?.end == Fix.at(4, 10, 30))
        #expect(edit?.text == "Fix login bug")
    }

    @Test func aSavedEditClosesTheForm() throws {
        var closed = 0
        try press(form(result: .saved(ActivityID()), saved: { _ in }, closed: { closed += 1 }), "Save")
        #expect(closed == 1)
    }

    @Test func anOverlapKeepsTheFormOpen() throws {
        var closed = 0
        try press(form(result: .overlap, saved: { _ in }, closed: { closed += 1 }), "Save")
        #expect(closed == 0)
    }

    @Test func cancelClosesWithoutSaving() throws {
        var saves = 0
        var closed = 0
        try press(form(result: .saved(ActivityID()), saved: { _ in saves += 1 }, closed: { closed += 1 }), "Cancel")
        #expect(saves == 0)
        #expect(closed == 1)
    }
}
