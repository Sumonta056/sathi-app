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
        #expect(h.engine.phase == .session(.meditation))
    }

    @Test func panelShowsAMeditationCardWhenEnabled() throws {
        let h = harness()
        let sut = MenuPanel().environmentObject(h.engine)
        #expect(try sut.inspect().findAll(HabitCard.self).count == 3)
    }

    @Test func bubbleStartsTheBreathingSession() throws {
        let h = harness(at: day(2026, 3, 4, 15))
        let sut = BubbleView(id: .meditation, level: .nudge).environmentObject(h.engine)
        try sut.inspect().find(button: "Start 5-min breathing").tap()
        #expect(h.engine.phase == .session(.meditation))
    }

    @Test func sessionShowsBreathingTitleAndAPhase() throws {
        let h = harness()
        h.engine.startMeditation()
        let sut = SessionView().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "BREATHING") != nil)
        #expect(throws: (any Error).self) { try sut.inspect().find(text: "READING · DO NOT DISTURB") }
        let phases = ["Breathe in", "Hold", "Breathe out", "Rest"]
        let shown = phases.filter { (try? sut.inspect().find(text: $0)) != nil }
        #expect(shown.count == 1)
    }

    @Test func readingSessionHasNoBreathingPhase() throws {
        let h = harness()
        h.engine.startReading()
        let sut = SessionView().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "READING · DO NOT DISTURB") != nil)
        #expect(throws: (any Error).self) { try sut.inspect().find(text: "Breathe in") }
    }

    @Test func celebrationShowsMinutesOfCalm() throws {
        let h = harness()
        h.engine.startMeditation()
        h.advance(minutes: 5)
        let sut = CelebrateView().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "5 min calm") != nil)
        #expect(try sut.inspect().find(text: h.engine.celebration.title) != nil)
        #expect(try sut.inspect().find(text: "Back to work") != nil)
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
        #expect(h.engine.phase == .bubble(.meditation, .nudge))
    }
}
