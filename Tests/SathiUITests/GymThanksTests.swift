import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Gym thanks")
struct GymThanksTests {
    private func finished() -> EngineHarness {
        let h = gymReminder()
        h.engine.startSession(.gym)
        h.engine.finishSession(.gym)
        return h
    }

    @Test func thanksNamesShokti() throws {
        let h = finished()
        #expect(h.engine.isCelebrating)
        let sut = try CelebrateView().environmentObject(h.engine).inspect()
        #expect(try sut.find(GymThanks.self) != nil)
        #expect((try? sut.find(LegacyCelebrate.self)) == nil)
        #expect(try sut.find(text: h.engine.celebration.title) != nil)
        #expect(try sut.find(text: "Shokti counted this move.") != nil)
    }

    @Test func closeEndsTheCelebration() throws {
        let h = finished()
        let sut = try GymThanks().environmentObject(h.engine).inspect()
        try Find.button(sut, label: "Close").tap()
        #expect(!h.engine.isCelebrating)
    }
}
