import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Settings sidebar")
struct SettingsSidebarTests {
    private func sidebar(_ h: EngineHarness, _ tab: Box<SettingsTab> = Box(.general)) -> some View {
        SettingsSidebar(tab: tab.binding).environmentObject(h.engine)
    }

    @Test func showsEveryNavEntry() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        for text in ["Sathi", "General", "Water", "Reading", "Meditation", "Add a buddy", "Open reports"] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
    }

    @Test func meditationRowShowsNewBadge() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "NEW") }
    }

    @Test func readingSwitchTurnsReadingOff() throws {
        let h = EngineHarness()
        try Find.button(sidebar(h).inspect(), label: "Reading reminders").tap()
        #expect(!h.engine.data.prefs.reading.enabled)
        #expect(h.store.prefs.reading.enabled == false)
    }

    @Test func meditationSwitchTurnsMeditationOn() throws {
        let h = EngineHarness()
        try Find.button(sidebar(h).inspect(), label: "Meditation reminders").tap()
        #expect(h.engine.data.prefs.meditation.enabled)
    }

    @Test func waterNavSelectsTheWaterTab() throws {
        let tab = Box<SettingsTab>(.general)
        try Find.button(sidebar(EngineHarness(), tab).inspect(), holding: "Water").tap()
        #expect(tab.value == .habit(.water))
    }

    @Test func addBuddyNavSelectsTheAddBuddyTab() throws {
        let tab = Box<SettingsTab>(.general)
        try Find.button(sidebar(EngineHarness(), tab).inspect(), holding: "Add a buddy").tap()
        #expect(tab.value == .addBuddy)
    }

    @Test func generalNavSelectsTheGeneralTab() throws {
        let tab = Box<SettingsTab>(.habit(.reading))
        try Find.button(sidebar(EngineHarness(), tab).inspect(), holding: "General").tap()
        #expect(tab.value == .general)
    }

    @Test func selectedNavButtonHasTheSelectedTrait() throws {
        let sut = try sidebar(EngineHarness(), Box(.habit(.water))).inspect()
        #expect(try A11y.isSelected(Find.button(sut, holding: "Water")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "General")))
    }

    @Test func openReportsIsEnabledWithoutSoon() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        #expect(Find.lacks(sut, text: "Soon"))
        #expect(try !Find.button(sut, holding: "Open reports").isDisabled())
    }

    @Test func openReportsOpensTheReportsWindow() throws {
        let h = EngineHarness()
        try Find.button(sidebar(h).inspect(), holding: "Open reports").tap()
        #expect(h.presenter.calls.last == .showReports)
    }

    @Test func openReportsSitsRightAfterGeneral() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        let order = sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
        let general = try #require(order.firstIndex(of: "General"))
        #expect(order[general + 1] == "Open reports")
    }

    @Test func footerShowsMadeByWithLinks() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Made by Sumonta") }
        let links = sut.findAll(ViewType.Link.self)
        let urls = try links.map { try $0.url() }
        #expect(urls.contains(Links.github))
        #expect(urls.contains(Links.portfolio))
        #expect(Links.github.absoluteString == "https://github.com/Sumonta056")
        #expect(Links.portfolio.absoluteString == "https://sumonta056.vercel.app/")
    }

    @Test func footerLinksAreIconsWithNames() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        let links = sut.findAll(ViewType.Link.self)
        let labels = links.compactMap { try? $0.accessibilityLabel().string() }
        #expect(labels.contains("GitHub"))
        #expect(labels.contains("Portfolio"))
        for link in links {
            #expect(try link.labelView().findAll(ViewType.Text.self).isEmpty)
        }
    }

    @Test func waterTabShowsItsHero() throws {
        let sut = try hosted(WaterSettingsTab(), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Small sips, all day long") }
        #expect(throws: Never.self) { try sut.find(text: "FOTA · WATER") }
    }

    @Test func addBuddyTabShowsTwoComingSoonBuddies() throws {
        let sut = try AddBuddyTab().inspect()
        for text in ["Add a buddy", "Eye break", "Posture"] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
        #expect(Find.lacks(sut, text: "Stretch"))
        #expect(Find.lacks(sut, text: "Walk"))
        let soon = sut.findAll(ViewType.Button.self).filter { (try? $0.labelView().find(text: "Soon")) != nil }
        #expect(soon.count == 2)
        #expect(soon.allSatisfy { $0.isDisabled() })
    }

    @Test func sidebarShowsGymWithNewLabel() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        let gym = try Find.button(sut, holding: "Gym")
        #expect(throws: Never.self) { try gym.find(text: "NEW") }
        #expect(throws: Never.self) { try Find.button(sut, label: "Gym reminders") }
    }

    @Test func rootShowsSidebarAndGeneralTabFirst() throws {
        let sut = try hosted(SettingsView(), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(SettingsSidebar.self) }
        #expect(throws: Never.self) { try sut.find(text: "Hi there") }
        #expect(Find.lacks(sut, text: "Small sips, all day long"))
    }

    @Test func everyRowFitsTheSidebarOnOneLine() {
        let host = NSHostingView(rootView: sidebar(EngineHarness { $0.prefs.meditation.enabled = true }))
        #expect(host.fittingSize.width <= UIMetrics.sidebarWidth)
    }
}
