import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Sound page")
struct SoundPageTests {
    private func page(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(SettingsPageView(page: .sound), h).inspect()
    }

    @Test func showsTheSoftSoundsSwitchAndTheSessionSoundCard() throws {
        let sut = try page(EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: "Play soft sounds") }
        #expect(throws: Never.self) { try sut.find(MeditationSoundCard.self) }
        #expect(throws: Never.self) { try sut.find(text: "Voice guide") }
    }

    @Test func softSoundsSwitchTurnsSoundOff() throws {
        let h = EngineHarness()
        try Find.button(page(h), label: "Sounds").tap()
        #expect(!h.engine.data.prefs.general.soundOn)
    }

    @Test func generalPageNoLongerHasTheSoundSwitch() throws {
        let sut = try hosted(GeneralTab(), EngineHarness()).inspect()
        #expect(Find.lacks(sut, text: "Play soft sounds"))
        #expect(sut.findAll(QuickSettingsCard.self).isEmpty)
    }

    @Test func shantiPageLinksToTheSoundPage() throws {
        let h = EngineHarness { $0.prefs.meditation.enabled = true }
        let sut = try hosted(MeditationSettingsTab(), h).inspect()
        #expect(sut.findAll(MeditationSoundCard.self).isEmpty)
        try Find.button(sut, holding: "Session sound is on the Sound page.").tap()
        #expect(h.presenter.calls.last == .showMain(.settings(.sound)))
    }
}
