import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Meditation settings fixes")
struct MeditationSettingsFixTests {
    private func reading(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(ReadingSettingsTab(), h).inspect()
    }

    @Test func chimeSwitchSaysItPlaysAtTheEnd() throws {
        let h = EngineHarness { $0.prefs.meditation.enabled = true }
        let sut = try hosted(MeditationSettingsTab(), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Soft chime at the end") }
        try Find.button(sut, label: "Chime").tap()
        #expect(!h.engine.data.prefs.meditation.chime)
    }

    @Test func readingOffersOnlyGentleAndNudgy() throws {
        let sut = try reading(EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: Strictness.friendly.title) }
        #expect(throws: Never.self) { try sut.find(text: Strictness.persistent.title) }
        #expect(Find.lacks(sut, text: "Strict"))
        #expect(Find.lacks(sut, text: Strictness.strict.detail))
    }

    @Test func waterStillOffersStrict() throws {
        let sut = try hosted(WaterSettingsTab(), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Strict") }
    }

    @Test func storedStrictReadingShowsNudgySelected() throws {
        let sut = try reading(EngineHarness { $0.prefs.reading.strictness = .strict })
        #expect(try A11y.isSelected(Find.button(sut, holding: "Nudgy")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "Gentle")))
    }

    @Test func meditationReminderButtonIsDisabledWhileOff() throws {
        let sut = try hosted(MeditationSettingsTab(), EngineHarness()).inspect()
        #expect(try sut.find(button: "Show a reminder now").isDisabled())
    }

    @Test func meditationReminderButtonIsEnabledWhileOn() throws {
        let sut = try hosted(MeditationSettingsTab(), EngineHarness { $0.prefs.meditation.enabled = true }).inspect()
        #expect(try !sut.find(button: "Show a reminder now").isDisabled())
    }

    @Test func sessionViewShowsNothingWithoutASession() throws {
        let h = EngineHarness()
        let sut = SessionView().environmentObject(h.engine)
        #expect(throws: (any Error).self) { try sut.inspect().find(text: "READING · DO NOT DISTURB") }
        #expect(throws: (any Error).self) { try sut.inspect().find(text: "BREATHING") }
        #expect(throws: (any Error).self) { try sut.inspect().find(button: "Stop early (won't count)") }
    }
}
