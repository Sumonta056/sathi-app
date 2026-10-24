import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("General tab")
struct GeneralTabTests {
    private func tab(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(GeneralTab(), h).inspect()
    }

    @Test func showsTitleAndSubtitle() throws {
        let sut = try tab(EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: "Hi there") }
        #expect(throws: Never.self) { try sut.find(text: "A few things that apply to every buddy.") }
    }

    @Test func nameFieldEditsTheName() throws {
        let h = EngineHarness()
        try tab(h).find(ViewType.TextField.self).setInput("Asha")
        #expect(h.engine.data.prefs.general.name == "Asha")
        #expect(h.store.prefs.general.name == "Asha")
    }

    @Test func snoozeMoreRaisesSnoozeByOne() throws {
        let h = EngineHarness()
        try Find.button(tab(h), label: "More", near: "Snooze for").tap()
        #expect(h.engine.data.prefs.general.snoozeMinutes == 6)
        #expect(h.engine.data.prefs.general.ignoreMinutes == 5)
    }

    @Test func snoozeMoreStopsAtTheUpperBound() throws {
        let top = Limits.snoozeMinutes.upperBound
        let h = EngineHarness { $0.prefs.general.snoozeMinutes = top }
        let more = try Find.button(tab(h), label: "More", near: "Snooze for")
        try? more.tap()
        #expect(h.engine.data.prefs.general.snoozeMinutes == top)
    }

    @Test func ignoreLessLowersIgnoreByOne() throws {
        let h = EngineHarness()
        try Find.button(tab(h), label: "Less", near: "Count it as a snooze after").tap()
        #expect(h.engine.data.prefs.general.ignoreMinutes == 4)
        #expect(h.engine.data.prefs.general.snoozeMinutes == 5)
    }

    @Test func snoozeValueIsShown() throws {
        let sut = try tab(EngineHarness { $0.prefs.general.ignoreMinutes = 7 })
        #expect(throws: Never.self) { try sut.find(text: "5 min") }
        #expect(throws: Never.self) { try sut.find(text: "7 min") }
    }

    @Test func soundsSwitchTurnsSoundOff() throws {
        let h = EngineHarness()
        try Find.button(tab(h), label: "Sounds").tap()
        #expect(!h.engine.data.prefs.general.soundOn)
    }

    @Test func quietInMeetingsIsOffAndDisabled() throws {
        let sut = try Find.button(tab(EngineHarness()), label: "Quiet in meetings")
        #expect(sut.isDisabled())
        #expect(!A11y.isSelected(sut))
    }

    @Test func onlyNightSproutThemeIsEnabled() throws {
        let sut = try tab(EngineHarness())
        #expect(try !Find.button(sut, holding: "Night sprout").isDisabled())
        #expect(try A11y.isSelected(Find.button(sut, holding: "Night sprout")))
        #expect(try Find.button(sut, holding: "Morning dew").isDisabled())
        #expect(try Find.button(sut, holding: "Follow macOS").isDisabled())
    }
}
