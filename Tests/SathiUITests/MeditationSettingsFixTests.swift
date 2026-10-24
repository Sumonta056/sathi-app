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
    private func settings(_ h: EngineHarness) -> some View {
        SettingsView().environmentObject(h.engine)
    }

    private func strictnessPicker(_ view: some View, _ title: String) throws -> InspectableView<ViewType.Picker> {
        try view.inspect().find(ViewType.Picker.self) { try $0.labelView().text().string() == title }
    }

    private func optionTitles(_ picker: InspectableView<ViewType.Picker>) -> [String] {
        picker.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    @Test func chimeToggleSaysItPlaysAtTheEnd() throws {
        let h = EngineHarness { $0.prefs.meditation.enabled = true }
        let toggle = try settings(h).inspect().find(ViewType.Toggle.self) { try $0.labelView().text().string() == "Soft chime at the end" }
        try toggle.tap()
        #expect(!h.engine.data.prefs.meditation.chime)
    }

    @Test func readingPickerOffersNoStrictOption() throws {
        let h = EngineHarness()
        let options = try optionTitles(strictnessPicker(settings(h), "When I ignore Boi"))
        #expect(options.contains(Strictness.friendly.title))
        #expect(options.contains(Strictness.persistent.title))
        #expect(!options.contains(Strictness.strict.title))
    }

    @Test func waterPickerStillOffersStrict() throws {
        let h = EngineHarness()
        let options = try optionTitles(strictnessPicker(settings(h), "When I ignore Fota"))
        #expect(options.contains(Strictness.strict.title))
    }

    @Test func storedStrictReadingShowsPersistentSelected() throws {
        let h = EngineHarness { $0.prefs.reading.strictness = .strict }
        let picker = try strictnessPicker(settings(h), "When I ignore Boi")
        #expect(try picker.selectedValue(Strictness.self) == .persistent)
    }

    @Test func meditationReminderButtonIsDisabledWhileOff() throws {
        let h = EngineHarness()
        #expect(try settings(h).inspect().find(button: "Show meditation reminder now").isDisabled())
    }

    @Test func meditationReminderButtonIsEnabledWhileOn() throws {
        let h = EngineHarness { $0.prefs.meditation.enabled = true }
        #expect(try !settings(h).inspect().find(button: "Show meditation reminder now").isDisabled())
    }

    @Test func sessionViewShowsNothingWithoutASession() throws {
        let h = EngineHarness()
        let sut = SessionView().environmentObject(h.engine)
        #expect(throws: (any Error).self) { try sut.inspect().find(text: "READING · DO NOT DISTURB") }
        #expect(throws: (any Error).self) { try sut.inspect().find(text: "BREATHING") }
        #expect(throws: (any Error).self) { try sut.inspect().find(button: "Stop early (won't count)") }
    }
}
