import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine meditation display")
struct EngineMeditationDisplayTests {
    private func harness(at start: Date = day(2026, 3, 4, 7)) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
        }
    }

    @Test func sessionMakesMeditationTheActiveFocus() {
        let h = harness()
        h.engine.startMeditation()
        #expect(h.engine.isActive(.meditation))
        #expect(!h.engine.isActive(.reading))
        #expect(!h.engine.isActive(.water))
        #expect(h.engine.focus == .meditation)
    }

    @Test func readingSessionKeepsReadingActive() {
        let h = harness()
        h.engine.startReading()
        #expect(h.engine.isActive(.reading))
        #expect(!h.engine.isActive(.meditation))
        #expect(h.engine.focus == .reading)
    }

    @Test func pillPerSessionHabit() {
        let h = harness()
        h.engine.startMeditation()
        #expect(h.engine.pill(.meditation) == "Breathing…")
        h.engine.stopSession()
        h.engine.startReading()
        #expect(h.engine.pill(.reading) == "Reading…")
    }

    @Test func statusCallToActionIsBreathe() {
        let h = harness(at: day(2026, 3, 4, 15))
        #expect(h.engine.phase == .bubble(.meditation, .nudge))
        #expect(h.engine.statusText == "Breathe!")
    }

    @Test func moodDuringAMeditationSessionIsReading() {
        let h = harness()
        h.engine.startMeditation()
        #expect(h.engine.mood(.meditation) == .reading)
    }

    @Test func subtitleShowsMinutesOfGoalAndStreak() {
        let h = harness()
        #expect(h.engine.subtitle(.meditation) == "0 of 10 min · 0-day streak")
        h.engine.startMeditation()
        h.advance(minutes: 5)
        #expect(h.engine.subtitle(.meditation) == "5 of 10 min · 0-day streak")
        #expect(h.engine.progress(.meditation) == 0.5)
    }

    @Test func sessionTicksEverySecond() {
        let now = day(2026, 3, 4, 10)
        #expect(TickPlanner.delay(now: now, phase: .session(.meditation), deadlines: [], focusRemaining: nil) == Timing.activeTick)
    }
}
