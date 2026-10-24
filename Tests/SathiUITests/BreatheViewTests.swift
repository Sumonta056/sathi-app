import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Breathe view")
struct BreatheViewTests {
    private func harness(at start: Date = day(2026, 3, 4, 15), lastWater: Date? = nil) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.sessionMinutes = 5
            $0.prefs.meditation.style = .box
            $0.live.lastWaterDone = lastWater ?? start.addingTimeInterval(-Timing.minute)
        }
    }

    private func advance(_ h: EngineHarness, seconds: TimeInterval) {
        h.clock.advance(minutes: seconds / Timing.minute)
        h.engine.tick()
    }

    private func breathe(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try BreatheView().environmentObject(h.engine).inspect()
    }

    @Test func startShowsHeaderFirstPhaseRoundAndStop() throws {
        let h = harness()
        h.engine.startMeditation()
        let sut = try breathe(h)
        #expect(try sut.find(text: "BOX BREATHING · 4·4·4·4") != nil)
        #expect(try sut.find(text: "Breathe in") != nil)
        #expect(try sut.find(text: "Round 1 of 18") != nil)
        #expect(try sut.find(text: "Stop") != nil)
        #expect(try sut.find(BreathCircle.self) != nil)
    }

    @Test func sixSecondsInHolds() throws {
        let h = harness()
        h.engine.startMeditation()
        advance(h, seconds: 6)
        let sut = try breathe(h)
        #expect(try sut.find(text: "Hold") != nil)
        #expect(Find.lacks(sut, text: "Breathe in"))
        #expect(try sut.find(text: "Round 1 of 18") != nil)
    }

    @Test func eighteenSecondsInStartsRoundTwo() throws {
        let h = harness()
        h.engine.startMeditation()
        advance(h, seconds: 18)
        let sut = try breathe(h)
        #expect(try sut.find(text: "Breathe in") != nil)
        #expect(try sut.find(text: "Round 2 of 18") != nil)
    }

    @Test func stopEndsWithoutCounting() throws {
        let h = harness()
        h.engine.startMeditation()
        h.advance(minutes: 2)
        try Find.button(breathe(h), holding: "Stop").tap()
        #expect(h.engine.phase == .idle)
        #expect(!h.engine.data.events.contains { $0.habit == .meditation && $0.kind == .done })
    }

    @Test func mentionsQueuedWater() throws {
        let h = harness(at: day(2026, 3, 4, 11, 58), lastWater: day(2026, 3, 4, 10))
        h.engine.startMeditation()
        h.advance(minutes: 3)
        #expect(h.engine.queue.contains(.water))
        #expect(try breathe(h).find(text: "Fota is waiting for you after this") != nil)
    }

    @Test func noWaterNoteWithoutAQueue() throws {
        let h = harness()
        h.engine.startMeditation()
        let sut = try breathe(h)
        #expect(try sut.find(text: "BOX BREATHING · 4·4·4·4") != nil)
        #expect(Find.lacks(sut, text: "Fota is waiting for you after this"))
    }

    @Test(arguments: [(BreathPhase.inhale, 1.0), (.hold, 1.0), (.exhale, 0.62), (.rest, 0.62)])
    func circleScale(_ phase: BreathPhase, _ expected: Double) {
        #expect(Double(BreathCircle.scale(for: phase)) == expected)
        #expect(Double(UIMetrics.breathScaleBig) == 1)
        #expect(Double(UIMetrics.breathScaleSmall) == 0.62)
    }

    @Test func readingFocusSessionKeepsTheSessionView() throws {
        let h = EngineHarness { $0.prefs.reading.reminderStyle = .focus }
        h.engine.startReading()
        let sut = try SessionView().environmentObject(h.engine).inspect()
        #expect(try sut.find(text: "READING · DO NOT DISTURB") != nil)
        #expect((try? sut.find(BreathCircle.self)) == nil)
    }

    private func styled(_ style: BreathingStyle) -> EngineHarness {
        let start = day(2026, 3, 4, 15)
        return EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.sessionMinutes = 5
            $0.prefs.meditation.style = style
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
        }
    }

    @Test func relaxStartsWithWindDownAndFifteenRounds() throws {
        let h = styled(.relax)
        h.engine.startMeditation()
        let sut = try breathe(h)
        #expect(try sut.find(text: "WIND DOWN · 4·7·8") != nil)
        #expect(try sut.find(text: "Breathe in") != nil)
        #expect(try sut.find(text: "Round 1 of 15") != nil)
    }

    @Test func evenBreathesOutAfterSixSeconds() throws {
        let h = styled(.even)
        h.engine.startMeditation()
        advance(h, seconds: 6)
        let sut = try breathe(h)
        #expect(try sut.find(text: "Breathe out") != nil)
        #expect(try sut.find(text: "Round 1 of 30") != nil)
    }
}
