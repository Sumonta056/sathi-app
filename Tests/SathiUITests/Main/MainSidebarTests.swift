import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Main sidebar")
struct MainSidebarTests {
    private static let pages = ["Today", "Activities", "Reports"]
    private static let subPages = [
        "General",
        "Fota · water",
        "Boi · reading",
        "Shanti · calm",
        "Shokti · gym",
        "Quick reminders",
        "Activity tracker",
        "Time blocks",
        "Sound"
    ]

    private final class Box {
        var open: Bool
        init(_ open: Bool) { self.open = open }
        var binding: Binding<Bool> { Binding(get: { self.open }, set: { self.open = $0 }) }
    }

    private func sidebar(_ h: EngineHarness, _ route: MainRoute, open: Bool = true) -> some View {
        MainSidebar(route: route, isOpen: .constant(open)).environmentObject(h.engine)
    }

    private func texts(_ h: EngineHarness, _ route: MainRoute, open: Bool = true) throws -> [String] {
        try sidebar(h, route, open: open).inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    @Test func listsThePagesInOrder() throws {
        let shown = try texts(EngineHarness(), MainRoute(.today))
        #expect(shown.filter(Self.pages.contains) == Self.pages)
    }

    @Test func settingsListIsAlwaysOpenWithNineItemsInOrder() throws {
        for page in [MainPage.today, .reports, .settings(.tracker)] {
            let shown = try texts(EngineHarness(), MainRoute(page))
            #expect(shown.filter(Self.subPages.contains) == Self.subPages)
            #expect(shown.contains("SETTINGS"))
        }
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

    @Test func tapOnASettingsItemShowsThatSettingsPage() throws {
        let route = MainRoute(.today)
        try Find.button(sidebar(EngineHarness(), route).inspect(), holding: "Shanti · calm").tap()
        #expect(route.page == .settings(.habit(.meditation)))
        try Find.button(sidebar(EngineHarness(), route).inspect(), holding: "Sound").tap()
        #expect(route.page == .settings(.sound))
    }

    @Test func selectedItemsHaveTheSelectedTrait() throws {
        let sut = try sidebar(EngineHarness(), MainRoute(.settings(.tracker))).inspect()
        #expect(try A11y.isSelected(Find.button(sut, holding: "Activity tracker")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "Today")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "General")))
    }

    @Test func openSidebarHasACloseButtonThatCloses() throws {
        let box = Box(true)
        let sut = try MainSidebar(route: MainRoute(.today), isOpen: box.binding).environmentObject(EngineHarness().engine).inspect()
        try Find.button(sut, label: "Close sidebar").tap()
        #expect(!box.open)
    }

    @Test func openSidebarShowsTheFooterWithTwoLinks() throws {
        let sut = try sidebar(EngineHarness(), MainRoute(.today)).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.sidebarFooter(version: AboutFooter.version)) }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "GitHub") }
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "Portfolio") }
    }

    @Test func closedSidebarHasAnOpenButtonThatOpens() throws {
        let box = Box(false)
        let sut = try MainSidebar(route: MainRoute(.today), isOpen: box.binding).environmentObject(EngineHarness().engine).inspect()
        try Find.button(sut, label: "Open sidebar").tap()
        #expect(box.open)
    }

    @Test func closedRailHidesTheHeadingTrackerBlockAndFooter() throws {
        let sut = try sidebar(EngineHarness(), MainRoute(.today), open: false).inspect()
        let shown = try texts(EngineHarness(), MainRoute(.today), open: false)
        #expect(!shown.contains("SETTINGS"))
        #expect(!shown.contains("TRACKER OFF"))
        #expect(throws: (any Error).self) { try sut.find(TrackerStatusBlock.self) }
        #expect(throws: (any Error).self) { try sut.find(SidebarFooter.self) }
    }

    @Test func closedRailShowsTheVersion() throws {
        let shown = try texts(EngineHarness(), MainRoute(.today), open: false)
        #expect(shown.contains(Copywriter.sidebarVersion(AboutFooter.version)))
    }

    @Test func closedRailLabelsEveryIcon() throws {
        let sut = try sidebar(EngineHarness(), MainRoute(.today), open: false).inspect()
        for label in Self.pages + Self.subPages + ["GitHub", Copywriter.sidebarTrackerOffHint] {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: label) }
        }
    }

    @Test func closedRailTapsNavigate() throws {
        let route = MainRoute(.today)
        let sut = try sidebar(EngineHarness(), route, open: false).inspect()
        try Find.button(sut, label: "Reports").tap()
        #expect(route.page == .reports)
        try Find.button(sut, label: "Sound").tap()
        #expect(route.page == .settings(.sound))
    }

    @Test func closedRailMarksTheSelectedTile() throws {
        let sut = try sidebar(EngineHarness(), MainRoute(.settings(.tracker)), open: false).inspect()
        #expect(try A11y.isSelected(Find.button(sut, label: "Activity tracker")))
        #expect(try !A11y.isSelected(Find.button(sut, label: "Sound")))
    }

    @Test func closedRailShowsTrackerOnHintWhenOn() throws {
        let sut = try sidebar(EngineHarness.tracker { _ in }, MainRoute(.today), open: false).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: Copywriter.sidebarTrackerOnHint) }
    }

    @Test func everySettingsPageHasAnIcon() {
        let icons = SettingsPage.all.map(SidebarSettingsStyle.icon)
        #expect(Set(icons).count == SettingsPage.all.count)
    }
}
