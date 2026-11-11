import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Main sidebar")
struct MainSidebarTests {
    private static let pages = ["Today", "Activities", "Reports", "Settings"]
    private static let subPages = ["General", "Fota", "Boi", "Shanti", "Shokti", "Quick reminders", "Activity tracker", "Time blocks", "Sound"]

    private func sidebar(_ h: EngineHarness, _ route: MainRoute) -> some View {
        MainSidebar(route: route).environmentObject(h.engine)
    }

    private func texts(_ h: EngineHarness, _ route: MainRoute) throws -> [String] {
        try sidebar(h, route).inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    @Test func listsTheFourPagesInOrder() throws {
        let shown = try texts(EngineHarness(), MainRoute(.today))
        #expect(shown.filter(Self.pages.contains) == Self.pages)
    }

    @Test func settingsSubPagesHideWhenSettingsIsNotSelected() throws {
        let shown = try texts(EngineHarness(), MainRoute(.reports))
        #expect(shown.filter(Self.subPages.contains).isEmpty)
    }

    @Test func settingsNestsItsNineSubPagesInOrder() throws {
        let shown = try texts(EngineHarness(), MainRoute(.settings(.tracker)))
        #expect(shown.filter(Self.subPages.contains) == Self.subPages)
        let settings = try #require(shown.firstIndex(of: "Settings"))
        #expect(shown[settings + 1] == "General")
    }

    @Test func trackerOffShowsTrackerOff() throws {
        let shown = try texts(EngineHarness(), MainRoute(.today))
        #expect(shown.contains("TRACKER OFF"))
        #expect(!shown.contains("TRACKER ON"))
    }

    @Test func trackerOnShowsItsHoursAndAskInterval() throws {
        let h = EngineHarness.tracker {
            $0.prefs.tracker.startMinutes = 9 * 60
            $0.prefs.tracker.endMinutes = 18 * 60
            $0.prefs.tracker.askEveryMinutes = 30
        }
        let shown = try texts(h, MainRoute(.today))
        let span = Copywriter.trackerSpan(day(2026, 3, 4, 9), day(2026, 3, 4, 18), calendar: .current)
        #expect(shown.contains("TRACKER ON"))
        #expect(shown.contains(span + " · asks every 30 min"))
        #expect(!shown.contains("TRACKER OFF"))
    }

    @Test func tapOnAPageShowsThatPage() throws {
        let route = MainRoute(.today)
        try Find.button(sidebar(EngineHarness(), route).inspect(), holding: "Reports").tap()
        #expect(route.page == .reports)
        try Find.button(sidebar(EngineHarness(), route).inspect(), holding: "Activities").tap()
        #expect(route.page == .activities(nil))
    }

    @Test func firstTapOnSettingsOpensGeneral() throws {
        let route = MainRoute(.today)
        try Find.button(sidebar(EngineHarness(), route).inspect(), holding: "Settings").tap()
        #expect(route.page == .settings(.general))
    }

    @Test func tapOnASubPageShowsThatSettingsPage() throws {
        let route = MainRoute(.settings(.general))
        try Find.button(sidebar(EngineHarness(), route).inspect(), holding: "Shanti").tap()
        #expect(route.page == .settings(.habit(.meditation)))
        try Find.button(sidebar(EngineHarness(), route).inspect(), holding: "Sound").tap()
        #expect(route.page == .settings(.sound))
    }

    @Test func selectedItemsHaveTheSelectedTrait() throws {
        let sut = try sidebar(EngineHarness(), MainRoute(.settings(.tracker))).inspect()
        #expect(try A11y.isSelected(Find.button(sut, holding: "Settings")))
        #expect(try A11y.isSelected(Find.button(sut, holding: "Activity tracker")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "Today")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "General")))
    }
}
