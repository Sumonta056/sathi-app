import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Settings")
struct SettingsViewTests {
    private func tab(_ id: HabitID, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        switch id {
        case .water: return try hosted(WaterSettingsTab(), h).inspect()
        case .reading: return try hosted(ReadingSettingsTab(), h).inspect()
        case .meditation: return try hosted(MeditationSettingsTab(), h).inspect()
        }
    }

    private func harness(_ id: HabitID, on: Bool) -> EngineHarness {
        EngineHarness {
            $0.prefs.meditation.enabled = false
            switch id {
            case .water: $0.prefs.water.enabled = on
            case .reading: $0.prefs.reading.enabled = on
            case .meditation: $0.prefs.meditation.enabled = on
            }
        }
    }

    @Test func rootNameFieldEditsTheName() throws {
        let h = EngineHarness()
        try hosted(SettingsView(), h).inspect().find(ViewType.TextField.self).setInput("Asha")
        #expect(h.engine.data.prefs.general.name == "Asha")
    }

    @Test(arguments: HabitID.allCases)
    func showReminderNowTriggersThatHabit(_ id: HabitID) throws {
        let h = harness(id, on: true)
        try tab(id, h).find(button: "Show a reminder now").tap()
        #expect(h.engine.phase(id) == .bubble(.nudge))
        #expect(h.presenter.calls.contains(.showBubble(id, .nudge)))
    }

    @Test(arguments: HabitID.allCases)
    func showReminderNowIsDisabledWhileTheHabitIsOff(_ id: HabitID) throws {
        let h = harness(id, on: false)
        #expect(try tab(id, h).find(button: "Show a reminder now").isDisabled())
    }

    @Test func readingTimeMenuShowsTheSetTime() throws {
        let sut = try hosted(ReadingSettingsTab(), EngineHarness { $0.prefs.reading.timeMinutes = 21 * 60 }).inspect()
        #expect(throws: Never.self) { try sut.find(text: Fmt.timeOfDay(21 * 60)) }
    }
}
