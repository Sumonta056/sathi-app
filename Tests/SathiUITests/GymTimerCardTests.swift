import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Gym timer card")
struct GymTimerCardTests {
    private func started() -> EngineHarness {
        let h = gymReminder()
        h.engine.startSession(.gym)
        return h
    }

    private func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try GymTimerCard().environmentObject(h.engine).inspect()
    }

    @Test func timerShowsWorkoutNameAndDoneCounts() throws {
        let h = started()
        let sut = try card(h)
        #expect(try sut.find(text: "SHOKTI · Neck and shoulder stretch") != nil)
        #expect(try sut.find(text: Copywriter.gymTimerLine()) != nil)
        try Find.button(sut, holding: "Done").tap()
        #expect(h.history.appended.last == .done(.gym, 1, at: h.engine.now))
        #expect(h.engine.session(.gym) == nil)
    }

    @Test func timerStopDoesNotCount() throws {
        let h = started()
        try Find.button(card(h), holding: "Stop").tap()
        #expect(h.engine.session(.gym) == nil)
        #expect(!h.history.appended.contains { $0.kind == .done })
    }

    @Test func progressIsTheShareOfTimeGone() {
        let start = day(2026, 3, 4, 10)
        let end = start.addingTimeInterval(4 * Timing.minute)
        #expect(GymTimerCard.progress(start: start, end: end, now: start) == 0)
        #expect(GymTimerCard.progress(start: start, end: end, now: start.addingTimeInterval(Timing.minute)) == 0.25)
        #expect(GymTimerCard.progress(start: start, end: end, now: end.addingTimeInterval(Timing.minute)) == 1)
        #expect(GymTimerCard.progress(start: start, end: start, now: start) == 0)
    }
}
