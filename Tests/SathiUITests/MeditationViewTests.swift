import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Meditation views")
struct MeditationViewTests {
    private func harness(at start: Date = day(2026, 3, 4, 7)) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
        }
    }

    @Test func meditationUsesThePebbleBuddy() {
        #expect(HabitID.meditation.kind == .pebble)
    }

    @Test func habitCardBreatheStartsMeditation() throws {
        let h = harness()
        let sut = HabitCard(id: .meditation).environmentObject(h.engine)
        try MenuFind.control(sut.inspect(), "Breathe").tap()
        #expect(h.engine.phase(.meditation) == .session)
    }

    @Test func panelShowsAMeditationCardWhenEnabled() throws {
        let h = harness()
        let sut = MenuPanel().environmentObject(h.engine)
        #expect(try sut.inspect().findAll(HabitCard.self).count == 3)
    }

    @Test func readingSessionHasNoBreathingPhase() throws {
        let h = harness()
        h.engine.startReading()
        let sut = SessionView(id: .reading).environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "READING · DO NOT DISTURB") != nil)
        #expect(throws: (any Error).self) { try sut.inspect().find(text: "Breathe in") }
    }

    @Test func settingsHaveAMeditationTab() throws {
        let h = harness()
        let sut = MeditationSettingsTab().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "SHANTI · MEDITATION") != nil)
        #expect(try sut.inspect().find(text: "Pause. Breathe. Come back.") != nil)
    }

    @Test func settingsShowMeditationReminderNow() throws {
        let h = harness()
        let sut = MeditationSettingsTab().environmentObject(h.engine)
        try sut.inspect().find(button: "Show a reminder now").tap()
        #expect(h.engine.phase(.meditation) == .bubble(.nudge))
    }
}
