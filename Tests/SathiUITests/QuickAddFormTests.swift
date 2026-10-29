import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick add form")
struct QuickAddFormTests {
    private func form(
        _ h: EngineHarness,
        text: String = "",
        chip: Int? = 15,
        time: Date? = nil
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(QuickAddForm(text: text, chip: chip, time: time, onClose: {}), h).inspect()
    }

    @Test func formDefaultsToFifteen() throws {
        let sut = try form(Quick.harness())
        #expect(throws: Never.self) { try sut.find(text: "Today at " + Quick.clock(day(2026, 3, 4, 10, 15))) }
        #expect(QuickAddForm.defaultChip == 15)
    }

    @Test func formShowsItsLabelsAndHint() throws {
        let sut = try form(Quick.harness())
        for line in ["New quick reminder", "REMIND ME TO", "WHEN", "or at", "A time that has passed today goes to tomorrow.", "0 / 80"] {
            #expect(throws: Never.self) { try sut.find(text: line) }
        }
        for chip in ["5 min", "15 min", "30 min", "1 hour"] {
            #expect(throws: Never.self) { try sut.find(button: chip) }
        }
    }

    @Test func addButtonDisabledWhenBlank() throws {
        let sut = try form(Quick.harness(), text: "   ")
        #expect(try sut.find(button: "Add reminder").isDisabled())
        let filled = try form(Quick.harness(), text: "Call mom")
        #expect(try !filled.find(button: "Add reminder").isDisabled())
    }

    @Test func addCallsEngine() throws {
        let h = Quick.harness()
        try form(h, text: "Call mom", chip: 30).find(button: "Add reminder").tap()
        #expect(h.engine.quickReminders.map(\.text) == ["Call mom"])
        #expect(h.engine.quickReminders.first?.due == day(2026, 3, 4, 10, 30))
    }

    @Test func returnInTheTextFieldAdds() throws {
        let h = Quick.harness()
        try form(h, text: "Call mom", chip: 5).find(ViewType.TextField.self).callOnSubmit()
        #expect(h.engine.quickReminders.count == 1)
    }

    @Test func timeClearsChip() throws {
        let h = Quick.harness()
        let sut = try form(h, chip: nil, time: day(2026, 3, 4, 14, 37))
        #expect(throws: Never.self) { try sut.find(text: "Today at " + Quick.clock(day(2026, 3, 4, 14, 37))) }
        let cal = Calendar.current
        #expect(QuickAddForm.when(chip: nil, time: day(2026, 3, 4, 14, 37), calendar: cal) == .at(minutes: 14 * 60 + 37))
        #expect(QuickAddForm.when(chip: 30, time: day(2026, 3, 4, 14, 37), calendar: cal) == .inMinutes(30))
    }

    @Test func pickedTimeAddsAtThatTime() throws {
        let h = Quick.harness()
        try form(h, text: "Meet", chip: nil, time: day(2026, 3, 4, 14, 37)).find(button: "Add reminder").tap()
        #expect(h.engine.quickReminders.first?.due == day(2026, 3, 4, 14, 37))
    }

    @Test func pastTimePreviewsTomorrow() throws {
        let sut = try form(Quick.harness(), chip: nil, time: day(2026, 3, 4, 8, 0))
        #expect(throws: Never.self) { try sut.find(text: "Tomorrow at " + Quick.clock(day(2026, 3, 5, 8, 0))) }
    }

    @Test func fullFormShowsMessage() throws {
        let sut = try form(Quick.harness(Quick.many(Limits.quickMax)), text: "More")
        #expect(throws: Never.self) { try sut.find(text: "You have 20 quick reminders. Delete one to add more.") }
        #expect(Find.lacks(sut, text: "Add reminder"))
        #expect(throws: Never.self) { try sut.find(button: "Cancel") }
    }

    @Test func textStopsAtEighty() {
        let long = String(repeating: "a", count: 120)
        #expect(QuickAddForm.capped(long).count == Limits.quickTextMax)
        #expect(QuickAddForm.capped("short") == "short")
    }

    @Test func counterShowsLength() throws {
        let sut = try form(Quick.harness(), text: "Call mom")
        #expect(throws: Never.self) { try sut.find(text: "8 / 80") }
    }
}
