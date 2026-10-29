import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick settings card")
struct QuickSettingsCardTests {
    private func tab(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(GeneralTab(), h).inspect()
    }

    @Test func hasTheTitleAndTheSwitchLabel() throws {
        let sut = try tab(EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: "QUICK REMINDERS") }
        #expect(throws: Never.self) { try sut.find(text: "Show a close button") }
    }

    @Test func defaultIsNudgy() throws {
        let sut = try tab(EngineHarness())
        #expect(try A11y.isSelected(Find.button(sut, holding: "Nudgy")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "Strict")))
    }

    @Test func pickStrictSaves() throws {
        let h = EngineHarness()
        try Find.button(tab(h), holding: "Strict").tap()
        #expect(h.engine.data.prefs.quick.strictness == .strict)
    }

    @Test func switchSaves() throws {
        let h = EngineHarness()
        try Find.button(tab(h), label: "Show a close button").tap()
        #expect(h.engine.data.prefs.quick.showsCloseButton == false)
    }
}
