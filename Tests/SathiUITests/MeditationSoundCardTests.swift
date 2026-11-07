import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Meditation sound card")
struct MeditationSoundCardTests {
    private func harness(_ configure: @escaping (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness {
            $0.prefs.meditation.enabled = true
            configure(&$0)
        }
    }

    private func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(MeditationSoundCard(), h).inspect()
    }

    private func slider(_ sut: InspectableView<ViewType.ClassifiedView>, _ name: String) throws -> InspectableView<ViewType.Slider> {
        try sut.find(viewWithAccessibilityLabel: "\(name) volume").find(ViewType.Slider.self)
    }

    private func hasSlider(_ sut: InspectableView<ViewType.ClassifiedView>, _ name: String) -> Bool {
        (try? sut.find(viewWithAccessibilityLabel: "\(name) volume")) != nil
    }

    @Test func showsTheRowsAndHints() throws {
        let sut = try card(harness())
        for text in [
            "Voice guide", "Music", "Soft bell at start and end", "Soft tick every minute", "Preview",
            "Shanti says each phase once. She never counts.", "Plays softly under the voice."
        ] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
    }

    @Test func voiceSwitchFlipsVoiceOn() throws {
        let h = harness()
        try Find.button(card(h), label: "Voice guide").tap()
        #expect(!h.engine.data.prefs.meditation.voiceOn)
    }

    @Test func musicSwitchFlipsMusicOn() throws {
        let h = harness()
        try Find.button(card(h), label: "Music").tap()
        #expect(!h.engine.data.prefs.meditation.musicOn)
    }

    @Test func bellSwitchFlipsChime() throws {
        let h = harness()
        try Find.button(card(h), label: "Soft bell at start and end").tap()
        #expect(!h.engine.data.prefs.meditation.chime)
    }

    @Test func tickSwitchFlipsMinuteTick() throws {
        let h = harness()
        try Find.button(card(h), label: "Soft tick every minute").tap()
        #expect(h.engine.data.prefs.meditation.minuteTick)
    }

    @Test func voiceSliderSetsVoiceVolume() throws {
        let h = harness { $0.prefs.meditation.musicOn = false }
        let sut = try card(h)
        #expect(!hasSlider(sut, "Music"))
        try slider(sut, "Voice guide").setValue(0.3)
        #expect(h.engine.data.prefs.meditation.voiceVolume == 0.3)
    }

    @Test func musicSliderSetsMusicVolume() throws {
        let h = harness { $0.prefs.meditation.voiceOn = false }
        let sut = try card(h)
        #expect(!hasSlider(sut, "Voice guide"))
        try slider(sut, "Music").setValue(0.4)
        #expect(h.engine.data.prefs.meditation.musicVolume == 0.4)
    }

    @Test func bothSlidersShowWhenBothSwitchesAreOn() throws {
        let sut = try card(harness())
        #expect(hasSlider(sut, "Voice guide") && hasSlider(sut, "Music"))
    }

    @Test func slidersHideWhenTheirSwitchesAreOff() throws {
        let h = harness {
            $0.prefs.meditation.voiceOn = false
            $0.prefs.meditation.musicOn = false
        }
        let sut = try card(h)
        #expect(!hasSlider(sut, "Voice guide") && !hasSlider(sut, "Music"))
    }

    @Test func previewPlaysTheSessionSound() throws {
        let h = harness()
        try card(h).find(button: "Preview").tap()
        guard case .preview = h.audio.calls.last else {
            Issue.record("expected a preview call")
            return
        }
    }

    @Test func previewIsDisabledWhenSoundIsOff() throws {
        let h = harness { $0.prefs.general.soundOn = false }
        #expect(try card(h).find(button: "Preview").isDisabled())
    }
}
