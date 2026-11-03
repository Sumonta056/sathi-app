import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Snooze limit settings")
struct SnoozeLimitSettingsTests {
    private func tab(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(GeneralTab(), h).inspect()
    }

    @Test func rowShowsNoLimitByDefault() throws {
        let sut = try tab(EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: "Snoozes allowed") }
        #expect(throws: Never.self) { try sut.find(text: "No limit") }
    }

    @Test func rowShowsTheSavedLimit() throws {
        let sut = try tab(EngineHarness { $0.prefs.general.snoozeLimit = 3 })
        #expect(throws: Never.self) { try sut.find(text: "3") }
        #expect(Find.lacks(sut, text: "No limit"))
    }

    @Test func rowHasAStepper() throws {
        let sut = try tab(EngineHarness { $0.prefs.general.snoozeLimit = 3 })
        #expect(throws: Never.self) { try Find.button(sut, label: "More", near: "Snoozes allowed") }
        #expect(throws: Never.self) { try Find.button(sut, label: "Less", near: "Snoozes allowed") }
    }
}
