import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Break menu")
struct BreakMenuTests {
    private let hint = "Quick reminders still show during a break."

    private func menu(_ h: EngineHarness) throws -> InspectableView<ViewType.Menu> {
        try hosted(BreakMenu(), h).inspect().find(ViewType.Menu.self)
    }

    @Test func menuIsLabelledTakeABreak() throws {
        let sut = try menu(Glance.harness())
        #expect(throws: Never.self) { try sut.labelView().find(text: "Take a break") }
    }

    @Test func panelFooterHoldsTheBreakMenu() throws {
        let sut = try Glance.panel(Glance.harness())
        #expect(sut.findAll(BreakMenu.self).count == 1)
        #expect(Find.lacks(sut, text: "Take a break from reminders"))
    }

    @Test func thirtyMinutesPausesForHalfAnHour() throws {
        let h = Glance.harness()
        try menu(h).find(button: "30 min").tap()
        #expect(h.engine.pausedUntil == day(2026, 3, 4, 10, 30))
    }

    @Test func oneHourPausesForAnHour() throws {
        let h = Glance.harness()
        try menu(h).find(button: "1 hour").tap()
        #expect(h.engine.pausedUntil == day(2026, 3, 4, 11))
    }

    @Test func restOfDayPausesUntilMidnight() throws {
        let h = Glance.harness()
        try menu(h).find(button: "Rest of day").tap()
        #expect(h.engine.pausedUntil == day(2026, 3, 5))
    }

    @Test func hintShowsOnlyWithQuickReminders() throws {
        #expect(try !MenuFind.hasText(menu(Glance.harness()), containing: hint))
        #expect(try MenuFind.hasText(menu(Glance.harness(reminders: 1)), containing: hint))
    }
}

@MainActor
@Suite("Version text")
struct VersionTextTests {
    @Test func menuFooterHasNoVersionText() throws {
        let texts = try MenuFind.texts(hosted(MenuFooter(), EngineHarness()).inspect())
        #expect(!texts.contains { $0 == MenuFooter.versionText || $0.hasPrefix("Sathi ") })
    }

    @Test func settingsSidebarShowsTheVersionAtTheBottom() throws {
        let sut = try SettingsSidebar(tab: Box<SettingsTab>(.general).binding).environmentObject(EngineHarness().engine).inspect()
        let texts = MenuFind.texts(sut)
        let addBuddy = try #require(texts.firstIndex(of: "Add a buddy"))
        let version = try #require(texts.lastIndex(of: MenuFooter.versionText))
        #expect(version > addBuddy)
    }
}
