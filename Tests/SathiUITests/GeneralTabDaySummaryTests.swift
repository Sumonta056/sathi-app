import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("General tab day summary")
struct GeneralTabDaySummaryTests {
    private func tab(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(GeneralTab(), h).inspect()
    }

    @Test func showsTheSwitchAndTheTimeMenuWhenOn() throws {
        let sut = try tab(EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: "Show my day summary") }
        #expect(throws: Never.self) { try sut.find(text: "Show it at") }
    }

    @Test func hidesTheTimeMenuWhenOff() throws {
        let sut = try tab(EngineHarness { $0.prefs.general.daySummaryOn = false })
        #expect(throws: Never.self) { try sut.find(text: "Show my day summary") }
        #expect((try? sut.find(text: "Show it at")) == nil)
    }

    @Test func theSwitchTurnsTheSummaryOff() throws {
        let h = EngineHarness()
        try Find.button(tab(h), label: "Day summary").tap()
        #expect(!h.engine.data.prefs.general.daySummaryOn)
    }
}
