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

    @Test func showsTheGoalAndRhythmRows() throws {
        let sut = try tab(harness())
        for text in ["Daily goal", "Each session", "Remind me every", "Between", "IF I IGNORE SHANTI"] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
    }

    @Test func goalChipSetsTheDailyGoal() throws {
        let h = harness()
        try tab(h).find(button: "20 min").tap()
        #expect(h.engine.data.prefs.meditation.dailyGoalMinutes == 20)
    }

    @Test func aSavedValueOutsideTheChipsStillShowsAsSelected() throws {
        let h = harness {
            $0.prefs.meditation.dailyGoalMinutes = 4
            $0.prefs.meditation.sessionMinutes = 15
        }
        let sut = try tab(h)
        #expect(try A11y.isSelected(sut.find(button: "4 min")))
        #expect(try A11y.isSelected(sut.find(button: "15 min")))
    }

    @Test func sessionChipSetsTheSessionLength() throws {
        let h = harness()
        try tab(h).find(button: "1 min").tap()
        #expect(h.engine.data.prefs.meditation.sessionMinutes == 1)
    }

    @Test func intervalChipSetsTheInterval() throws {
        let h = harness()
        try tab(h).find(button: "90 min").tap()
        #expect(h.engine.data.prefs.meditation.intervalMinutes == 90)
    }

    @Test func strictCardIsOfferedAndSetsStrict() throws {
        let h = harness()
        try Find.button(tab(h), holding: "Strict").tap()
        #expect(h.engine.data.prefs.meditation.strictness == .strict)
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
        #expect(try sut.find(button: "20 min").isDisabled())
        #expect(try Find.button(sut, label: "Chime").isDisabled())
    }
}
