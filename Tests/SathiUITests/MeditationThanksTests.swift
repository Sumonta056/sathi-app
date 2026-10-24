import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Meditation thanks")
struct MeditationThanksTests {
    private func finished(events: [HistoryEvent] = []) -> EngineHarness {
        let start = day(2026, 3, 4, 15)
        let h = EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.sessionMinutes = 5
            $0.prefs.meditation.slots = [.afternoon]
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
            $0.events = events
        }
        h.engine.startMeditation()
        h.advance(minutes: 5)
        return h
    }

    private func celebrate(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try CelebrateView().environmentObject(h.engine).inspect()
    }

    @Test func fullSessionShowsTheThanksCard() throws {
        let h = finished()
        #expect(h.engine.phase == .celebrate)
        let sut = try celebrate(h)
        #expect(try sut.find(MeditationThanks.self) != nil)
        #expect((try? sut.find(LegacyCelebrate.self)) == nil)
        #expect(try sut.find(text: h.engine.celebration.title) != nil)
        #expect(try sut.find(text: "A calm start.") != nil)
        #expect(try sut.find(text: "Back to work") != nil)
    }

    @Test func backToWorkEndsTheCelebration() throws {
        let h = finished()
        let card = try celebrate(h).find(MeditationThanks.self)
        try Find.button(card, holding: "Back to work").tap()
        #expect(h.engine.phase == .idle)
    }

    @Test func hintCountsTheStreak() throws {
        let h = finished(events: [.done(.meditation, 5, at: day(2026, 3, 3, 8, 5))])
        #expect(try celebrate(h).find(text: "2 calm days in a row.") != nil)
    }
}
