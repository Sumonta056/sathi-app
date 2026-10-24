import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Meditation settings tab")
struct MeditationSettingsTabTests {
    private func harness(_ configure: @escaping (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness {
            $0.prefs.meditation.enabled = true
            configure(&$0)
        }
    }

    private func tab(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(MeditationSettingsTab(), h).inspect()
    }

    @Test func showsTheHero() throws {
        let sut = try tab(harness())
        #expect(throws: Never.self) { try sut.find(text: "SHANTI · MEDITATION") }
        #expect(throws: Never.self) { try sut.find(text: "Pause. Breathe. Come back.") }
    }

    @Test func slotChipAddsASlot() throws {
        let h = harness()
        try tab(h).find(button: "Afternoon").tap()
        #expect(h.engine.data.prefs.meditation.slots == [.morning, .afternoon, .evening])
    }

    @Test func slotChipRemovesASlot() throws {
        let h = harness()
        try tab(h).find(button: "Morning").tap()
        #expect(h.engine.data.prefs.meditation.slots == [.evening])
    }

    @Test func lastSlotCannotBeRemoved() throws {
        let h = harness { $0.prefs.meditation.slots = [.evening] }
        try tab(h).find(button: "Evening").tap()
        #expect(h.engine.data.prefs.meditation.slots == [.evening])
    }

    @Test func selectedSlotsHaveTheSelectedTrait() throws {
        let sut = try tab(harness())
        #expect(try A11y.isSelected(sut.find(button: "Morning")))
        #expect(try !A11y.isSelected(sut.find(button: "Afternoon")))
    }

    @Test func windDownSetsRelax() throws {
        let h = harness()
        try Find.button(tab(h), holding: "Wind down").tap()
        #expect(h.engine.data.prefs.meditation.style == .relax)
    }

    @Test func patternCardsShowTitlesAndDetails() throws {
        let sut = try tab(harness())
        for text in ["Box", "Steady and calm.", "Wind down", "Good before sleep.", "Even", "Simple in and out."] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
    }

    @Test func boxBeatsAreShown() throws {
        #expect(throws: Never.self) { try tab(harness()).find(text: "4·4·4·4") }
    }

    @Test func chimeSwitchFlipsChime() throws {
        let h = harness()
        try Find.button(tab(h), label: "Chime").tap()
        #expect(!h.engine.data.prefs.meditation.chime)
    }

    @Test func sectionsAreDisabledWhileMeditationIsOff() throws {
        let sut = try tab(EngineHarness())
        #expect(try sut.find(button: "Morning").isDisabled())
        #expect(try Find.button(sut, label: "Chime").isDisabled())
    }
}
