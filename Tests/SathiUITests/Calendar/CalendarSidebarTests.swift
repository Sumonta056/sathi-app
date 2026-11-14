import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar sidebar item")
struct CalendarSidebarTests {
    private func sidebar(_ h: EngineHarness, _ route: MainRoute, open: Bool = true) -> some View {
        MainSidebar(route: route, isOpen: .constant(open)).environmentObject(h.engine)
    }

    private func texts(_ h: EngineHarness, _ route: MainRoute) throws -> [String] {
        try sidebar(h, route).inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    private func calendarOn() -> EngineHarness {
        EngineHarness { $0.prefs.calendarPage.isOn = true }
    }

    @Test func calendarOffHasNoCalendarItem() throws {
        let shown = try texts(EngineHarness(), MainRoute(.today))
        #expect(!shown.contains("Calendar"))
        #expect(!shown.contains("Experimental"))
    }

    @Test func calendarOnShowsAfterActivitiesWithTheTag() throws {
        let shown = try texts(calendarOn(), MainRoute(.today))
        #expect(shown.filter(["Today", "Activities", "Calendar", "Reports"].contains) == ["Today", "Activities", "Calendar", "Reports"])
        #expect(shown.contains("Experimental"))
    }

    @Test func calendarTapShowsTheCalendarPage() throws {
        let route = MainRoute(.today)
        try Find.button(sidebar(calendarOn(), route).inspect(), holding: "Calendar").tap()
        #expect(route.page == .calendar(nil))
    }

    @Test func calendarRailIconIsLabeledAndTaps() throws {
        let route = MainRoute(.today)
        let sut = try sidebar(calendarOn(), route, open: false).inspect()
        try Find.button(sut, label: "Calendar").tap()
        #expect(route.page == .calendar(nil))
        let off = try sidebar(EngineHarness(), MainRoute(.today), open: false).inspect()
        #expect((try? off.find(viewWithAccessibilityLabel: "Calendar")) == nil)
    }
}
