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
    private func harness(
        _ style: BreathingStyle = .calm,
        at start: Date = day(2026, 3, 4, 15),
        lastWater: Date? = nil
    ) -> EngineHarness {
        EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.sessionMinutes = 5
            $0.prefs.meditation.style = style
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

    private func frame(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try breathe(h).find(ViewType.TimelineView.self).contentView(.init(date: h.engine.now))
    }

    private func texts(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    @Test func startShowsEyebrowCountPhaseTimeLeftAndButtons() throws {
        let h = harness()
        h.engine.startMeditation()
        let root = try breathe(h)
        let sut = try frame(h)
        #expect(try root.find(text: "CALM · 4 6") != nil)
        #expect(try sut.find(text: "4 · IN") != nil)
        #expect(try sut.find(text: "Breathe in") != nil)
        #expect(try sut.find(text: "5:00 left") != nil)
        #expect(try root.find(text: "Pause") != nil)
        #expect(try root.find(text: "Stop") != nil)
        #expect(try sut.find(BreathOrb.self) != nil)
    }

    @Test func showsNoRoundCount() throws {
        let h = harness()
        h.engine.startMeditation()
        let all = try texts(breathe(h)) + texts(frame(h))
        #expect(!all.contains { $0.contains("Round") })
    }

    @Test func fiveSecondsInBreathesOut() throws {
        let h = harness()
        h.engine.startMeditation()
        advance(h, seconds: 5)
        let sut = try frame(h)
        #expect(try sut.find(text: "Breathe out") != nil)
        #expect(try sut.find(text: "5 · OUT") != nil)
        #expect(try sut.find(text: "4:55 left") != nil)
        #expect(Find.lacks(sut, text: "Breathe in"))
    }

    @Test func pauseFreezesTheTimeLeftAndShowsResume() throws {
        let h = harness()
        h.engine.startMeditation()
        advance(h, seconds: 5)
        try Find.button(breathe(h), holding: "Pause").tap()
        #expect(h.engine.session(.meditation)?.isPaused == true)
        advance(h, seconds: 60)
        #expect(try frame(h).find(text: "4:55 left") != nil)
        #expect(try frame(h).find(text: "Breathe out") != nil)
        let root = try breathe(h)
        #expect(Find.lacks(root, text: "Pause"))
        try Find.button(root, holding: "Resume").tap()
        #expect(h.engine.session(.meditation)?.isPaused == false)
    }

    @Test func stopEndsWithoutCounting() throws {
        let h = harness()
        h.engine.startMeditation()
        h.advance(minutes: 2)
        try Find.button(breathe(h), holding: "Stop").tap()
        #expect(h.engine.activities.isEmpty)
        #expect(!h.engine.data.events.contains { $0.habit == .meditation && $0.kind == .done })
    }

    @Test func stopWhilePausedEndsWithoutCounting() throws {
        let h = harness()
        h.engine.startMeditation()
        h.engine.pauseSession(.meditation)
        try Find.button(breathe(h), holding: "Stop").tap()
        #expect(h.engine.activities.isEmpty)
        #expect(!h.engine.data.events.contains { $0.habit == .meditation && $0.kind == .done })
    }

    @Test func boxHoldsAfterSixSeconds() throws {
        let h = harness(.box)
        h.engine.startMeditation()
        advance(h, seconds: 6)
        let sut = try frame(h)
        #expect(try breathe(h).find(text: "BOX · 4 4 4 4") != nil)
        #expect(try sut.find(text: "Hold") != nil)
        #expect(try sut.find(text: "2 · HOLD") != nil)
        #expect(try sut.find(text: "4:54 left") != nil)
    }

    @Test func relaxStartsWithWindDown() throws {
        let h = harness(.relax)
        h.engine.startMeditation()
        #expect(try breathe(h).find(text: "WIND DOWN · 4 7 8") != nil)
        #expect(try frame(h).find(text: "4 · IN") != nil)
    }

    @Test func noWaterNoteWhileWaterShows() throws {
        let h = harness(at: day(2026, 3, 4, 11, 58), lastWater: day(2026, 3, 4, 10))
        h.engine.startMeditation()
        h.advance(minutes: 3)
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(h.engine.phase(.meditation) == .session)
        #expect(try Find.lacks(breathe(h), text: "Fota is waiting for you after this"))
    }

    @Test func readingFocusSessionKeepsTheSessionView() throws {
        let h = EngineHarness { $0.prefs.reading.reminderStyle = .focus }
        h.engine.startReading()
        let sut = try SessionView(id: .reading).environmentObject(h.engine).inspect()
        #expect(try sut.find(text: "READING · DO NOT DISTURB") != nil)
        #expect((try? sut.find(BreathOrb.self)) == nil)
    }
}
