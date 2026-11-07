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

    @Test func chimeSwitchSaysItPlaysAtStartAndEnd() throws {
        let h = EngineHarness { $0.prefs.meditation.enabled = true }
        let sut = try hosted(MeditationSettingsTab(), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Soft bell at start and end") }
        try Find.button(sut, label: "Soft bell at start and end").tap()
        #expect(!h.engine.data.prefs.meditation.chime)
    }

    @Test func readingOffersGentleNudgyAndStrict() throws {
        let sut = try reading(EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: Strictness.friendly.title) }
        #expect(throws: Never.self) { try sut.find(text: Strictness.persistent.title) }
        #expect(throws: Never.self) { try sut.find(text: Strictness.strict.title) }
        #expect(throws: Never.self) { try sut.find(text: Strictness.strict.detail) }
    }

    @Test func readingStrictCardSetsStrict() throws {
        let h = EngineHarness()
        try Find.button(reading(h), holding: "Strict").tap()
        #expect(h.store.prefs.reading.strictness == .strict)
    }

    @Test func waterStillOffersStrict() throws {
        let sut = try hosted(WaterSettingsTab(), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Strict") }
    }

    @Test func storedStrictReadingShowsStrictSelected() throws {
        let sut = try reading(EngineHarness { $0.prefs.reading.strictness = .strict })
        #expect(try A11y.isSelected(Find.button(sut, holding: "Strict")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "Nudgy")))
    }

    @Test func meditationReminderButtonIsDisabledWhileOff() throws {
        let sut = try hosted(MeditationSettingsTab(), EngineHarness()).inspect()
        #expect(try sut.find(button: "Show a reminder now").isDisabled())
    }

    @Test func meditationReminderButtonIsEnabledWhileOn() throws {
        let sut = try hosted(MeditationSettingsTab(), EngineHarness { $0.prefs.meditation.enabled = true }).inspect()
        #expect(try !sut.find(button: "Show a reminder now").isDisabled())
    }

    @Test(arguments: [HabitID.reading, .meditation])
    func sessionViewShowsNothingWithoutASession(_ id: HabitID) throws {
        let h = EngineHarness()
        let sut = SessionView(id: id).environmentObject(h.engine)
        #expect(throws: (any Error).self) { try sut.inspect().find(text: "READING · DO NOT DISTURB") }
        #expect(throws: (any Error).self) { try sut.inspect().find(text: "BREATHING") }
        #expect(throws: (any Error).self) { try sut.inspect().find(button: "Stop early (won't count)") }
    }
}
