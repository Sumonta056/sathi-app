import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar page switch")
struct CalendarSwitchTests {
    private func tab(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(GeneralTab(), h).inspect()
    }

    @Test func generalTabHasTheExperimentalSwitchOffByDefault() throws {
        let h = EngineHarness()
        let sut = try tab(h)
        #expect(throws: Never.self) { try sut.find(text: "EXPERIMENTAL") }
        #expect(throws: Never.self) { try sut.find(text: "Calendar page (experimental)") }
        #expect(!h.engine.data.prefs.calendarPage.isOn)
    }

    @Test func theSwitchTurnsThePageOn() throws {
        let h = EngineHarness()
        try Find.button(tab(h), label: "Calendar page").tap()
        #expect(h.engine.data.prefs.calendarPage.isOn)
    }
}
